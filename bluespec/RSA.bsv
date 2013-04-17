
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import RSAPipelineTypes::*;

// Struct to hold RSA packet data
// (Usually 8 bit)
// Doesn't make sense (Does it?) to send modulus,
// maybe modify this later
typedef union tagged {
    RSA_PACKET data;
    RSA_PACKET exponent;
    RSA_PACKET modulus;
} RSAData deriving(Bits, Eq);

typedef Server#(Command, Value) RSAServer;

module mkRSA (RSAServer);
		ModExpt modexpt <- mkModExpt();
    
    Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) data_buffer <- replicateM();
    Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) exponent_buffer <- replicateM();    
    Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) modulus_buffer <- replicateM();

    FIFO#(BIG_INT) outfifo <- mkFIFO();
    
    Reg#(Log#(BI_SIZE) + 1) i <- mkReg(0);
    
    rule process
    	Vector#(3, BIG_INT) packet;
    	
    	if(i == 1023) begin
    		
    		// Preload the packet
    		packet[0] = data[i];
    		packet[1] = exponent[i];
    		packet[2] = modulus[i];
    		
    		// Perform the calculation
    		modexpt.put();
    		Response r <- modexpt.get();
    		
    		// Allow further loads
    		i <= 0;
    	end
  	endrule
    
    interface Put request;
        method Action put(Command cmd);
        		data_buffer[i] <= cmd.data;
        		exponent_buffer[i] <= cmd.exponent;
        		modulus_buffer[i] <= cmd.modulus;
        		
        		// Keep storing data into memory until we have the entire set
        		// Then stall until processing is complete
        		if(i < 1023) begin
        			i <= i + 1;
        		end
        		
        endmethod
    endinterface

    interface Get response = toGet(outfifo);
endmodule

