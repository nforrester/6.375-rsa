import ClientServer::*;
import FIFO::*;
import GetPut::*;
import DefaultValue::*;
import SceMi::*;
import Clocks::*;
import ResetXactor::*;

import RSAPipeline::*;
import RSAPipelineTypes::*;

(* synthesize *)

module [Module] mkDutWrapper (RSAPipeline);
    RSAPipeline rsa <- mkRSAPipeline();
    return rsa;
endmodule


module [SceMiModule] mkSceMiLayer();

    SceMiClockConfiguration conf = defaultValue;

    SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);
    RSAPipeline dut <- buildDutWithSoftReset(mkDutWrapper, clk_port);

    Empty mem <- mkPutXactor(dut.memInit.request, clk_port);
    Empty rsa_result <- mkGetXactor(dut.get_result, clk_port);

    Empty shutdown <- mkShutdownXactor();
endmodule

