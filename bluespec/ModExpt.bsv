import RSAPipelineTypes::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
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
  FIFO#(1, Vector#(3, BIG_INT)) inputFIFO <- mkFIFO();
  FIFO#(1, BIG_INT) outputFIFO <- mkFIFO();
  
  Reg#(BIG_INT) b <- mkReg(0);
	Reg#(BIG_INT) e <- mkReg(0);
	Reg#(BIG_INT) c <- mkReg(0);
	BIG_INT m;

	ModExpt modmult0 <- mkModMultIlvd();
	ModExpt modmult1 <- mkModMultIlvd();
	
	rule reset;
		if(inputFIFO.notEmpty) begin
			let packet_in <- inputFIFO.first();
		
			b <= packet[0];
			e <= packet[1];
			m = packet[2];
			// Cross your fingers that the compiler elaborates this into a constant
			c <= 0 - 1;
			
		end
	endrule
	
	rule shift;
		Vector#(3, BIG_INT) packet_out;
		
		packet_out[0] = b;
		packet_out[1] = b;
		packet_out[2] = m;
		modmult0.put(packet_out);
		
		b <= modmult1.get();
		
		packet_out[0] = b;
		packet_out[1] = c;
		packet_out[2] = m;
		modmult1.put(packet_out);
		
		if(e & 1) begin
			c <= modmult1.get();
		end
		
		e <= e >> 1;
		
		if(e == 0) begin
			inputFIFO.deq();
			outputFIFO.push(c);
		end
		
	endrule

	rule 

  interface Put request = toPut(infifo);
  interface Get response = toGet(outfifo);
endmodule

module mkModExptTest (Empty);
  // some unit test
endmodule

