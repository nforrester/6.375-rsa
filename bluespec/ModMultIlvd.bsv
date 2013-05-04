import RSAPipelineTypes::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
//import PipelineAdder::*;
import CLAdder::*;


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
  Reg#(BIG_INT) x_val <- mkRegU;
  Reg#(State) state <- mkReg(Shift);
  
  Reg#(Maybe#(Bit#(0))) wait_for_add <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub1 <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub2 <- mkReg(tagged Invalid);
//	Adder adder <- mkCLAdder();
	Adder adder <- mkSimpleAdder();
	Adder subtracter <- mkSubtracter();
  Reg#(Bool) hack <- mkReg(False);
  
  rule init(!hack);
    //$display("hack fix zeros");
      hack <= True;
      i <= fromInteger(valueof(BI_SIZE))-1;
      p_val <= 0;
      wait_for_add <= tagged Invalid;
      state <= Shift;
   //   let in = inputFIFO.first();
   //   x_val <= in[0];
      let in = inputFIFO.first();
      let x_temp = in[0];
      BIG_INT x_out = ?;
      for (Integer ptr= 0; ptr < valueof(BI_SIZE) ; ptr = ptr +1) begin
        x_out[valueof(BI_SIZE)-1-ptr] = x_temp[ptr];
      end
      x_val <= x_out; 

  endrule
 
  rule doShift (state == Shift  && hack);
    //$display("mod mult function i = %d", i);
    let next_p = p_val << 1;
    p_val <= next_p;
    state <= XiY;
    //$display("doShift\t\tP = %d", next_p);
  endrule

  rule doXiY (state == XiY);
    let in = inputFIFO.first();
   // let x_val = in[0];
    let y_val = in[1];
      let x_tmp = in[0]; 
      let next_p = ?;
     
      if(x_tmp[i] == 1)begin
      	// Pack the add request
      	Vector#(2, BIG_INT) operands;
    		operands[0] = p_val;
    		operands[1] = y_val;
    		
        adder.request.put(operands);
        wait_for_add <= tagged Valid 0;
        end
      else begin
        next_p = p_val;
        end
        
      state <= PsubM1;
    endrule
    
  rule doPSubM1(state == PsubM1);
		let in = inputFIFO.first();
    let m_val = in[2];
    let next_p = ?;
    let p_val_result = ?;
    
    // Grab the result from the adder if we're waiting for it
    if(isValid(wait_for_add)) begin
			p_val_result <- adder.response.get();
			wait_for_add <= tagged Invalid;
		end else begin
			// otherwise just put in the current p_val
			p_val_result = p_val;
		end
    
    if (p_val_result >= m_val) begin
      // pack the sub request
      Vector#(2, BIG_INT) operands;
      operands[0] = p_val_result;
      operands[1] = m_val;
      subtracter.request.put(operands);
      wait_for_sub1 <= tagged Valid 0;
      
      //p_val <= p_val_result - m_val;
    end
    
    else begin
      p_val <= p_val_result;
    end
    
    state <= PsubM2;
    //$display("doPSubM1\t\tp = %d", next_p);
  endrule


  rule doPSubM2 (state == PsubM2);
    let in = inputFIFO.first();
    let m_val = in[2];  
    let p_val_result = ?;
    if(isValid(wait_for_sub1))begin
      wait_for_sub1 <= tagged Invalid;
      p_val_result <- subtracter.response.get();
      end
    else begin
      p_val_result = p_val;
    end

    if (p_val_result >= m_val) begin
      p_val_result = p_val_result - m_val;
    end

    p_val <= p_val_result;
  

    //$display("doPSubM2\t\tp = %d", next_p);
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
  //%display("%d * %d mod %d = %d",in[0], in[1], in[2], p_val);
    inputFIFO.deq();
    outputFIFO.enq(p_val);
    p_val <= 0;
    i <= fromInteger(valueof(BI_SIZE))-1;
    state <= Shift;
  endrule

   
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule


