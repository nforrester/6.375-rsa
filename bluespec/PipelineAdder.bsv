import RSAPipelineTypes::*;

import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import Vector::*;
import Randomizable::*;

typedef Server#(
  AdderOperands,
  BIG_INT
) Adder;


/* Performs 
   
   result = a + b


	 Interface:
	 Input FIFO is 1-deep


   Input Put: 
   3 x BIG_INT

	 Output Get:
	1 x BIG_INT, overflow not guaranteed

	Will take an undefined number of cycles
*/


typedef enum {Add, Done} State deriving (Bits, Eq);


module mkSimpleAdder(Adder);
	FIFOF#(AdderOperands) inputFIFO <- mkFIFOF();
  FIFO#(BIG_INT) outputFIFO <- mkFIFO();


  rule doAddORSub;
    let in = inputFIFO.first();
    inputFIFO.deq();
    let res = ?;


    if(in.do_sub)begin
      res = in.a - in.b;
    end else begin
      res = in.a + in.b;
    end
    outputFIFO.enq(res);
  endrule


  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);

endmodule


module mkPipelineAdder(Adder);

	// Concatenates chunks into one BIG_INT
	function BIG_INT toBigInt(Vector#(ADD_STAGES, Reg#(Bit#(ADD_WIDTH))) data);
		BIG_INT result = 0;
		
		for(Integer i = 0; i < valueOf(BI_SIZE); i = i + 1) begin
			Integer chunk_id = (i * valueOf(ADD_STAGES)) / valueOf(BI_SIZE);
			let chunk = data[chunk_id];
			result[i] = chunk[i - (chunk_id * valueOf(ADD_WIDTH))];
		end
		
		return result;
	
	endfunction

  FIFOF#(AdderOperands) inputFIFO <- mkSizedBRAMFIFOF(1);
  FIFO#(BIG_INT) outputFIFO <- mkSizedBRAMFIFO(1);
  
  Reg#(State) state <- mkReg(Add);
	Reg#(Int#(TAdd#(TLog#(ADD_STAGES), 1))) add_stage <- mkReg(0);
	Reg#(Bit#(TAdd#(ADD_WIDTH, 1))) cs <- mkReg(0);
	Reg#(Int#(TAdd#(TLog#(BI_SIZE), 1))) idx_lo <- mkReg(0);
	Reg#(Int#(TAdd#(TLog#(BI_SIZE), 1))) idx_hi <- mkReg(fromInteger(valueOf(ADD_WIDTH)) - 1);	
	Vector#(ADD_STAGES, Reg#(Bit#(ADD_WIDTH))) result <- replicateM(mkReg(0));

	rule calculate(state == Add);
    let a = inputFIFO.first().a;
  	let b = inputFIFO.first().b;
  	let sub = inputFIFO.first().do_sub; // This is okay: BSV will clip extra bits
 		
 		// If we're subtracting, flip the negative value and add 1
  	let c_in = (sub && add_stage == 0) ? 1 : 0;
  	b = sub ? ~b : b;

		// Need this width for the bit select multiplier
		Int#(TAdd#(TLog#(BI_SIZE), 1)) add_width = fromInteger(valueOf(ADD_WIDTH));
		
		// Select the relevant chunk of the input data
   	//$display("Selecting [%d:%d]", idx_hi, idx_lo);
		Bit#(TAdd#(ADD_WIDTH, 1)) a_chunk = a[idx_hi : idx_lo];
		Bit#(TAdd#(ADD_WIDTH, 1)) b_chunk = b[idx_hi : idx_lo];
		idx_lo <= idx_lo + add_width;
		idx_hi <= idx_hi + add_width;
				
		// Perform an addition, carrying in the carry bit from last cycle, and the external carry in
	 	let cs_in = a_chunk + b_chunk  + zeroExtend(cs[add_width]) + c_in;
		cs <= cs_in;
		
		// Store the result in the output buffer
		result[add_stage] <= truncate(cs_in); 

		add_stage <= add_stage + 1;
		
		//$display("Adding stage %d, %b + %b = %b" , add_stage, a_chunk, b_chunk, cs_in);
		
		if(add_stage == fromInteger(valueOf(ADD_STAGES) - 1)) begin
			state <= Done;
		end
		
	endrule

	rule done(state == Done);	
	
		outputFIFO.enq(toBigInt(result));
		inputFIFO.deq();
		add_stage <= 0;
		cs <= 0;
		idx_lo <= 0;
		idx_hi <= fromInteger(valueOf(ADD_WIDTH)) - 1;
		state <= Add;
	
	
	endrule
	
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule


module mkAddTest (Empty);

    Adder adder <- mkPipelineAdder();
		Randomize#(Bit#(BI_SIZE)) test_gen1 <- mkGenericRandomizer;
		Randomize#(Bit#(BI_SIZE)) test_gen2 <- mkGenericRandomizer;

    Reg#(Bit#(32)) feed <- mkReg(0);
    Reg#(BIG_INT) sim_result <- mkReg(0);

		rule init(feed == 0);
			test_gen1.cntrl.init();
			test_gen2.cntrl.init();
			feed <= 1;
		endrule

    rule store(feed == 1);
      feed <= 2;
      let a <- test_gen1.next();
      let b <- test_gen2.next();
      
      // No overflow support
      a[valueOf(BI_SIZE)-1] = 0;
      b[valueOf(BI_SIZE)-1] = 0;
      
      if(a > b) begin 
      	sim_result <= a - b;
      	adder.request.put(AdderOperands{a:a, b:b, do_sub:True});
    	end else begin
    		sim_result <= b - a;
      	adder.request.put(AdderOperands{a:b, b:a, do_sub:True});
    	end
      //$display("%b\n+\n%b", operands[0], operands[1]);
    endrule

    rule load(feed == 2);
      let result = ?;		
      result <-	adder.response.get();
      $display("Result: %d", result);
      if(result != sim_result) begin
        $display("Result:\n%b", result);
        $display("Golden:\n%b", sim_result);
        $display("FAIL");
        $finish();
      end
      feed <= 1;
    endrule
endmodule
