#include <cassert>
#include <iostream>
#include <unistd.h>
#include <stdio.h>
#include <sys/time.h>
#include <gpg-error.h>

#include "bsv_scemi.h"
#include "SceMiHeaders.h"
#define GCRYPT_NO_DEPRECATED
#include <gcrypt.h>

#include "ResetXactor.h"

//#define DEBUG




// RSA raw data packet to send to FPGA
typedef struct {
  unsigned char mod[256];
  unsigned char priv_exp[256];
  unsigned char pub_exp[256];
  unsigned char ciphertext[256];
  size_t mod_len;
  size_t priv_len;
  size_t pub_len;
  size_t cipher_len;
} rsa_packet;

void timer_start(struct timeval *start) {
	gettimeofday(start, NULL);
}

void timer_poll(char *format, struct timeval *start) {
	struct timeval now, diff;
	gettimeofday(&now, NULL);
	timersub(&now, start, &diff);
	printf(format, diff.tv_sec, diff.tv_usec);
}

gcry_sexp_t sexp_new(const char *str) {
	gcry_error_t error;

	gcry_sexp_t sexp;
	size_t len = strlen(str);
	if ((error = gcry_sexp_new(&sexp, str, len, 1))) {
		printf("Error in sexp_new(%s): %s\nSource: %s\n", str, gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	return sexp;
}

void printBits(size_t const size, void const * const ptr)
{
    unsigned char *b = (unsigned char*) ptr;
    unsigned char byte;
    int i, j;

    for (i=size-1;i>=0;i--)
    {
        for (j=7;j>=0;j--)
        {
            byte = b[i] & (1<<j);
            byte >>= j;
            printf("%u", byte);
        }
    }
    puts("");
}

char* sexp_string(gcry_sexp_t sexp) {
	size_t buf_len = gcry_sexp_sprint(sexp, GCRYSEXP_FMT_ADVANCED, NULL, 0);
	char *buffer = (char*)gcry_malloc(buf_len);
	if (buffer == NULL) {
		printf("gcry_malloc(%ld) returned NULL in sexp_string()!\n", buf_len);
		exit(1);
	}
	if (0 == gcry_sexp_sprint(sexp, GCRYSEXP_FMT_ADVANCED, buffer, buf_len)) {
		printf("gcry_sexp_sprint() lies!\n");
		exit(1);
	}
	return buffer;

	// This should be freed with gcry_free(buffer);
}

void crypto_init(){
	// Version check makes sure that important subsystems are initalized
	if (!gcry_check_version(GCRYPT_VERSION)) {
		printf("libgcrypt version mismatch\n");
		exit(2);
	}

	// Disable secure memory (it's just more hassle I don't think we really need)
	gcry_control(GCRYCTL_DISABLE_SECMEM, 0);

	// Tell Libgcrypt that initialization has completed.
	gcry_control(GCRYCTL_INITIALIZATION_FINISHED, 0);
}

void generate_key(rsa_packet * packet, char **public_key, char **private_key) {
	gcry_error_t error;
	int i;
	// Generate a reduced strength (to save time) RSA key, 1024 bits long
//	gcry_sexp_t params = sexp_new( "(genkey (rsa (transient-key) (nbits 3:512)))" );
	gcry_sexp_t params = sexp_new( "(genkey (rsa (transient-key) (nbits 4:1024)))" );
	gcry_sexp_t r_key;
	if ((error = gcry_pk_genkey(&r_key, params))) {
		printf("Error in gcry_pk_genkey(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	// Parse the S expression strings
	gcry_sexp_t public_sexp  = gcry_sexp_nth(r_key, 1);
	gcry_sexp_t private_sexp = gcry_sexp_nth(r_key, 2);
	gcry_sexp_t mod_sexp = gcry_sexp_cdr(gcry_sexp_find_token(private_sexp, "n", 1));
	gcry_sexp_t priv_exp_sexp = gcry_sexp_cdr(gcry_sexp_find_token(private_sexp, "d", 1));
	gcry_sexp_t pub_exp_sexp = gcry_sexp_cdr(gcry_sexp_find_token(public_sexp, "e", 1));

	
	// Extract the raw data in MPI format
	gcry_mpi_t mod_mpi, pubexp_mpi, privexp_mpi;
  mod_mpi = gcry_sexp_nth_mpi(mod_sexp, 0, GCRYMPI_FMT_USG); 
  privexp_mpi = gcry_sexp_nth_mpi(priv_exp_sexp, 0, GCRYMPI_FMT_USG);   
  pubexp_mpi = gcry_sexp_nth_mpi(pub_exp_sexp, 0, GCRYMPI_FMT_USG); 

  //gcry_mpi_aprint(GCRYMPI_FMT_HEX, public_key,  NULL, mod_mpi);
  // Now pack it into unsigned char
	gcry_mpi_print(GCRYMPI_FMT_USG, packet->mod, 256, &packet->mod_len, mod_mpi);
	gcry_mpi_print(GCRYMPI_FMT_USG, packet->priv_exp, 256, &packet->priv_len, privexp_mpi);
	gcry_mpi_print(GCRYMPI_FMT_USG, packet->pub_exp, 256, &packet->pub_len, pubexp_mpi);  
  
 // printf ("fmt: %i: %.*s\n", (int)len, (int) len, );

	*public_key = sexp_string(public_sexp);
	*private_key = sexp_string(private_sexp);
}

char* encrypt(rsa_packet * packet, char *public_key, char *plaintext){
	gcry_error_t error;

	gcry_mpi_t r_mpi;
	if ((error = gcry_mpi_scan(&r_mpi, GCRYMPI_FMT_HEX, plaintext, 0, NULL))) {
		printf("Error in gcry_mpi_scan() in encrypt(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	gcry_sexp_t data;
	size_t erroff;
	if ((error = gcry_sexp_build(&data, &erroff, "(data (flags raw) (value %m))", r_mpi))) {
		printf("Error in gcry_sexp_build() in encrypt() at %ld: %s\nSource: %s\n", erroff, gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	gcry_sexp_t public_sexp = sexp_new(public_key);
	gcry_sexp_t r_ciph;
	struct timeval timer;
	timer_start(&timer);
	if ((error = gcry_pk_encrypt(&r_ciph, data, public_sexp))) {
		printf("Error in gcry_pk_encrypt(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}
	timer_poll("\nSoftware encrypt: %d.%06d    seconds\n", &timer);
	
	gcry_sexp_t cipher_sexp = gcry_sexp_cdr(gcry_sexp_find_token(r_ciph, "a", 1));
	gcry_mpi_t cipher_mpi = gcry_sexp_nth_mpi(cipher_sexp, 0, GCRYMPI_FMT_USG);
	gcry_mpi_print(GCRYMPI_FMT_USG, packet->ciphertext, 256, &packet->cipher_len, cipher_mpi);  
	
	return sexp_string(r_ciph);
}

char* decrypt(char *private_key, char *ciphertext){
	gcry_error_t error;
	gcry_sexp_t data = sexp_new(ciphertext);

	gcry_sexp_t private_sexp = sexp_new(private_key);
	gcry_sexp_t r_plain;
	struct timeval timer;
	timer_start(&timer);
	if ((error = gcry_pk_decrypt(&r_plain, data, private_sexp))) {
		printf("Error in gcry_pk_decrypt(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}
	timer_poll("\nSoftware decrypt: %d.%06d    seconds\n", &timer);

	gcry_mpi_t r_mpi = gcry_sexp_nth_mpi(r_plain, 0, GCRYMPI_FMT_USG);

	unsigned char *plaintext;
	size_t plaintext_size;
	if ((error = gcry_mpi_aprint(GCRYMPI_FMT_HEX, &plaintext, &plaintext_size, r_mpi))) {
		printf("Error in gcry_mpi_aprint(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	// Return type hack
	return (char *) plaintext;
}

char* sign(char *private_key, char *document){
	gcry_error_t error;

	gcry_mpi_t r_mpi;
	if ((error = gcry_mpi_scan(&r_mpi, GCRYMPI_FMT_HEX, document, 0, NULL))) {
		printf("Error in gcry_mpi_scan() in encrypt(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	gcry_sexp_t data;
	size_t erroff;
	if ((error = gcry_sexp_build(&data, &erroff, "(data (flags raw) (value %m))", r_mpi))) {
		printf("Error in gcry_sexp_build() in sign() at %ld: %s\nSource: %s\n", erroff, gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	gcry_sexp_t private_sexp = sexp_new(private_key);
	gcry_sexp_t r_sig;
	struct timeval timer;
	timer_start(&timer);
	if ((error = gcry_pk_sign(&r_sig, data, private_sexp))) {
		printf("Error in gcry_pk_sign(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}
	timer_poll("libgcrypt    Sign:    %d.%06d    seconds\n", &timer);

	return sexp_string(r_sig);
}

short verify(char *public_key, char *document, char *signature){
	gcry_error_t error;

	gcry_mpi_t r_mpi;
	if ((error = gcry_mpi_scan(&r_mpi, GCRYMPI_FMT_HEX, document, 0, NULL))) {
		printf("Error in gcry_mpi_scan() in encrypt(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	gcry_sexp_t data;
	size_t erroff;
	if ((error = gcry_sexp_build(&data, &erroff, "(data (flags raw) (value %m))", r_mpi))) {
		printf("Error in gcry_sexp_build() in sign() at %ld: %s\nSource: %s\n", erroff, gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	gcry_sexp_t sig = sexp_new(signature);

	gcry_sexp_t public_sexp = sexp_new(public_key);
	short good_sig = 1;
	struct timeval timer;
	timer_start(&timer);
	if ((error = gcry_pk_verify(sig, data, public_sexp))) {
		if (gcry_err_code(error) != GPG_ERR_BAD_SIGNATURE) {
			printf("Error in gcry_pk_verify(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
			exit(1);
		}
		good_sig = 0;
	}
	timer_poll("libgcrypt    Verify:  %d.%06d    seconds\n", &timer);
	return good_sig;
}


int main(int argc, char* argv[])
{
		rsa_packet packet;
		int i;
		bool cipher_done = 0;
		Command cmd;
		timeval hard_time;
	
    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");
    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);
    	
    // Initialize the crypto library
    crypto_init();

    // Initialize the SceMi inport
    InportProxyT<Command> inport ("", "scemi_rsaxactor_req_inport", sceMi);

    // Initialize the SceMi outport
    OutportQueueT<BIG_INT> outport ("", "scemi_rsaxactor_resp_outport", sceMi);

    ResetXactor reset("", "scemi", sceMi);
    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);

    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread (sceMi);

    reset.reset();
	
    char *test_texts[] = { "deadbeef"
                         , "badf00d"
                         , "0ff1ce"
                         , "cafe"
                         , "defaced"
                         , "aeb45a0ee831ad6e538f9c59300290db92696abbaa06a0b1df6ca317239292160d81f220c99bd788cce66cc41033e2c3eddb"
                         , "46f4ef8bf4cf769bc5ab709267981dbb44801f9c419e99a2fc7639baaf6de6741cee37af64d5d50c87402713505cb51a88fb"
                         , "4d889e31f9a92bd62df29e16047beb747fc92e3eceebab44d399b386825d1f55294f6d854e56d0f9a7b610c67b2ae7b5e5bd36"
                         , "8ecbff22d54c29902bda135826fd302787742d4ce7a064f73c4ecca822235035fbdf1350bb7d9abcb4f54eb3257f2c96798d2e"
                         , "853493ee4fd1fe0cde743cba9b180bff20bd457c152e258b9e3b478bd25fa60a6766b8d36a95885c2c47aaa63f22ff93ebea08"
                         , "050e383b35f7688879a54ef463961533f040f943467b6a5617fdf88000c91c662d0688ddd5144f12c49106d8d81a5e04ff5ca2"
                         , "f355db88fb426ebea4a551ad129d4fcb243b903411e638a08a81e22bfe250937f1194caea4d1f312f06ecfa906d79e8c948a0d"
                         , "11d1e35094599325a2122f2f919a64e4d4ace48812f192ea7c11410c539707149c5d335f921f132d11795bcc1ebbf4a20b65e9"
                         , "7b101a938d50b8dc88780235f226bc1c6650df830c3290565e12d6b9c347c06b1fb0b6fb2e648019c8526e2d4adc4dc766dba5"
                         , "7305d1b0e93f54de5fa19eb1089fa6fbc566f8479cd381ca5894492c3078d23ef3d7a1923b9a96ffb7bf2b727fc28c6d522e54"
                         , "4228043134c88aed152a8cd0d9aef45f742e6d12511d0ecbfbf34ea593998c499f19c6315e8779184ab58dd8e731a25d410d61"
                         , "c04bb261996776e003d70116c3d7d56c6e2375f349983d478416f6600edeec1dbc286d4a57445be4ded180dcb7e157b35a8a4f"
                         , "eac2be8a8e3ef31a292c4faafa9c8a63acf1e4046672c5379215f6f145ce2062ace5587f3ea226f628178426062dd9ff81186c"
                         , "c3387e260634be9995b52c1f7114cf23d01cce8ef598cc8e5364db272aee60d06e626a2a67964d7391d5ed5c7193ab36eba81e"
                         , "ac84645df2aaca9dee4d03e8b900007905f9bfe93bbef391ea7b57513948ec88b252add18db987b0ff886e1c7d25152f7dc1af"
                         , "7176de621be4b8d4f5060b6ae0ab188d2c33f3aeddaddbe639cd89a8ca5784a8cdb0135108eb7f35020556795764c71536b49e"
                         , "1a3f9f30e4c3d5d244c1d9e6cfb8f4dd47f686efb74e99de63358750e6f0622b24afc212a472bf9a93b0d39e79ff4a71ee57c6"
                         , "68a9101d17cadfa1d89353a1d12d878dede2630904fbd8bf08ee36ccaa3c2b1759415ec3fe54bfa9f1034c5a20d01673fa06f6"
                         , "31206814135169d02ec6893064bcaab54d9a2cc44fedc5e16dba2d97adca09fd6838af21e06def28a3815dccae369ce1e2f4af"
                         , "f536b2e57395c6421008095dc6832282d8083ac466debc88f5979e8ada0e0b4820754f0325de29d77c46eada3683bb5be3fd10"
                         };
    for (int tests = 0; tests < 20; tests++) {
      char *public_key, *private_key;
      printf("Generating keypair in software...");
      generate_key(&packet, &public_key, &private_key);
      
      #ifdef DEFINE
        printf("Raw data dump\n Modulus length: %zi\n", packet.mod_len);
        for(i = 0; i < packet.mod_len; i++) {
          printf("%02X", packet.mod[i]);
        }
        
        printf("\nPrivate exponent length: %zi\n", packet.priv_len);
        for(i = 0; i < packet.priv_len; i++) {
          printf("%02X", packet.priv_exp[i]);
        }
        
          printf("\nPublic exponent length: %zi\n", packet.pub_len);
        for(i = 0; i < packet.pub_len; i++) {
          printf("%02X", packet.pub_exp[i]);
        }
      #endif

      printf("Public Key:\n%s\n", public_key);
      printf("Private Key:\n%s\n", private_key);
    
      char *plaintext = test_texts[tests];
      printf("Plain Text:\n%s\n\n", plaintext);
    
      char *ciphertext;
      ciphertext = encrypt(&packet, public_key, plaintext);
      printf("Software-calculated cipher Text:\n%s\n", ciphertext);
    
          printf("\nCiphertext length: %zi\n", packet.cipher_len);
        for(i = 0; i < packet.cipher_len; i++) {
          printf("%02X", packet.ciphertext[i]);
        }		  
    
    
      char *decrypted;
      decrypted = decrypt(private_key, ciphertext);
      printf("\nSoftware-decrypted plain Text:\n%s\n\n", decrypted);
    
      /*char *signature;
      signature = sign(private_key, plaintext);
      printf("Software signature:\n%s\n", signature);
      
      if (verify(public_key, plaintext, signature)) {
        printf("Software signature GOOD!\n");
      } else {
        printf("Software signature BAD!\n");
      }*/
      
      printf("Sending to FPGA..\n");

      
      // Pack the command for transport to FPGA
      // Command is specified in Command.h, run build and look in tbinclude
      // Assuming mod_len >= priv_len/pub_len/len(ciphertext)
      for(i = 0; i < packet.mod_len; i++) {
        cmd.m_modulus = packet.mod[packet.mod_len - i - 1];
        
        // Send the data for decryption
        if(i < packet.priv_len) {
          cmd.m_exponent = packet.priv_exp[packet.priv_len - i - 1];
        } else {
          cmd.m_exponent = 0;
        }
        
        // Since the exponent is short, pack it backwards
        if(i < packet.cipher_len) {
          cmd.m_data = packet.ciphertext[packet.cipher_len - i - 1];
        } else {
          cmd.m_data = 0;
        }
        
        //printf("Sending message %i, mod: %X coeff: %X data:%X\n", i, cmd.m_data.get(), cmd.m_exponent.get(), cmd.m_data.get());
        inport.sendMessage(cmd);
      }
        
      printf("Sending padding, 1 packet");
      cmd.m_modulus = 0;
      cmd.m_exponent = 0;
      cmd.m_data = 0;
      timer_start(&hard_time);
      inport.sendMessage(cmd);
        
      printf("Getting result..");
      
      std::cout << "Result: " << outport.getMessage() << std::endl;
      timer_poll("FPGA wall time: %d.%06d    seconds\n", &hard_time);
    }

    std::cout << "shutting down..." << std::endl;
    shutdown.blocking_send_finish();
    scemi_service_thread->stop();
    scemi_service_thread->join();
    SceMi::Shutdown(sceMi);
    std::cout << "finished" << std::endl;

    return 0;
}

