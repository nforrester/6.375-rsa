#include <stdio.h>
#include <sys/time.h>
#include <gpg-error.h>

#define GCRYPT_NO_DEPRECATED
#include <gcrypt.h>

void timer_start(struct timeval *start) {
	gettimeofday(start, NULL);
}

void timer_poll(char *format, struct timeval *start) {
	struct timeval now, diff;
	gettimeofday(&now, NULL);
	timersub(&now, start, &diff);
	fprintf(stderr, format, diff.tv_sec, diff.tv_usec);
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

void generate_key(char **public_key, char **private_key) {
	gcry_error_t error;

	// Generate a reduced strength (to save time) RSA key, 1024 bits long
	gcry_sexp_t params = sexp_new("(genkey (rsa (transient-key) (nbits 4:1024)))");
	gcry_sexp_t r_key;
	if ((error = gcry_pk_genkey(&r_key, params))) {
		printf("Error in gcry_pk_genkey(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	gcry_sexp_t public_sexp  = gcry_sexp_nth(r_key, 1);
	gcry_sexp_t private_sexp = gcry_sexp_nth(r_key, 2);

	*public_key = sexp_string(public_sexp);
	*private_key = sexp_string(private_sexp);
}

char* encrypt(char *public_key, char *plaintext){
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
	timer_poll("libgcrypt    Encrypt: %d.%06d    seconds\n", &timer);

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
	timer_poll("libgcrypt    Decrypt: %d.%06d    seconds\n", &timer);

	gcry_mpi_t r_mpi = gcry_sexp_nth_mpi(r_plain, 0, GCRYMPI_FMT_USG);

	unsigned char *plaintext;
	size_t plaintext_size;
	if ((error = gcry_mpi_aprint(GCRYMPI_FMT_HEX, &plaintext, &plaintext_size, r_mpi))) {
		printf("Error in gcry_mpi_aprint(): %s\nSource: %s\n", gcry_strerror(error), gcry_strsource(error));
		exit(1);
	}

	return plaintext;
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

int main() {
	crypto_init();

	char *public_key, *private_key;

	generate_key(&public_key, &private_key);
	printf("Public Key:\n%s\n", public_key);
	printf("Private Key:\n%s\n", private_key);

	char *plaintext = "DEADBEEF0123456789";
	printf("Plain Text:\n%s\n\n", plaintext);

	char *ciphertext;
	ciphertext = encrypt(public_key, plaintext);
	printf("Ciper Text:\n%s\n", ciphertext);

	char *decrypted;
	decrypted = decrypt(private_key, ciphertext);
	printf("Decrypted Plain Text:\n%s\n\n", decrypted);

	char *signature;
	signature = sign(private_key, plaintext);
	printf("Signature:\n%s\n", signature);

	if (verify(public_key, plaintext, signature)) {
		printf("Signature GOOD!\n");
	} else {
		printf("Signature BAD!\n");
	}

	return 0;
}
