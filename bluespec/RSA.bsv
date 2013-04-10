
import FIFO::*;
import GetPut::*;
import ClientServer::*;

typedef union tagged {
    RSA_PACKET data;
} RSAData deriving(Bits, Eq);

typedef Server#(Command, Value) RSAServer;

module mkRSA (RSAServer);

    Vector#(PACKET_COUNT, RSA_PACKET) buffer <- replicateM();

    FIFO#(BIG_INT) outfifo <- mkFIFO();
    
    Reg#(Log#(BI_SIZE) + 1) i <- mkReg(0);

    interface Put request;
        method Action put(Command cmd);
        		buffer[i] = cmd.data;
        		i = i + 1;
        		
        		if(i > 1023) begin
        			i = 0;
        		end
        		
            outfifo.enq(pack(buffer));
        endmethod
    endinterface

    interface Get response = toGet(outfifo);
endmodule

