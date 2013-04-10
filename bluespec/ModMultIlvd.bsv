import RSAPipelineTypes::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
typedef 3 NUM_ARGS

typedef Server#(
  Vector#(NUM_ARGS, BIG_INT), 
  BIG_INT
) ModMultIlvd;

module mkModMultIlvd(ModMultIlvd);
  FIFO#(Vector#(NUM_ARGS, BIG_INT)) inputFIFO <- mkFIFO();
  FIFO#(BIG_INT) outputFIFO <- mkFIFO();
  
  rule modMult;
    let in = inputFIFO.first();
    inputFIFO.deq();

    let X = in[0];
    let Y = in[1];
    let M = in[2];

    BIG_INT P = 0;
    BIG_INT I = ?;

    P = P << 1;
    
    I = X & Y;

    P = P + I;

    if (P >= M) begin
      P = P - M;
    end

    if (P >= M) begin
      P = P - M;
    end
    
    outputFIFO.enq(P);
  endrule


   
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule

module mkModMultIlvdTest (Empty);
  // some unit test
endmodule

