import GetPut::*;

typedef 520 BI_SIZE;
typedef 520 NUM_BITS_IN_CHUNK;

/*
typedef 1032 BI_SIZE;
typedef 1032 NUM_BITS_IN_CHUNK;
*/

typedef Bit#(NUM_BITS_IN_CHUNK) CHUNK_T;
typedef TDiv#(BI_SIZE,NUM_BITS_IN_CHUNK) NCHUNKS;
typedef Bit#(BI_SIZE) BIG_INT;


// SceMi Types
typedef 8 RSA_PACKET_SIZE;
typedef Bit#(RSA_PACKET_SIZE) RSA_PACKET;
typedef TDiv#(BI_SIZE, 8) PACKET_COUNT;

// pointers for B, E, N and Result
typedef TMul#(NUM_BITS_IN_CHUNK,0)  B_0;
typedef TMul#(NUM_BITS_IN_CHUNK,1)  E_0;
typedef TMul#(NUM_BITS_IN_CHUNK,2)  N_0;
typedef TMul#(NUM_BITS_IN_CHUNK,3)  RES_0;

// Adder types
typedef 8 ADD_WIDTH; // MUST BE DIVISIBLE INTO BI_SIZE
typedef TDiv#(BI_SIZE, ADD_WIDTH) ADD_STAGES;


interface RSAPipeline;
  interface MemInitIfc memInit;
  interface Get#(BIG_INT) get_result;
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
