import ClientServer::*;
import FIFO::*;
import GetPut::*;
import DefaultValue::*;
import SceMi::*;
import Clocks::*;
import ResetXactor::*;

import RSA::*;
import RSAPipelineTypes::*;

(* synthesize *)

module [Module] mkDutWrapper (RSAServer);
    RSAServer rsa <- mkRSA();
    return rsa;
endmodule


module [SceMiModule] mkSceMiLayer();

    SceMiClockConfiguration conf = defaultValue;

    SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);
    RSAServer dut <- buildDutWithSoftReset(mkDutWrapper, clk_port);

    Empty rsaxactor <- mkServerXactor(dut, clk_port);
    
    Empty shutdown <- mkShutdownXactor();
endmodule

