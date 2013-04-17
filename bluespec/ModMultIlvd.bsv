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
  Reg#(Bit#(32)) i <- mkReg(0);
  Reg#(BIG_INT) p_val <- mkReg(0);
  Reg#(BIG_INT) i_val  <- mkRegU;
  Reg#(State) state <- mkReg(Shift);

  Reg#(Bool) hack <- mkReg(False);
  
  rule init(!hack);
    $display("hack fix zeros");
      hack <= True;
      i <= 0;
      p_val <= 0;
      state <= Shift;
  endrule

 
  rule doShift (state == Shift  && hack);
    $display("mod mult function i = %d", i);
    let next_p = p_val << 1;
    p_val <= next_p;
    state <= XiY;
    $display("doShift\t\t P = %d", next_p);
  endrule

  rule doXiY (state == XiY);
    let in = inputFIFO.first();
    let x_val = in[0];
    let y_val = in[1];
      
      let next_p = ?;
      if(x_val[i] == 1)begin
        i_val <= y_val;
        next_p = p_val + y_val;
        p_val <= next_p;
        end
      else begin
        next_p = p_val;
        end
      $display("doXiY\t\tp = %d", next_p);
        
      state <= PsubM1;

    i <= i + 1;
    endrule
    
  rule doPSubM1(state == PsubM1);
    let in = inputFIFO.first();
    let m_val = in[2];
    let next_p = ?;
    if (p_val >= m_val) begin
      next_p = p_val - m_val;
      p_val <= next_p;
    end
    else begin
      next_p = p_val;
    end
    state <= PsubM2;
    $display("doPSubM1\t\tp = %d", next_p);
  endrule

  rule doPSubM2 (state == PsubM2);
    let in = inputFIFO.first();
    let m_val = in[2];  
    let next_p = ?;
    if (p_val >= m_val) begin
      next_p = p_val - m_val;
      p_val <= next_p;
    end
    else begin
      next_p = p_val;
    end

    $display("doPSubM2\t\tp = %d", next_p);
    if(i+1 == fromInteger( valueof(BI_SIZE)))begin
      state <= Done;
    end
    else begin
      state <= Shift;
    end

  endrule

  rule doComplete (state == Done);
    $display("\t\t complete p = %d", p_val);
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

