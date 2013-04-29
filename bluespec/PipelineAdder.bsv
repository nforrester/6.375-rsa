import RSAPipelineTypes::*;

import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;


typedef Server#(
  Vector#(2, BIG_INT),  // changed this to hardcoded 3 since the algo is hardcoded
  BIG_INT
) Adder;


/* Performs 
   
   result = a + b


	 Interface:
	 Input FIFO is 1-deep


   Input Put: 
   2 x BIG_INT

	 Output Get:
	1 x BIG_INT, overflow not guaranteed

	Will take an undefined number of cycles
*/


typedef enum {Add, Done} State deriving (Bits, Eq);


module mkPipelineAdder(Adder);

	// Concatenates chunks into one big BIG_INT
	function BIG_INT toBigInt(Vector#(ADD_STAGES, Reg#(Bit#(ADD_WIDTH))) data);
		BIG_INT result = 0;
		
		for(Integer i = 0; i < valueOf(BI_SIZE); i = i + 1) begin
			Integer chunk_id = (i * valueOf(ADD_STAGES)) / valueOf(BI_SIZE);
			let chunk = data[chunk_id];
			result[i] = chunk[i - (chunk_id * valueOf(ADD_WIDTH))];
		end
		
		return result;
	
	endfunction

  FIFOF#(Vector#(2, BIG_INT)) inputFIFO <- mkFIFOF();
  FIFO#(BIG_INT) outputFIFO <- mkFIFO();
  
  Reg#(State) state <- mkReg(Add);
	Reg#(Int#(32)) hack <- mkReg(1337);
	Reg#(Int#(TAdd#(TLog#(ADD_STAGES), 1))) add_stage <- mkReg(0);
	Reg#(Bit#(TAdd#(ADD_WIDTH, 1))) cs <- mkReg(0);
	Vector#(ADD_STAGES, Reg#(Bit#(ADD_WIDTH))) result <- replicateM(mkReg(0));

  rule reset(hack != 1337);
    hack <= 1337;
    state <= Add;
    cs <= 0;
		for(Integer j = 0; j < valueOf(ADD_STAGES); j = j + 1) begin
			result[j] <= 0;
		end
    add_stage <= 0;
  endrule
  

	rule calculate(state == Add);
    let a = inputFIFO.first()[0];
  	let b = inputFIFO.first()[1];
  	
		Int#(TAdd#(TLog#(ADD_STAGES), 1)) add_width = fromInteger(valueOf(ADD_WIDTH));
		
		// Select the relevant chunk of the input data
		Bit#(TAdd#(ADD_WIDTH, 1)) a_chunk = a[add_stage * add_width + (add_width-1):add_stage * add_width];
		Bit#(TAdd#(ADD_WIDTH, 1)) b_chunk = b[add_stage * add_width + (add_width-1):add_stage * add_width];
				
		// Perform an addition, carrying in the carry bit from last cycle
	 	let cs_in = a_chunk + b_chunk  + zeroExtend(cs[add_width]);
		cs <= cs_in;
		
		// Store the result in the output buffer
		result[add_stage] <= truncate(cs_in); 

		add_stage <= add_stage + 1;
		
		//$display("Adding stage %d, %d + %d = %d" , add_stage, a_chunk, b_chunk, cs_in);
		
		if(add_stage == fromInteger(valueOf(ADD_STAGES) - 2)) begin
			state <= Done;
		end
		
	endrule

	rule done(state == Done);	
	
	
		outputFIFO.enq(toBigInt(result));
		inputFIFO.deq();
		add_stage <= 0;
		state <= Add;
	
	
	endrule
	
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule


module mkAddTest (Empty);
  // some unit test
endmodule

