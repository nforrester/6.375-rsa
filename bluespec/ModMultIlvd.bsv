import RSAPipelineTypes::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;

typedef enum {Init, Shift, XiY, Add1, Add2,Add3, PsubM1, PsubM2, Done} State deriving (Bits,Eq);
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
  Reg#(Bit#(32)) i <- mkReg(fromInteger(valueof(BI_SIZE))-1);
  Reg#(BIG_INT) p_val <- mkReg(0);
  Reg#(State) state <- mkReg(Init);
  Reg#(BIG_INT) x_val <- mkRegU();

  Reg#(Bit#(1))carry <- mkRegU();
  Reg#(Bit#(512))bottom_sum <- mkRegU();
  Reg#(Bit#(513))top_sum <- mkRegU();


  rule doInit (state == Init);
    // reverse x bits
    let in = inputFIFO.first();
    let x_temp = in[0];
    BIG_INT x_out = ?;
    for (Integer ptr= 0; ptr < valueof(BI_SIZE) ; ptr = ptr +1) begin
      x_out[valueof(BI_SIZE)-1-ptr] = x_temp[ptr];
    end
    x_val <= x_out;
    state <= Shift;
  endrule
  rule doShift (state == Shift);
    let next_p = p_val << 1;
    p_val <= next_p;
    state <= XiY;
  endrule

  rule doXiY (state == XiY);
    let in = inputFIFO.first();
   // let x_val = in[0];
    let y_val = in[1];
      
      let next_p = ?;
      x_val <= x_val >> 1;
      if(x_val[0] == 1)begin
        state <= Add1;
       // next_p = p_val + y_val;
        //p_val <= next_p;
        end
      else begin
        state <= PsubM1;
       // next_p = p_val;
        end
      //state <= PsubM1;
    endrule
    
  rule doAdd1 (state == Add1);
    let in = inputFIFO.first();
    let y_val = in[1];
    Bit#(512) y_trunc = truncate(y_val);
    Bit#(512) p_trunc = truncate(p_val);
    
    Bit#(513) sum = zeroExtend(y_trunc) + zeroExtend(p_trunc);
    Bit#(1) carry = sum[512];
    bottom_sum <= truncate(sum);
    state <= Add2;

  endrule

  rule doAdd2(state == Add2);
    let in = inputFIFO.first();
    let y_val = in[1];
    Integer j = 0;
    Bit#(512) y_trunc = ?;
    Bit#(512) p_trunc = ?;

    for(Integer ptr = 513; ptr < 1024; ptr=ptr+1)begin
      y_trunc[j] = y_val[ptr];
      p_trunc[j] = p_val[ptr];
      j = j +1;
    end
    
    top_sum <= zeroExtend(y_trunc) + zeroExtend(p_trunc) ;
 /*   Bit#(513) sum = zeroExtend(y_trunc) + zeroExtend(p_trunc) +zeroExtend(carry);
   
    for(Integer ptr = 0; ptr < 512; ptr=ptr +1) begin
      p_val[ptr] <= bottom_sum[ptr];
    end

    j = 0;
    for(Integer ptr = 512; ptr < 1025; ptr=ptr+1)begin
      p_val[ptr] <= sum[j];
      j = j +1;
    end
    state <= PsubM1;*/
    state <= Add3;
    endrule


  rule doAdd3(state ==Add3);
  Bit#(513) sum = top_sum + zeroExtend(carry);

  for(Integer ptr = 0; ptr < 512; ptr=ptr +1) begin
      p_val[ptr] <= bottom_sum[ptr];
    end

    Integer j = 0;
    for(Integer ptr = 512; ptr < 1025; ptr=ptr+1)begin
      p_val[ptr] <= sum[j];
      j = j +1;
    end

  state <= PsubM1;
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
    //$display("doPSubM1\t\tp = %d", next_p);
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
    
    i <= i -1;
    if(i==0)begin
      state <= Done;
    end
    else begin
      state <= Shift;
    end

  endrule

  rule doComplete (state == Done);
  let in = inputFIFO.first();
    inputFIFO.deq();
    outputFIFO.enq(p_val);
    p_val <= 0;
    i <= fromInteger(valueof(BI_SIZE))-1;
    state <= Init;
  endrule


   
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule

