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


typedef enum {PutMult, GetMult, Done} State deriving (Bits, Eq);


module mkModExpt(ModExpt);
  FIFOF#(Vector#(3, BIG_INT)) inputFIFO <- mkFIFOF();
  FIFO#(BIG_INT) outputFIFO <- mkFIFO();
  
  Reg#(BIG_INT) b <- mkReg(0);
	Reg#(BIG_INT) e <- mkReg(0);
	Reg#(BIG_INT) c <- mkReg(0);
	Reg#(BIG_INT) m <- mkReg(0);


	ModExpt modmult0 <- mkModMultIlvd();
	ModExpt modmult1 <- mkModMultIlvd();


  Reg#(State) state <- mkReg(Done);
	Reg#(Bool) hack <-mkReg(False);

  rule init(!hack);
    hack <= True;
    b <= 0;
    e <= 0;
    c <= 0;
    m <= 0;
    state <= Done;
  endrule

	rule start(hack&& state == Done);
   // $display("modExpt \t\t Start");
    let packet_in = inputFIFO.first();
    inputFIFO.deq();
  
    b <= packet_in[0];
    e <= packet_in[1];
    m <= packet_in[2];
    c <= 1;


    state <= PutMult;
	endrule


	rule putMult(state == PutMult);
 //   $display("modExpt \t\t PutMult");
    Vector#(3, BIG_INT) packet_out = ?;
		if(e == 0) begin
			outputFIFO.enq(c);
      state <= Done;
		end else begin
      if((e & fromInteger(1)) == fromInteger(1)) begin
        packet_out[0] = b;
        packet_out[1] = c;
        packet_out[2] = m;
        modmult1.request.put(packet_out);
      end
      packet_out[0] = b;
      packet_out[1] = b;
      packet_out[2] = m;
      modmult0.request.put(packet_out);


      state <= GetMult;
    end
	endrule


	rule getMult(state == GetMult);
		let next_c = ?;
    let next_b = ?;
    let next_e = ?;


    if((e & fromInteger(1)) == fromInteger(1)) begin
			BIG_INT r1 <- modmult1.response.get();
      next_c = r1;
			c <= r1;
		end
    else next_c = c;


		BIG_INT r0 <- modmult0.response.get();
		b <= r0;
    next_b = r0;


		e <= e >>1;
    next_e = e >> 1;


    
 //   $display("modExpt \t\t GetMult\t\tb=%d\tc=%d\te=%d",next_b,next_c,next_e);
    state <= PutMult;
	endrule


  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule


module mkModExptTest (Empty);
  // some unit test
endmodule

