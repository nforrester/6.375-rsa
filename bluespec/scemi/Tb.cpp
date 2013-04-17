
#include <iostream>
#include <unistd.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>

#include "bsv_scemi.h"
#include "SceMiHeaders.h"
#include "ResetXactor.h"
int NUM_INPUTS=0;
FILE * out = NULL;
long int outCount = 0;
// Initialize the memories from the given vmh file.
bool mem_init(const char *filename, InportProxyT<MemInit>& mem)
{
    char *line;
    size_t len = 0;
    int read;

    FILE *file = fopen(filename, "r");

    if (file == NULL)
    {
        printf( "could not open VMH file %s.\n", filename);
        return false;
    }

    uint32_t addr = 0;
    while ((read = getline(&line, &len, file)) != -1) {
        if (read != 0) {
            if (line[0] == '@') {
                addr = strtoul(&line[1], NULL, 16);
            } else {
                uint32_t data = strtoul(line, NULL, 16);

                MemInit msg;
                msg.the_tag = MemInit::tag_InitLoad;
                msg.m_InitLoad.m_addr = addr;
                msg.m_InitLoad.m_data = data;
                mem.sendMessage(msg);
                printf("addr: %x\tdata: %x\n",addr,data);
                addr++;
            }
        }
    }

    free(line);
    fclose(file);
    NUM_INPUTS=addr;
    MemInit msg;
    msg.the_tag = MemInit::tag_InitDone;
    mem.sendMessage(msg);
    return true;
}
void out_cb(void* x, const CHUNK_T &res)
  { 
    if(outCount < NUM_INPUTS){
      int a = res.get() & 0xFF;
      int b = (res.get() & 0xFF00) >> 8;
      printf("a = %x\t b= %x\n", a,b);
      fputc(a, out);
      fputc(b, out);
      outCount++;
     }else{
      fclose(out);
      out = NULL;
      }

    }

int main(int argc, char* argv[])
{
    if (argc < 2) {
        printf( "usage: TestDriver <vmh-file>\n");
        return 1;
    }
    char* vmh = argv[1];

    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");
    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);

    // Initialize the SceMi ports
    InportProxyT<MemInit> mem("", "scemi_mem_inport", sceMi);
    
    OutportProxyT<CHUNK_T> outport("", "scemi_rsa_result_outport", sceMi);
    outport.setCallBack(out_cb,NULL);


  //  ResetXactor reset("", "scemi", sceMi);
    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);

    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread(sceMi);

    // Reset the dut.
   // reset.reset();
    out = fopen("out.txt", "wb");

    // Initialize the memories.
    if (!mem_init(vmh, mem)) {
        printf( "Failed to load memory\n");
        std::cout << "shutting down..." << std::endl;
        shutdown.blocking_send_finish();
        scemi_service_thread->stop();
        scemi_service_thread->join();
        SceMi::Shutdown(sceMi);
        std::cout << "finished" << std::endl;
        return 1;
    }

    while (outCount < NUM_INPUTS){}
    fclose(out);

    shutdown.blocking_send_finish();
    scemi_service_thread->stop();
    scemi_service_thread->join();
    SceMi::Shutdown(sceMi);

    return 0;
}

