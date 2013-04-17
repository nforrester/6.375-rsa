import RSAPipelineTypes::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;

typedef enum {Shift, XiY, AddPI, PsubM1, PsubM2, Done} State deriving (Bits,Eq);
typedef Server#(
  Vector#(3, BIG_INT),  // changed this to hardcoded 3 since the algo is hardcoded
  BIG_INT
) ModMultIlvd;


// Interface:
// Put: Of type  Vector#(3, BIG_INT)
// [0] = X, [1] = Y, [2]= M
// Get: Of type  FIFO#(BIG_INT)
module mkModMultIlvd(ModMultIlvd);
  FIFO#(Vector#(3, BIG_INT)) inputFIFO <- mkFIFO();
  FIFO#(BIG_INT) outputFIFO <- mkFIFO();
  /*Reg#(Bit#(11)) i <- mkReg(0);
  Reg#(BIG_INT) P <- mkReg(0);
  Reg#(BIG_INT) I  <- mkRegU;
  Reg#(Bit#(5)) state <- mkReg(Shift);

  rule doShift (state == Shift);
    P <= P << 1;
    state <= XiY;
  endrule

  rule doXiY (state == XiY);
    let in = inputFIFO.first();
    let X = in[0];
    let Y = in[1];
 
    for(Integer j = 0; j < NCHUNKS; j = j + 1)begin
      Bit#(CHUNK_SIZE) y = ?;
      Bit#(CHUNK_SIZE) x = zeroExtend(X[i]);
        
      for(Integer k = 0; k < CHUNK_SIZE; k = k +1)begin
        let idx = j*CHUNK_SIZE + k;
        y[k] = Y[idx];
       end

      Bit#(CHUNK_SIZE) res = y*x;
      for(Integer k = 0; k < CHUNK_SIZE; k = k +1)begin
        let idx = j*CHUNK_SIZE + k;
        I[idx] <= res[k];
        end
      end
      state <= AddPI;
    endrule
    rule doAddPI(state == AddPI);
      P <= P + I;
      state <= PSubM1
  endrule

  rule doPSubM1(state == PSubM1);
    let in = inputFIFO.first();
    M = in[2];
    if (P >= M) begin
      P <= P - M;
    end
    state <= PSubM2;
  endrule

  rule doPSubM2 (state == PSubM2);
    if (P >= M) begin
      P <= P - M;
    end
    i <= + 1;

    if(i+1 == BI_SIZE)begin
      state <= Done;
    end
    else begin
      state <= Shift;
    end

  end

  rule doComplete (state == Done);
    inputFIFO.deq();
    i = 0;
    outputFIFO.enq(P);
    P <= 0;
  endrule*/

   
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule

module mkModMultIlvdTest (Empty);
  // some unit test
endmodule

