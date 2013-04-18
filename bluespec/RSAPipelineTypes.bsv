import GetPut::*;
/*
typedef 16 BI_SIZE;
typedef 16 NUM_BITS_IN_CHUNK;
typedef Bit#(NUM_BITS_IN_CHUNK) CHUNK_T;
typedef TMul#(8,NUM_BITS_IN_CHUNK) CHUNK_SIZE;
typedef TDiv#(BI_SIZE,CHUNK_SIZE) NCHUNKS;
typedef Bit#(BI_SIZE) BIG_INT;
*/


typedef 1024 BI_SIZE;
typedef 1024 NUM_BITS_IN_CHUNK;
typedef Bit#(NUM_BITS_IN_CHUNK) CHUNK_T;
typedef TDiv#(BI_SIZE,NUM_BITS_IN_CHUNK) NCHUNKS;
typedef Bit#(BI_SIZE) BIG_INT;


// SceMi Types
typedef 8 RSA_PACKET_SIZE;
typedef Bit#(RSA_PACKET_SIZE) RSA_PACKET;
typedef TDiv#(BI_SIZE, 8) PACKET_COUNT;

// pointers for B, E, N and Result
typedef TMul#(BI_SIZE,0)  B_0;
typedef TMul#(BI_SIZE,1)  E_0;
typedef TMul#(BI_SIZE,2)  N_0;
typedef TMul#(BI_SIZE,3)  RES_0;


interface RSAPipeline;
  interface MemInitIfc memInit;
  interface Get#(CHUNK_T) get_result;
endinterface


// Memory Types
typedef Bit#(16) Addr;


typedef struct {
    Addr addr;
    CHUNK_T data;
} MemInitLoad deriving(Eq, Bits);


typedef union tagged {
   MemInitLoad InitLoad;
   void InitDone;
} MemInit deriving(Eq, Bits);


interface MemInitIfc;
  interface Put#(MemInit) request;
  method Bool done();
endinterface


typedef struct{
    Bool  op;
    Addr  addr;
    CHUNK_T  data;
} MemReq deriving(Eq,Bits);
