import RSAPipelineTypes::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import Clocks::*;

typedef struct {
  BIG_INT a;
  BIG_INT b;
  Bool do_sub;
} AdderOperands deriving (Bits, Eq);

typedef Server#(
  AdderOperands,
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

*/


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

module mkSlowClkAdder(Adder);
  let clockDiv2 <- mkClockDivider(2);
  let clk2nd = clockDiv2.slowClock;
  let currentReset <- exposeCurrentReset;
  let reset2nd <- mkAsyncReset(1, currentReset, clk2nd);
  //let reset2nd <- mkAsyncResetFromCC(0, clk2nd);
  let adder <- mkSimpleAdder(clocked_by clk2nd, reset_by reset2nd);

  SyncFIFOIfc#(AdderOperands) inputFIFO <- mkSyncFIFOToSlow(2, clockDiv2, reset2nd);
  SyncFIFOIfc#(BIG_INT) outputFIFO <- mkSyncFIFOToFast(2, clockDiv2, reset2nd);

  rule in;
    adder.request.put(inputFIFO.first());
    inputFIFO.deq();
  endrule

  rule out;
    let x <- adder.response.get();
    outputFIFO.enq(x);
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
