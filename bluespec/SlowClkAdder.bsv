import RSAPipelineTypes::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import Clocks::*;
/*
typedef struct {
  BIG_INT a;
  BIG_INT b;
  Bool do_sub;
} AdderOperands deriving (Bits, Eq);

typedef Server#(
  AdderOperands,
  BIG_INT
) Adder;
*/
/* Performs 
   
   result = a + b


	 Interface:
	 Input FIFO is 1-deep


   Input Put: 
   2 x BIG_INT

	 Output Get:
	1 x BIG_INT, overflow not guaranteed

*/


module mkWrappedAdder(Clocks::ClockDividerIfc clk, Reset rst, Adder ifc);
  SyncFIFOIfc#(AdderOperands) inputFIFO <- mkSyncFIFOToSlow(2, clk, rst);
  SyncFIFOIfc#(BIG_INT) outputFIFO <- mkSyncFIFOToFast(2, clk, rst);

  rule doAddORSub;
    let in = inputFIFO.first();
    inputFIFO.deq();
    let res = in.a + in.b + zeroExtend(in.c_in);

    /*if(in.do_sub)begin
      res = in.a - in.b;
    end else begin
      res = in.a + in.b;
    end*/
    outputFIFO.enq(res);
  endrule

  interface Put request;
    method Action put(AdderOperands x);
      inputFIFO.enq(x);
    endmethod
  endinterface

  interface Get response;
    method ActionValue#(BIG_INT) get();
      outputFIFO.deq();
      return outputFIFO.first();
    endmethod
  endinterface
endmodule

module mkSlowClkAdder(Adder);
  let clockDiv2 <- mkClockDivider(2);
  let clk2nd = clockDiv2.slowClock;
  let currentReset <- exposeCurrentReset;
  let reset2nd <- mkAsyncReset(1, currentReset, clk2nd);
  let adder <- mkWrappedAdder(clockDiv2, reset2nd, clocked_by clk2nd, reset_by reset2nd);

  interface Put request = adder.request;
  interface Get response = adder.response;
endmodule
