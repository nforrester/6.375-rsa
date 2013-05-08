import RSAPipelineTypes::*;
import ModMultIlvd::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
import BRAMFIFO::*;
import Vector::*;


interface ModExpt;
    method Action putData(Vector#(3, BIG_INT) data);
    method ActionValue#(BIG_INT) getResult();
endinterface


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
  FIFO#(Bit#(1)) doneFIFO <- mkSizedFIFO(1);
  
  Reg#(BIG_INT) b <- mkRegU;
	Reg#(BIG_INT) e <- mkRegU;
	Reg#(BIG_INT) c <- mkRegU;
	Reg#(BIG_INT) m <- mkRegU;

	ModMultIlvd modmult <- mkModMultIlvd();

  Reg#(State) state <- mkReg(Start);

  rule doPutMult1 (state==PutMult1);
    if(e==0)begin
      doneFIFO.enq(0);
      state <= Start;
    end else begin
      if(e[0] == 1) begin
        Vector#(3, BIG_INT) packet_out =?;
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

 
    method Action putData(Vector#(3, BIG_INT) data);
		    b <= data[0];
		    e <= data[1];
		    m <= data[2];
		    c <= 1;
		    state <= PutMult1;
    endmethod

    method ActionValue#(BIG_INT) getResult();
        doneFIFO.deq();
        return c;
    endmethod
endmodule



