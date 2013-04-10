
import FIFO::*;
import GetPut::*;
import ClientServer::*;

typedef Bit#(32) Value;

typedef enum {
    ADD,
    SUB,
    MUL
} Operation deriving(Bits, Eq);

typedef union tagged {
    void Clear;

    struct {
        Operation op;
        Value val;
    } Operate;
} Command deriving(Bits, Eq);

typedef Server#(Command, Value) Calculator;

module mkCalculator (Calculator);

    Reg#(Value) acc <- mkReg(0);

    FIFO#(Value) outfifo <- mkFIFO();

    interface Put request;
        method Action put(Command cmd);
            Value upd = ?;
            case (cmd) matches
                tagged Clear: upd = 0;
                tagged Operate { op: .op, val: .val }: begin
                    case (op)
                        ADD: upd = acc + val;
                        SUB: upd = acc - val;
                        MUL: upd = acc * val;
                    endcase
                end
            endcase

            acc <= upd;
            outfifo.enq(upd);
        endmethod
    endinterface

    interface Get response = toGet(outfifo);
endmodule

