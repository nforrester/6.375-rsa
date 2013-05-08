import RSAPipelineTypes::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;

typedef 4 ADDER_SIZE;

/*typedef struct {
  BIG_INT a;
  BIG_INT b;
  Bool do_sub;
} AdderOperands deriving (Bits, Eq);

typedef Server#(
  AdderOperands,
  BIG_INT
) Adder;
*/

typedef struct {
  Bit#(adder_size) a;
  Bit#(adder_size) b;
  Bit#(1) c_in;
} AdderIn#(numeric type adder_size) deriving (Bits, Eq);

typedef struct {
  Bit#(adder_size) s;
  Bit#(1) c_out;
} AdderOut#(numeric type adder_size) deriving (Bits,Eq);

typedef Server#(
  AdderIn#(adder_size),
  AdderOut#(adder_size)) AdderUnit#(numeric type adder_size);


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

  rule doAdd;
    let in = inputFIFO.first();
    inputFIFO.deq();
    let res = in.a + in.b + zeroExtend(in.c_in);
    outputFIFO.enq(res);
  endrule

  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);

endmodule


module mkAdderUnit(AdderUnit#(adder_size));

  FIFO#(AdderIn#(adder_size)) inputFIFO <- mkFIFO();
  FIFO#(AdderOut#(adder_size)) outputFIFO <- mkFIFO();
  
  function Bit#(adder_size) prop(Bit#(adder_size) a, Bit#(adder_size) b);
    return a | b;
  endfunction
  
  function Bit#(adder_size) gen(Bit#(adder_size) a, Bit#(adder_size) b);
    return a & b;
  endfunction
  
  function Bit#(1) sum(Bit#(1) a, Bit#(1) b, Bit#(1) c);
    return a ^ b ^ c;
  endfunction
  
  
  rule doAdd;
    let in = inputFIFO.first(); inputFIFO.deq();
    let g = gen(in.a, in.b);
    let p = prop(in.a, in.b);
    Bit#(adder_size) s = ?;

    Bit#(1) c = in.c_in;
    for(Integer i = 0; i < valueof(adder_size); i = i +1)begin
      s[i] = sum(in.a[i], in.b[i], c);
      c = g[i] | (p[i] & c);
   //   $display("dummy check i =? %d", i);
    end

    let out = AdderOut{s:s, c_out:c};
    outputFIFO.enq(out);
  endrule


  interface Put request = toPut(inputFIFO);
  interface Get response = toGet(outputFIFO);


endmodule

module mkCLAdder(Adder);

  AdderUnit#(BI_SIZE) adder  <- mkAdderUnit();
  
  interface Put request;
    method Action put(AdderOperands x);
        adder.request.put(AdderIn{a:x.a, b:x.b, c_in:x.c_in});
    endmethod
  endinterface

  interface Get response;
    method ActionValue#(BIG_INT) get();
      let x <- adder.response.get();
      return x.s;
    endmethod
  endinterface

endmodule


module mkCLAdderTest (Empty);
  Adder main_adder <-mkCLAdder();
  AdderUnit#(ADDER_SIZE) test  <- mkAdderUnit();
  Reg#(Bit#(32)) feed <- mkReg(0);
  Reg#(Bit#(32)) check <- mkReg(0);
  Reg#(Bool) passed <- mkReg(True);
 
  function Action dofeed(AdderIn#(ADDER_SIZE) x);
    action
      test.request.put(x);
      feed <= feed+1;
    endaction
  endfunction

  function Action doCheck(AdderOut#(ADDER_SIZE) correct);
    action 
      let x <- test.response.get();
      if(x.s != correct.s || x.c_out != correct.c_out)begin
        $display("wanted s = %x, c=%x", correct.s, correct.c_out);
        $display("got s = %x, c=%x", x.s, x.c_out);
        passed <=False;
      end
      check <= check+1;
    endaction
  endfunction

  rule f0 (feed==0); dofeed(AdderIn{a:0,b:0,c_in:0});endrule
  rule f1 (feed==1); dofeed(AdderIn{a:0,b:1,c_in:0});endrule
  rule f2 (feed==2); dofeed(AdderIn{a:1,b:1,c_in:0});endrule
  rule f3 (feed==3); dofeed(AdderIn{a:15,b:1,c_in:0});endrule
  rule f4 (feed==4); dofeed(AdderIn{a:15,b:1,c_in:1});endrule

  rule c0 (check == 0); doCheck(AdderOut{s:0,c_out:0});endrule
  rule c1 (check == 1); doCheck(AdderOut{s:1,c_out:0});endrule
  rule c2 (check == 2); doCheck(AdderOut{s:2,c_out:0});endrule
  rule c3 (check == 3); doCheck(AdderOut{s:0,c_out:1});endrule
  rule c4 (check == 4); doCheck(AdderOut{s:1,c_out:1});endrule

  rule finish (feed==5 && check==5);
    if(passed)
      $display("PASSED");
    else
      $display("FAILLLEEEEEED");
    $finish();
  endrule

endmodule
