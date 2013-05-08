import GetPut::*;
import ClientServer::*;

//typedef 1032 BI_SIZE;
typedef 520 BI_SIZE;
//typedef 1032 NUM_BITS_IN_CHUNK;

//typedef 1024 RSA_SIZE;
typedef Bit#(BI_SIZE) BIG_INT;

// SceMi Types
typedef 8 RSA_PACKET_SIZE;
typedef Bit#(RSA_PACKET_SIZE) RSA_PACKET;
typedef TDiv#(BI_SIZE, 8) PACKET_COUNT;

// Adder types
typedef 2 ADD_STAGES; // MUST BE DIVISIBLE INTO BI_SIZE
typedef TDiv#(BI_SIZE, ADD_STAGES) ADD_WIDTH;

typedef struct {
  BIG_INT a;
  BIG_INT b;
  Bit#(1) c_in;
} AdderOperands deriving (Bits, Eq);

typedef Server#(
  AdderOperands,
  BIG_INT
) Adder;


// Memory Types
typedef Bit#(16) Addr;
