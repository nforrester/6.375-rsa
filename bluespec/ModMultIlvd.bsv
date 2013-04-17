import RSAPipelineTypes::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
typedef 3 NUM_ARGS;

typedef enum {Shift, XiY, AddPI, PsubM1, PsubM2, Done} State deriving (Bits,Eq);
typedef Server#(
  Vector#(NUM_ARGS, BIG_INT), 
  BIG_INT
) ModMultIlvd;

module mkModMultIlvd(ModMultIlvd);
  FIFO#(Vector#(NUM_ARGS, BIG_INT)) inputFIFO <- mkFIFO();
  FIFO#(BIG_INT) outputFIFO <- mkFIFO();
  Reg#(Bit#(11)) i <- mkReg(0);
  Reg#(BIG_INT) p_val <- mkReg(0);
  Reg#(BIG_INT) i_val  <- mkRegU;
  Reg#(State) state <- mkReg(Shift);

  rule doShift (state == Shift);
    p_val <= p_val << 1;
    state <= XiY;
  endrule

  rule doXiY (state == XiY);
    let in = inputFIFO.first();
    let x_val = in[0];
    let y_val = in[1];
 
    for(Integer j = 0; j < valueof(NCHUNKS); j = j + 1)begin
      Bit#(CHUNK_SIZE) y = ?;
      Bit#(CHUNK_SIZE) x = zeroExtend(x_val[i]);
        
      for(Integer k = 0; k < valueof(CHUNK_SIZE); k = k +1)begin
        let idx = j*valueof(CHUNK_SIZE) + k;
        y[k] = y_val[idx];
       end

      Bit#(CHUNK_SIZE) res = y*x;
      for(Integer k = 0; k < valueof(CHUNK_SIZE); k = k +1)begin
        let idx = j*valueof(CHUNK_SIZE) + k;
        i_val[idx] <= res[k];
        end
      end
      state <= AddPI;
    endrule
    rule doAddPI(state == AddPI);
      p_val <= p_val + i_val;
      state <= PsubM1;
  endrule

  rule doPSubM1(state == PsubM1);
    let in = inputFIFO.first();
    let m_val = in[2];
    if (p_val >= m_val) begin
      p_val <= p_val - m_val;
    end
    state <= PsubM2;
  endrule

  rule doPSubM2 (state == PsubM2);
    let in = inputFIFO.first();
    let m_val = in[2];  
    if (p_val >= m_val) begin
      p_val <= p_val - m_val;
    end
    i <= + 1;

    if(i+1 == fromInteger( valueof(BI_SIZE)))begin
      state <= Done;
    end
    else begin
      state <= Shift;
    end

  endrule

  rule doComplete (state == Done);
    inputFIFO.deq();
    i <= 0;
    outputFIFO.enq(p_val);
    p_val <= 0;
  endrule

   
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule

module mkModMultIlvdTest (Empty);
  // some unit test
endmodule

