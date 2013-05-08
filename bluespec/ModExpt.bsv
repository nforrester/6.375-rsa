import RSAPipelineTypes::*;
import ModMultIlvd::*;


import ClientServer::*;
import GetPut::*;
import FIFO::*;
import BRAMFIFO::*;
import Vector::*;
import Clocks::*;


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


module mkWrappedModExpt(Clocks::ClockDividerIfc clk, Reset rst, ModExpt ifc);
  SyncFIFOIfc#(Vector#(3, BIG_INT)) inputFIFO <- mkSyncFIFOToSlow(2, clk, rst);
  SyncFIFOIfc#(BIG_INT) outputFIFO <- mkSyncFIFOToFast(2, clk, rst);

  Reg#(BIG_INT) b <- mkRegU;
	Reg#(BIG_INT) e <- mkRegU;
	Reg#(BIG_INT) c <- mkRegU;
	Reg#(BIG_INT) m <- mkRegU;

	ModMultIlvd modmult <- mkModMultIlvd();

  Reg#(State) state <- mkReg(Start);

  rule start (state == Start);
    let data = inputFIFO.first();
    inputFIFO.deq();
	  b <= data[0];
	  e <= data[1];
	  m <= data[2];
	  c <= 1;
	  state <= PutMult1;
  endrule

  rule doPutMult1 (state==PutMult1);
    if(e==0)begin
      outputFIFO.enq(c);
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
      inputFIFO.enq(data);
    endmethod

    method ActionValue#(BIG_INT) getResult();
      outputFIFO.deq();
      return outputFIFO.first();
    endmethod
endmodule

module mkModExpt(ModExpt);
  let clockDiv <- mkClockDivider(10);
  let clk = clockDiv.slowClock;
  let currentReset <- exposeCurrentReset;
  let rst <- mkAsyncReset(1, currentReset, clk);
  let modExpt <- mkWrappedModExpt(clockDiv, rst, clocked_by clk, reset_by rst);

  method Action putData(Vector#(3, BIG_INT) data);
    modExpt.putData(data);
  endmethod

  method ActionValue#(BIG_INT) getResult();
    let r <- modExpt.getResult();
    return r;
  endmethod
endmodule
