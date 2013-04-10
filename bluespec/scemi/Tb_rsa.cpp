
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



int main(int argc, char* argv[])
{
    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");
    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);
    	
    // Initialize the crypto library
    crypto_init();

    // Initialize the SceMi inport
    InportProxyT<Command> inport ("", "scemi_rsaxactor_req_inport", sceMi);

    // Initialize the SceMi outport
    OutportQueueT<Value> outport ("", "scemi_rsaxactor_resp_outport", sceMi);

    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);

    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread (sceMi);

    Command cmd;

		char *public_key, *private_key;
	
		printf("Generating keypair in software...");
		generate_key(&public_key, &private_key);
		printf("Public Key:\n%s\n", public_key);
		printf("Private Key:\n%s\n", private_key);
	
		char *plaintext = "DEADBEEF0123456789";
		printf("Plain Text:\n%s\n\n", plaintext);
	
		char *ciphertext;
		ciphertext = encrypt(public_key, plaintext);
		printf("Software-calculated cipher Text:\n%s\n", ciphertext);
	
		char *decrypted;
		decrypted = decrypt(private_key, ciphertext);
		printf("Software-decrypted plain Text:\n%s\n\n", decrypted);
	
		char *signature;
		signature = sign(private_key, plaintext);
		printf("Software signature:\n%s\n", signature);
		
		if (verify(public_key, plaintext, signature)) {
			printf("Software signature GOOD!\n");
		} else {
			printf("Software signature BAD!\n");
		}

		
    cmd.the_tag = Command::tag_Operate;
    cmd.m_Operate.m_val = val;
    cmd.m_Operate.m_op = operationof(op);

    printf("Sending to FPGA..");
    inport.sendMessage(cmd);
    outport.getMessage();

    std::cout << "shutting down..." << std::endl;
    shutdown.blocking_send_finish();
    scemi_service_thread->stop();
    scemi_service_thread->join();
    SceMi::Shutdown(sceMi);
    std::cout << "finished" << std::endl;

    return 0;
}

