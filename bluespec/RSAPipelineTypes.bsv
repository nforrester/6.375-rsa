import GetPut::*;

typedef 1024 RSA_SIZE;
typedef Bit#(BI_SIZE) BIG_INT;
typedef TAdd#(RSA_SIZE, 8) BI_SIZE;

// Adder types
typedef 8 ADD_STAGES; // MUST BE DIVISIBLE INTO BI_SIZE
typedef TDiv#(BI_SIZE, ADD_STAGES) ADD_WIDTH;

typedef struct {
  BIG_INT a;
  BIG_INT b;
  Bool do_sub;
} AdderOperands deriving (Bits, Eq);


// Memory Types
typedef Bit#(16) Addr;
