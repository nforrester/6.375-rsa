import ModExpt::*;
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



(* synthesize *)
module mkRSAModExpt(ModExpt);
  ModExpt modexpt <- mkModExpt();
  return modexpt;
endmodule

typedef enum{PutB, PutE, PutM, Done} PutVar deriving (Bits,Eq);
  typedef enum{GetB, GetE, GetM, Done} GetVar deriving (Bits,Eq);



module mkRSAPipeline(RSAPipeline);
 
  ModMultIlvd modmult <- mkRSAModMultIlvd();
  ModExpt modexpt <- mkRSAModExpt();
  Memory memory <- mkMemory();
  Reg#(Addr) state <- mkReg(0);
  Reg#(Bool) hack <- mkReg(False);
  Reg#(PutVar) put_var <- mkReg(PutB);
  Reg#(GetVar) get_var <- mkReg(GetB);

  Vector#(3, Reg#(BIG_INT)) inputs <- replicateM(mkRegU());

  rule init(memory.init.done() && !hack);
      hack <= True;
      state <= 0;
      put_var <= PutB;
      get_var <= GetB;
      // test 3*5 mod 20 = 15
    /*  Vector#(3,BIG_INT) in = ?;
      in[0] = 5;
      in[1] = 3;
      in[2] = 8;

      $display("sending test case in");
      modexpt.request.put(in);
      //modmult.request.put(in);
      */
  endrule

  rule doPutB(put_var == PutB && hack);
      let x = MemReq{op:False, addr:0, data:0};
      memory.request.put(x);
      put_var <= PutE;
  endrule
   rule doPutE(put_var == PutE && hack);
      let x = MemReq{op:False, addr:1, data:0};
      memory.request.put(x);
      put_var <= PutM;
  endrule
    rule doPutM(put_var == PutM && hack);
      let x = MemReq{op:False, addr:2, data:0};
      memory.request.put(x);
      put_var <= Done;
      $display("memory read requests complete");
  endrule
  
  rule doGetB(get_var == GetB);
      let x <- memory.response.get();
      inputs[0] <= x;
      get_var <= GetE;
  endrule

  rule doGetE(get_var == GetE);
      let x <- memory.response.get();
      inputs[1] <= x;
      get_var <= GetM;
  endrule
  rule doGetM(get_var == GetM);
      let x <- memory.response.get();
      inputs[2] <= x;
      get_var <= Done;
  endrule

  rule doRSA(get_var==Done && put_var==Done);
      $display("Computing %d ^ %d mod %d",inputs[0], inputs[1], inputs[2]);
      Vector#(3, BIG_INT) in = readVReg(inputs);
      modexpt.request.put(in);
  endrule


 /* rule doSomething(memory.init.done() && hack && state < 1 );
      $display("recieved response");
      let y <- modexpt.response.get();
      //let y <- modmult.response.get();
      $display(y);
    
     // let x = MemReq{op:False, addr:state, data:0};
      //memory.request.put(x);
     // $fwrite(stdout, "%d\n",state);
    //  $display("done");
      $finish();
      state <= state +1;
  endrule
*/
   
  interface Get get_result;
    method ActionValue#(BIG_INT) get();
      let x <- modexpt.response.get();
      $display("Result = %d",x);
      return x;
    endmethod
  endinterface

  interface MemInit memInit = memory.init;
endmodule

