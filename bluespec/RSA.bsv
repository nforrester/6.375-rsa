
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import RSAPipelineTypes::*;
import Vector::*;
import ModExpt::*;

// Struct to hold RSA packet data
// (Usually 8 bit)
// Doesn't make sense (Does it?) to send modulus,
// maybe modify this later
typedef struct {
    Bit#(8) data;
    Bit#(8) exponent;
    Bit#(8) modulus;
} Command deriving(Bits, Eq);

typedef Server#(Command, BIG_INT) RSAServer;

module mkRSA (RSAServer);

		// Concatenates chunks into one big BIG_INT
		function BIG_INT toBigInt(Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) data);
			BIG_INT result = 0;
			
			for(Integer i = 0; i < BI_SIZE; i = i + 1) begin
				Integer chunk_id = i * (NCHUNKS / BI_SIZE);
				RSA_PACKET chunk = data[chunk_id];
				result[i] = data[i - (chunk_id * NUM_BITS_IN_CHUNK)];
			end
			
			return result;
		
		endfunction

		ModExpt modexpt <- mkModExpt();
    
    Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) data_buffer <- replicateM(mkReg(0));
    Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) exponent_buffer <- replicateM(mkReg(0));    
    Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) modulus_buffer <- replicateM(mkReg(0));

    FIFO#(BIG_INT) outfifo <- mkFIFO();
    
    Reg#(Bit#(TAdd#(TLog#(BI_SIZE), 1))) i <- mkReg(0);
    
    // Once loading is complete, push data to ModExpt
    rule process;

    		Vector#(3, BIG_INT) packet;
    		
    		// Preload the packet
    		packet[0] = toBigInt(data_buffer);
    		packet[1] = toBigInt(exponent_buffer);
    		packet[2] = toBigInt(modulus_buffer);
    		
    		// Perform the calculation
    		modexpt.request.put(packet);
    		let r <- modexpt.get();
    		
    		// Allow further loads
    		i <= 0;

  	endrule
    
    // Store data from SceMi inside a buffer
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

