//import ModExpt::*;
import ModMultIlvd::*;
import RSAPipelineTypes::*;
import Memory::*;
import ClientServer::*;
import GetPut::*;
import Vector::*;


(* synthesize *)
module mkRSAModMultIlvd(ModMultIlvd);
  ModMultIlvd modmult <- mkModMultIlvd();
  return modmult;
endmodule

/*

(* synthesize *)
module mkRSAModExpt(ModExpt);
  ModExpt modexpt <- mkModExpt();
  return modexpt;
endmodule


*/
module mkRSAPipeline(RSAPipeline);
 
  ModMultIlvd modmult <- mkRSAModMultIlvd();
//  ModExpt modexpt <- mkRSAModExpt();
  Memory memory <- mkMemory();
  Reg#(Addr) state <- mkReg(0);
  Reg#(Bool) hack <- mkReg(False);

  rule init(memory.init.done() && !hack);
      hack <= True;
      state <= 0;
      
      // test 3*5 mod 20 = 15
      BIG_INT x = 3;
      BIG_INT y = 5;
      BIG_INT m = 20;

      Vector#(3,BIG_INT) in = ?;
      in[0] = 5;
      in[1] = 3;
      in[2] = 20;
      $display("sending test case in");
      modmult.request.put(in);

  endrule
/*  rule getResponse;
      $display("recieved response");
      let x <- modmult.response.get();
      $display(x);
  endrule
  */    
  rule doSomething(memory.init.done() && hack && state < 1 );
      $display("recieved response");
      let y <- modmult.response.get();
      $display(y);
    
     // let x = MemReq{op:False, addr:state, data:0};
      //memory.request.put(x);
     // $fwrite(stdout, "%d\n",state);
    //  $display("done");
      $finish();
      state <= state +1;
  endrule

   
  interface Get get_result;
    method ActionValue#(CHUNK_T) get();
      let x <- memory.response.get();
      return x;
    endmethod
  endinterface

  interface MemInit memInit = memory.init;
endmodule

