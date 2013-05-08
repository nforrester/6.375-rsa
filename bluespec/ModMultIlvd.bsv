import RSAPipelineTypes::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import PipelineAdder::*;
//import CLAdder::*;


typedef enum {Idle, Shift, AddPI, PsubM1, PsubM2, PsubM3} State deriving (Bits,Eq);
interface ModMultIlvd;
    method Action putData(Vector#(3, BIG_INT) data);
    method ActionValue#(BIG_INT) getResult();
endinterface


// Interface:
// Put: Of type  Vector#(3, BIG_INT)
// [0] = X, [1] = Y, [2]= M
// Get: Of type  FIFO#(BIG_INT)
module mkModMultIlvd(ModMultIlvd);
  Reg#(BIG_INT) x_val <- mkReg(0);
  Reg#(BIG_INT) y_val <- mkReg(0);
  Reg#(BIG_INT) m_val <- mkReg(0);
  Reg#(BIG_INT) p_val <- mkReg(0);
    
  FIFO#(Bit#(1)) doneFIFO <- mkSizedFIFO(1);
  Reg#(Bit#(32)) i <- mkReg(0);
  Reg#(State) state <- mkReg(Idle);
  
  Reg#(Maybe#(Bit#(0))) wait_for_add <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub1 <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub2 <- mkReg(tagged Invalid);

//	Adder adder <- mkCLAdder();
	Adder adder <- mkFoldedAdder();
 
  rule doShift (state == Shift);
    //$display("mod mult function i = %d", i);
    let p_shift = p_val << 1;
      
      if(x_val[i] == 1)begin
      	// Pack the add request
    	  let operands = 	AdderOperands{a:p_shift, b:y_val, do_sub:False};
        adder.request.put(operands);
        wait_for_add <= tagged Valid 0;
        end
      
      p_val <= p_shift;
      state <= PsubM1;
  endrule
    
  rule doPSubM1(state == PsubM1);
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
      let operands = 	AdderOperands{a:p_val_result, b:m_val, do_sub:True};
      adder.request.put(operands);
      wait_for_sub1 <= tagged Valid 0;
    	state <= PsubM2;
    end else begin
			  // No need to waste 2 cycles
    	  i <= i - 1;
    
			  if(i == 0) begin
			  	doneFIFO.enq(0);
			    state <= Idle;
			  end
			  else begin
			    state <= Shift;
			  end
    end
    
    p_val <= p_val_result;
    
  endrule

  rule doPSubM2 (state == PsubM2);
    let p_val_result = ?;
    if(isValid(wait_for_sub1))begin
      wait_for_sub1 <= tagged Invalid;
      p_val_result <- adder.response.get();
      end
    else begin
      p_val_result = p_val;
    end

    if (p_val_result >= m_val) begin
      let operands = 	AdderOperands{a:p_val_result, b:m_val, do_sub:True};
      adder.request.put(operands);
			state <= PsubM3;
    end else begin
    	  // No need to waste a cycle
    	  i <= i - 1;
    
			  if(i == 0) begin
			  	doneFIFO.enq(0);
			    state <= Idle;
			  end
			  else begin
			    state <= Shift;
			  end
    end

    p_val <= p_val_result;

	endrule
	
  rule doPSubM3(state == PsubM3);

    let x <- adder.response.get();
    p_val <= x;

	  i <= i - 1;
	    
	  if(i == 0)begin
	  	doneFIFO.enq(0);
	    state <= Idle;
	  end
	  else begin
	    state <= Shift;
	  end
  endrule
   
    method Action putData(Vector#(3, BIG_INT) data);
      x_val <= data[0]; 
		  y_val <= data[1];
		  m_val <= data[2];
      i <= fromInteger(valueof(BI_SIZE))-1;
      p_val <= 0;
      wait_for_add <= tagged Invalid;
      state <= Shift;
    endmethod

    method ActionValue#(BIG_INT) getResult();
        doneFIFO.deq();
        return p_val;
    endmethod
endmodule


module mkModMultTest (Empty);

    ModMultIlvd modmult <- mkModMultIlvd();

    Reg#(Bit#(32)) feed <- mkReg(0);
    
    rule store(feed == 0);
      feed <= 1;
          Vector#(3, BIG_INT) packet_out=?;
    packet_out[0] = 1337133713371337133713337;
    packet_out[1] = 9999999;
    packet_out[2] = 133713371337;
      modmult.putData(packet_out);
    endrule

    rule load(feed == 1);
      let result = ?;		
      result <-	modmult.getResult();
      $display("Result: %d", result);
      $display("Golden: 133383371370");
      $finish();

      feed <= 0;
    endrule
endmodule