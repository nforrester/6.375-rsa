import RSAPipelineTypes::*;
import ModMultIlvd::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import Vector::*;


interface ModExpt;
    method Action start();
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


typedef enum {Idle, PutMult1, PutMult2, GetMult} State deriving (Bits, Eq);


module mkModExpt#(Reg#(BIG_INT) b, Reg#(BIG_INT) e, Reg#(BIG_INT) m) (ModExpt);
  FIFO#(Bit#(1)) doneFIFO <- mkSizedFIFO(1);
  
	Reg#(BIG_INT) c <- mkRegU;

	ModMultIlvd modmult <- mkModMultIlvd();

  Reg#(State) state <- mkReg(Idle);

  rule doPutMult1 (state==PutMult1);
    if(e==0)begin
      doneFIFO.enq(0);
      $display("finished %X", c); 
      state <= Idle;
    end else begin
      if(e[0] == 1) begin
        Vector#(3, BIG_INT) packet_out =?;
        packet_out[0] = b;
        packet_out[1] = c;
        packet_out[2] = m;
        modmult.putData(packet_out);
      end
      state <= PutMult2;
    end
  endrule
  
  rule doPutMult2 (state==PutMult2);
    if(e[0] == 1) begin
      let x <- modmult.getResult();
      c <= x;
    end
    Vector#(3, BIG_INT) packet_out=?;
    packet_out[0] = b;
    packet_out[1] = b;
    packet_out[2] = m;
    modmult.putData(packet_out);

    state <= GetMult;

  endrule

  rule doGetMult (state == GetMult);
    let x <- modmult.getResult();
    b <= x;
    
    e <= e >> 1;
    state <= PutMult1;
  endrule

 
    method Action start();
		    c <= 1;
		    state <= PutMult1;
    endmethod

    method ActionValue#(BIG_INT) getResult();
        doneFIFO.deq();
        return c;
    endmethod
endmodule

module mkModExptTest (Empty);

		Reg#(BIG_INT) b <- mkReg(2328323);
		Reg#(BIG_INT) e <- mkReg(12312);
		Reg#(BIG_INT) m <- mkReg(13371337);

    ModExpt modexpt <- mkModExpt(b, e, m);

    Reg#(Bit#(32)) feed <- mkReg(0);
    
    rule store(feed == 0);
    feed <= 1;
    
      modexpt.start;
    endrule

    rule load(feed == 1);
      let result = ?;		
      result <-	modexpt.getResult();
      $display("Result: %d", result);
      $display("Golden 2376662");
      $finish();

      feed <= 0;
    endrule
endmodule