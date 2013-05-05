
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import RSAPipelineTypes::*;
import Vector::*;
import ModExpt::*;

// Struct to hold RSA packet data
// (Usually 8 bit)
typedef struct {
    Bit#(RSA_PACKET_SIZE) data;
    Bit#(RSA_PACKET_SIZE) exponent;
    Bit#(RSA_PACKET_SIZE) modulus;
} Command deriving(Bits, Eq);

typedef Server#(Command, BIG_INT) RSAServer;
typedef enum {PutExpt, GetExpt, Idle, Reset} State deriving (Bits, Eq);

module mkRSA (RSAServer);

		Reg#(State) state <- mkReg(Idle);
		// Concatenates chunks into one big BIG_INT
		function BIG_INT toBigInt(Vector#(PACKET_COUNT, Reg#(RSA_PACKET)) data);
			BIG_INT result = 0;
			
			for(Integer i = 0; i < valueOf(BI_SIZE); i = i + 1) begin
				Integer chunk_id = (i * valueOf(PACKET_COUNT)) / valueOf(BI_SIZE);
				RSA_PACKET chunk = data[chunk_id];
				result[i] = chunk[i - (chunk_id * valueOf(RSA_PACKET_SIZE))];
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
   
    rule pushExpt(state == PutExpt);

    		Vector#(3, BIG_INT) packet;
    		
    		// Preload the packet
    		packet[0] = toBigInt(data_buffer);
    		packet[1] = toBigInt(exponent_buffer);
    		packet[2] = toBigInt(modulus_buffer);
    
    		// Perform the calculation
    		$display("Data %X", packet[0]);
    		$display("Mod %X", packet[2]);
    		$display("Exponent %X", packet[1]);
    		modexpt.request.put(packet);
    		
    		// Allow further loads
    		i <= 0;
    		state <= GetExpt;

  	endrule
  	
  	rule getExpt(state == GetExpt);
  		  let r <- modexpt.response.get();
  			outfifo.enq(r);
  			i <= 0;
  			state <= Idle;
  	endrule
    
    // Store data from SceMi inside a buffer (MSB ... LSB format)
    interface Put request;
        method Action put(Command cmd);
        		
        		data_buffer[i] <= cmd.data;
        		exponent_buffer[i] <= cmd.exponent;
        		modulus_buffer[i] <= cmd.modulus;

        		/*$display("Got packet", i, " out of ", (valueOf(TDiv#(BI_SIZE, RSA_PACKET_SIZE)) - 1) );
        		$display("Mod %X Data %X Exponent %X", cmd.modulus, cmd.data, cmd.exponent);*/

        		// Keep storing data into memory until we have the entire set
        		// Then stall until processing is complete
        		if(i < fromInteger((valueOf(TDiv#(BI_SIZE, RSA_PACKET_SIZE)) - 1)) ) begin
        			i <= i + 1;
        		end else begin
        			state <= PutExpt;
        		end
        		
        endmethod
    endinterface

    interface Get response = toGet(outfifo);
endmodule

