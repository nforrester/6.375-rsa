
import ClientServer::*;
import FIFO::*;
import GetPut::*;
import DefaultValue::*;
import SceMi::*;
import Clocks::*;

import Calculator::*;

(* synthesize *)
module [Module] mkDutWrapper (Calculator);
    Calculator calc <- mkCalculator();
    return calc;
endmodule

module [SceMiModule] mkSceMiLayer();

    SceMiClockConfiguration conf = defaultValue;

    SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);
    Calculator dut <- buildDut(mkDutWrapper, clk_port);

    Empty calcxactor <- mkServerXactor(dut, clk_port);

    Empty shutdown <- mkShutdownXactor();
endmodule

