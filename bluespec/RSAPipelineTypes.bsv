import GetPut::*;

typedef 1024 BI_SIZE;
typedef Bit#(16) CHUNK_T;
typedef TMul#(8,SizeOf#(CHUNK_T)) CHUNK_SIZE;
typedef TDiv#(BI_SIZE,CHUNK_SIZE) NCHUNKS;
typedef Bit#(BI_SIZE) BIG_INT;

// SceMi Types
typedef Bit#(8) RSA_PACKET;
typedef TDiv#(BI_SIZE, 8) PACKET_COUNT;

interface RSAPipeline;
endinterface


