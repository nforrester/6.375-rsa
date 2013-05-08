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


typedef enum {Start, PutMult1, PutMult2, GetMult} State deriving (Bits, Eq);


module mkModExpt(ModExpt);
  FIFOF#(Vector#(3, BIG_INT)) inputFIFO <- mkFIFOF(1);
  FIFO#(BIG_INT) outputFIFO <- mkFIFO(1);
  
  Reg#(BIG_INT) b <- mkRegU;
	Reg#(BIG_INT) e <- mkRegU;
	Reg#(BIG_INT) c <- mkRegU;
	Reg#(BIG_INT) m <- mkRegU;

	ModExpt modmult <- mkModMultIlvd();


  Reg#(State) state <- mkReg(Start);

	rule start(state == Start);
   // $display("modExpt \t\t Start");
    let packet_in = inputFIFO.first();
    inputFIFO.deq();
  
    b <= packet_in[0];
    e <= packet_in[1];
    m <= packet_in[2];
    c <= 1;

    state <= PutMult1;
	endrule

  rule doPutMult1 (state==PutMult1);
    if(e==0)begin
      outputFIFO.enq(c);
      state <= Start;
    end else begin
      if(e[0] == 1) begin
        Vector#(3, BIG_INT)packet_out =?;
        packet_out[0] = b;
        packet_out[1] = c;
        packet_out[2] = m;
        modmult.request.put(packet_out);
      end
      state <= PutMult2;
    end
  endrule
  
  rule doPutMult2 (state==PutMult2);
    if(e[0] == 1) begin
      let x <- modmult.response.get();
      c <= x;
    end
    Vector#(3, BIG_INT) packet_out=?;
    packet_out[0] = b;
    packet_out[1] = b;
    packet_out[2] = m;
    modmult.request.put(packet_out);

    state <= GetMult;

  endrule

  rule doGetMult (state == GetMult);
    let x <- modmult.response.get();
    b <= x;
    
    e <= e >> 1;
    state <= PutMult1;
  endrule

 
  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);
endmodule



