
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import RSAPipelineTypes::*;
import Vector::*;
import ModExpt::*;

// Struct to hold RSA packet data
// (Usually 8 bit)
typedef struct {
    Bit#(RSA_SIZE) data;
    Bit#(RSA_SIZE) exponent;
    Bit#(RSA_SIZE) modulus;
} Command deriving(Bits, Eq);

typedef Server#(Command, BIG_INT) RSAServer;
typedef enum {PutExpt, GetExpt, Idle, Reset} State deriving (Bits, Eq);

module mkRSA (RSAServer);

		Reg#(State) state <- mkReg(Idle);
    Reg#(BIG_INT) data_buffer <- mkReg(0);
    Reg#(BIG_INT) exponent_buffer <- mkReg(0);    
    Reg#(BIG_INT) modulus_buffer <- mkReg(0);

		ModExpt modexpt <- mkModExpt(data_buffer, exponent_buffer, modulus_buffer);
    
    FIFO#(BIG_INT) outfifo <- mkFIFO();
    
    Reg#(Int#(32)) timer <- mkReg(0);
    Reg#(Int#(32)) old_time <- mkReg(0);
    
    // Once loading is complete, push data to ModExpt
   
    rule pushExpt(state == PutExpt);

    		modexpt.start();
    		
    		state <= GetExpt;
    		
				old_time <= timer;
  	endrule
  	
  	rule countCycles;
  			timer <= timer + 1;
  	endrule
  	
  	rule getExpt(state == GetExpt);
  		  let r <- modexpt.getResult();
  		  $display("Completed in %d cycles", timer - old_time); 
  			outfifo.enq(r);
  			state <= Idle;
  	endrule
    
    // Store data from SceMi inside a buffer (MSB ... LSB format)
    interface Put request;
        method Action put(Command cmd);
        		
        		data_buffer <= zeroExtend(cmd.data);
        		exponent_buffer <= zeroExtend(cmd.exponent);
        		modulus_buffer <= zeroExtend(cmd.modulus);

        		state <= PutExpt;
        endmethod
    endinterface

    interface Get response = toGet(outfifo);
endmodule

