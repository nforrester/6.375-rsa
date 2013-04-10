import ModExpt::*;
import ModMultIlvd::*;
import RSAPipelineTypes::*;

import ClientServer::*;
import GetPut::*;
import Vector::*;


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



module mkRSAPipeline(RSAPipeline);
  ModMultIlvd modmult <- mkRSAModMultIlvd();
  ModExpt modexpt <- mkRSAModExpt();


endmodule
