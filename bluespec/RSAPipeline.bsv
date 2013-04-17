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
  Reg#(Int#(8)) state <- mkReg(0);

  rule doSomething(memory.init.done());
      let x = MemReq{op:False, addr:1, data:0};
      memory.request.put(x);
      let y = 0;
      $fwrite(stdout, "%d ... y = %d",state, y);
      $display("done");
  endrule

  interface Get get_result;
    method ActionValue#(CHUNK_T) get();
      let x <- memory.response.get();
      return x;
    endmethod
  endinterface

  interface MemInit memInit = memory.init;
endmodule

