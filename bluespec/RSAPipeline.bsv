import ModExpt::*;
import ModMultIlvd::*;
import RSAPipelineTypes::*;
import Memory::*;
import ClientServer::*;
import FIFO::*;
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
//  Reg#(Addr) state <- mkReg(0);
  Reg#(Bool) hack <- mkReg(False);
  Reg#(PutVar) put_var <- mkReg(PutB);
  Reg#(GetVar) get_var <- mkReg(GetB);

  Vector#(3, Reg#(BIG_INT)) inputs <- replicateM(mkRegU());
  
  Reg#(Bool) doPut <- mkReg(True);
  Reg#(Addr) put_counter <- mkReg(0);
  Reg#(Addr) get_counter <- mkReg(0);
  Reg#(int)  ld_counter <- mkReg(0);
  Reg#(Bool) rsaRequested <- mkReg(False);
  
  FIFO#(BIG_INT) temp_input <- mkFIFO();

  rule init(memory.init.done() && !hack);
      hack <= True;
 //     state <= 0;
      put_var <= PutB;
      get_var <= GetB;
      put_counter <= 0;
      get_counter <= 0;
      doPut <=True;
      BIG_INT tmp = 0;
      temp_input.enq(tmp);
      ld_counter <= 0;
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


// request memory from address 0 - 95
  rule doPutMemoryRequests(hack && doPut);
      
      let x = MemReq{op:False, addr:put_counter, data:0};
      memory.request.put(x);
      put_counter <= put_counter + 1;
      if(put_counter == fromInteger(valueof(RES_0)- 1) )begin
        doPut <= False;
      //  $display("completed loading memory requests");
      end
  endrule

  rule doGet(ld_counter < 3);
 // $display("getting memory %d ", get_counter);
      let x <- memory.response.get();
      let idx = fromInteger(valueof(NUM_BITS_IN_CHUNK))*get_counter;
      BIG_INT tmp = temp_input.first();

      temp_input.deq();

      for(Integer i = 0; i < valueof(NUM_BITS_IN_CHUNK); i = i +1) begin
        tmp[idx + fromInteger(i)] = x[i]; 
      end
      
      if(get_counter==fromInteger(valueof(NUM_BITS_IN_CHUNK)-1))begin
      //  $display("loaded input %d", ld_counter);
        inputs[ld_counter] <= tmp;
        ld_counter <= ld_counter +1;
        tmp = 0;
      end
      else begin
        get_counter <= get_counter +1;
      end
      temp_input.enq(tmp);
  endrule






/*  rule doPutB(put_var == PutB && hack);
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
      inputs[0] <= zeroExtend(x);
      get_var <= GetE;
  endrule

  rule doGetE(get_var == GetE);
      let x <- memory.response.get();
      inputs[1] <= zeroExtend(x);
      get_var <= GetM;
  endrule
  rule doGetM(get_var == GetM);
      let x <- memory.response.get();
      inputs[2] <= zeroExtend(x);
      get_var <= Done;
  endrule
*/
  rule doRSA(get_var==Done && put_var==Done || ld_counter==3 && !rsaRequested);
      $display("Computing %d ^ %d mod %d",inputs[0], inputs[1], inputs[2]);
      Vector#(3, BIG_INT) in = readVReg(inputs);
      modexpt.request.put(in);
      rsaRequested <= True;
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

