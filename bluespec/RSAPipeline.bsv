//import ModExpt::*;
//import ModMultIlvd::*;
import RSAPipelineTypes::*;
import Memory::*;
import ClientServer::*;
import GetPut::*;
import Vector::*;
/*

(* synthesize *)
module mkRSAModMultIlvd(ModMultIlvd);
  ModMultIlvd modmult <- mkModMultIlvd();
  return modmult;
endmodule


(* synthesize *)
module mkRSAModExpt(ModExpt);
  ModExpt modexpt <- mkModExpt();
  return modexpt;
endmodule


*/
module mkRSAPipeline(RSAPipeline);
//  ModMultIlvd modmult <- mkRSAModMultIlvd();
//  ModExpt modexpt <- mkRSAModExpt();
  Memory memory <- mkMemory();
  Reg#(Bit#(16)) state <- mkReg(0);

  rule doSomething ( state < 1024);
    let x = MemReq{op:False, addr:0, data:0};
    memory.request.put(x);
    state <= state +1;
    $display("state is %d", state);
  endrule
  interface Get get_result;
    method ActionValue#(CHUNK_T) get();
      let x <- memory.response.get();
      return x;
    endmethod
  endinterface

  interface MemInit memInit = memory.init;
endmodule

