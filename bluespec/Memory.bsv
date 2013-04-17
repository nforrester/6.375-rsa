import RSAPipelineTypes::*;
import BRAM::*;
import GetPut::*;

interface Memory;
  interface Put#(MemReq) request;
  interface Get#(CHUNK_T) response;
  interface MemInitIfc init;
endinterface


function BRAMRequest#(Addr,CHUNK_T) makeRequest(Bool write, Addr addr, CHUNK_T data);
  return  BRAMRequest{
                        write: write,
                        responseOnWrite:False,
                        address:truncate(addr),
                        datain:data
                      };
endfunction

module mkMemInitBRAM(BRAM1Port#(Addr, CHUNK_T) mem, MemInitIfc ifc);
    Reg#(Bool) initialized <- mkReg(False);

    interface Put request;
        method Action put(MemInit x) if (!initialized);
          case (x) matches
            tagged InitLoad .l: begin
                mem.portA.request.put(BRAMRequest {
                    write: True,
                    responseOnWrite: False,
                    address: truncate(l.addr),
                    datain: l.data});
            end
    
            tagged InitDone: begin
                initialized <= True;
            end
          endcase
        endmethod
    endinterface
    
    method Bool done() = initialized;

endmodule

(* synthesize *)
module mkMemory(Memory);
  BRAM_Configure cfg = defaultValue;
  BRAM1Port#(Addr, CHUNK_T) bram <- mkBRAM1Server(cfg);
  MemInitIfc memInit <- mkMemInitBRAM(bram);

  interface Put request;
    method Action put(MemReq x); 
      bram.portA.request.put(makeRequest(True, x.addr, x.data));
    endmethod
  endinterface

  interface Get response;
      method ActionValue#(CHUNK_T) get();
        let x <- bram.portA.response.get();
        return x;
      endmethod
  endinterface

  interface MemInitIfc init = memInit;
endmodule

