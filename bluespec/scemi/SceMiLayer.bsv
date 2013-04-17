import ClientServer::*;
import FIFO::*;
import GetPut::*;
import DefaultValue::*;
import SceMi::*;
import Clocks::*;

import RSA::*;
import RSAPipelineTypes::*;

(* synthesize *)
module [Module] mkDutWrapper (RSA);
    RSAServer rsa <- mkRSA();
    return calc;
endmodule

module [SceMiModule] mkSceMiLayer();

    SceMiClockConfiguration conf = defaultValue;

    SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);
    RSAServer dut <- buildDut(mkDutWrapper, clk_port);

    Empty rsaxactor <- mkServerXactor(dut, clk_port);

    Empty shutdown <- mkShutdownXactor();
endmodule

