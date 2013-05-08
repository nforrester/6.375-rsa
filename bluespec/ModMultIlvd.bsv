import RSAPipelineTypes::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import PipelineAdder::*;
import CLAdder::*;
import SlowClkAdder::*;

module mkAdder(Adder);
// Adder adder <- mkSlowClkAdder();
 	Adder adder <- mkCLAdder();
//	Adder adder <- mkSimpleAdder();
//	Adder adder <- mkPipelineAdder();
    interface Put request = adder.request;
    interface Get response = adder.response;
endmodule

module mkSubtracter(Adder);
//  Adder adder <- mkSlowClkAdder();
    Adder adder <- mkCLAdder();
//	Adder adder <- mkSimpleAdder();
//	Adder adder <- mkPipelineAdder();
    interface Put request;
      method Action put(AdderOperands x);
        adder.request.put(AdderOperands{a:x.a, b:~x.b, c_in:1});
      endmethod
    endinterface
    interface Get response = adder.response;
endmodule



typedef enum {Shift, XiY, AddPI, PsubM1, PsubM2, PsubM3,  Done} State deriving (Bits,Eq);
typedef Server#(
  Vector#(3, BIG_INT),  // changed this to hardcoded 3 since the algo is hardcoded
  BIG_INT
) ModMultIlvd;

// Interface:
// Put: Of type  Vector#(3, BIG_INT)
// [0] = X, [1] = Y, [2]= M
// Get: Of type  FIFO#(BIG_INT)
module mkModMultIlvd(ModMultIlvd);
  FIFO#(Vector#(3, BIG_INT)) inputFIFO <- mkSizedFIFO(1);
  FIFO#(BIG_INT) outputFIFO <- mkSizedFIFO(1);
  Reg#(Bit#(32)) i <- mkReg(0);
  Reg#(BIG_INT) p_val <- mkReg(0);
  Reg#(BIG_INT) x_val <- mkRegU;
  Reg#(State) state <- mkReg(Shift);
  
  Reg#(Maybe#(Bit#(0))) wait_for_add <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub1 <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub2 <- mkReg(tagged Invalid);
  Adder adder <- mkAdder();
  Adder subtracter <- mkSubtracter();


  Reg#(Bool) hack <- mkReg(False);
  
  rule init(!hack);
      hack <= True;
      i <= fromInteger(valueof(BI_SIZE))-1;
      p_val <= 0;
      wait_for_add <= tagged Invalid;
      state <= Shift;
      let in = inputFIFO.first();
      let x_temp = in[0];
      BIG_INT x_out = ?;
      for (Integer ptr= 0; ptr < valueof(BI_SIZE) ; ptr = ptr +1) begin
        x_out[valueof(BI_SIZE)-1-ptr] = x_temp[ptr];
      end
      x_val <= x_out; 

  endrule
 
  rule doShift (state == Shift  && hack);
    let next_p = p_val << 1;
    p_val <= next_p;
    state <= XiY;
  endrule

  rule doXiY (state == XiY);
    let in = inputFIFO.first();
    let y_val = in[1];
    let x_tmp = in[0]; 
    let next_p = ?;
     
    if(x_tmp[i] == 1)begin
      	// Pack the add request
    	  let operands = 	AdderOperands{a:p_val, b:y_val, c_in:0};
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
      let operands = 	AdderOperands{a:p_val_result, b:m_val, c_in:1};
      subtracter.request.put(operands);
      wait_for_sub1 <= tagged Valid 0;
    end
    
    else begin
      p_val <= p_val_result;
    end
    
    state <= PsubM2;
  endrule




  rule doPSubM2 (state == PsubM2);
    let in = inputFIFO.first();
    let m_val = in[2];  
    let p_val_result = ?;
    if(isValid(wait_for_sub1))begin
      wait_for_sub1 <= tagged Invalid;
      p_val_result <- subtracter.response.get();    
      
      if (p_val_result >= m_val) begin
        let operands = 	AdderOperands{a:p_val_result, b:m_val, c_in:1};
        subtracter.request.put(operands);
        wait_for_sub2 <= tagged Valid 0;
      end
    end
    else begin
      p_val_result = p_val;
    end
    p_val <= p_val_result;
    state <= PsubM3;
	endrule
	
  rule doPSubM3(state == PsubM3);
    if(isValid(wait_for_sub2))begin
      let x <- subtracter.response.get();
      p_val <= x;
      wait_for_sub2 <= tagged Invalid;
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
    state <= Shift;
  endrule
   
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule
