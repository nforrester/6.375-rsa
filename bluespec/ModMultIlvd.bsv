import RSAPipelineTypes::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import PipelineAdder::*;
//import CLAdder::*;


typedef enum {Idle, Shift, XiY, AddPI, PsubM1, PsubM2, PsubM3,  Done} State deriving (Bits,Eq);
interface ModMultIlvd;
    method Action putData(Vector#(3, BIG_INT) data);
    method ActionValue#(BIG_INT) getResult();
endinterface


// Interface:
// Put: Of type  Vector#(3, BIG_INT)
// [0] = X, [1] = Y, [2]= M
// Get: Of type  FIFO#(BIG_INT)
module mkModMultIlvd(ModMultIlvd);
  Reg#(BIG_INT) y_val <- mkReg(0);
  Reg#(BIG_INT) m_val <- mkReg(0);
  
  FIFO#(Bit#(1)) doneFIFO <- mkSizedFIFO(1);
  Reg#(Bit#(32)) i <- mkReg(0);
  Reg#(BIG_INT) p_val <- mkReg(0);
  Reg#(BIG_INT) x_val <- mkRegU;
  Reg#(State) state <- mkReg(Idle);
  
  Reg#(Maybe#(Bit#(0))) wait_for_add <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub1 <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(0))) wait_for_sub2 <- mkReg(tagged Invalid);

//	Adder adder <- mkCLAdder();
	Adder adder <- mkPipelineAdder();
 
  rule doShift (state == Shift);
    //$display("mod mult function i = %d", i);
    let next_p = p_val << 1;
    p_val <= next_p;
    state <= XiY;
  endrule

  rule doXiY (state == XiY);

      if(x_val[i] == 1)begin
      	// Pack the add request
    	  let operands = 	AdderOperands{a:p_val, b:y_val, do_sub:False};
        adder.request.put(operands);
        wait_for_add <= tagged Valid 0;
        end
           
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
      
    end
    
    else begin
      p_val <= p_val_result;
    end
    
    state <= PsubM2;

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
      wait_for_sub2 <= tagged Valid 0;
    end

    p_val <= p_val_result;

    state <= PsubM3;

	endrule
	
  rule doPSubM3(state == PsubM3);
  if(isValid(wait_for_sub2))begin

    let x <- adder.response.get();
    p_val <= x;
    wait_for_sub2 <= tagged Invalid;
  end


   i <= i - 1;
    
  if(i==0)begin
    state <= Done;
  end
  else begin
    state <= Shift;
  end
  endrule

  rule doComplete (state == Done);
  	//$display("%d * %d mod %d = %d", x_val, y_val, m_val, p_val);
    doneFIFO.enq(0);
    state <= Idle;
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