//import ModExpt::*;
//import ModMultIlvd::*;
import RSAPipelineTypes::*;
import Memory::*;
import ClientServer::*;
import GetPut::*;
import Vector::*;


/*(* synthesize *)
module mkRSAModMultIlvd(ModMultIlvd);
  ModMultIlvd modmult <- mkModMultIlvd();
  return modmult;
endmodule
*/
/*

(* synthesize *)
module mkRSAModExpt(ModExpt);
  ModExpt modexpt <- mkModExpt();
  return modexpt;
endmodule


*/
module mkRSAPipeline(RSAPipeline);
//ModMultIlvd modmult <- mkRSAModMultIlvd();
//  ModExpt modexpt <- mkRSAModExpt();
  Memory memory <- mkMemory();
  Reg#(int) state <- mkReg(4);

  rule doSomething(memory.init.done() && state >= 0);
      let x = MemReq{op:False, addr:0, data:0};
      memory.request.put(x);
      $fwrite(stdout, "%d\n",state);
      $display("done");
      state <= state -1;
  endrule

  interface Get get_result;
    method ActionValue#(CHUNK_T) get();
      let x <- memory.response.get();
      return x;
    endmethod
  endinterface

  interface MemInit memInit = memory.init;
endmodule

