import RSAPipelineTypes::*;
import ModMultIlvd::*;

import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;

typedef Server#(
  Vector#(3, BIG_INT),  // changed this to hardcoded 3 since the algo is hardcoded
  BIG_INT
) ModExpt;

/* Performs 
   
   result = b ^ e % m

	 Interface:
	 Input FIFO is 1-deep

   Input Put: 
		
		b = packet[0];
		e = packet[1];
		m = packet[2];
		
	 Output Get:
	 
	 BIG_INT
*/
module mkModExpt(ModExpt);
  FIFOF#(Vector#(3, BIG_INT)) inputFIFO <- mkFIFOF();
  FIFO#(BIG_INT) outputFIFO <- mkFIFO();
  
  Reg#(BIG_INT) b <- mkReg(0);
	Reg#(BIG_INT) e <- mkReg(0);
	Reg#(BIG_INT) c <- mkReg(0);
	Reg#(BIG_INT) m <- mkReg(0);

	ModExpt modmult0 <- mkModMultIlvd();
	ModExpt modmult1 <- mkModMultIlvd();
	
	rule reset;
		if(inputFIFO.notEmpty) begin
			let packet_in = inputFIFO.first();
		
			b <= packet_in[0];
			e <= packet_in[1];
			m <= packet_in[2];
			// Cross your fingers that the compiler elaborates this into a constant
			c <= 0 - 1;
			
		end
	endrule
	
	rule shift;
		Vector#(3, BIG_INT) packet_out;
		
		packet_out[0] = b;
		packet_out[1] = b;
		packet_out[2] = m;
		modmult0.request.put(packet_out);
		
		BIG_INT r0 <- modmult0.response.get();
		b <= r0;
		
		packet_out[0] = b;
		packet_out[1] = c;
		packet_out[2] = m;
		modmult1.request.put(packet_out);
		
		if((e & fromInteger(1)) == fromInteger(1)) begin
			BIG_INT r1 <- modmult1.response.get();
			c <= r1;
		end
		
		e <= e >> 1;
		
		if(e == 0) begin
			inputFIFO.deq();
			outputFIFO.enq(c);
		end
		
	endrule

  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule

module mkModExptTest (Empty);
  // some unit test
endmodule

