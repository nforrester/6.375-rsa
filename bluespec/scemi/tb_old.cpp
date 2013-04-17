
#include <cassert>
#include <iostream>
#include <unistd.h>

#include "bsv_scemi.h"
#include "SceMiHeaders.h"

bool isoperation(const std::string& op)
{
    return op == "ADD" || op == "SUB" || op == "MUL";
}

Operation operationof(const std::string& op)
{
    if (op == "ADD") {
        return Operation(Operation::e_ADD);
    } else if (op == "SUB") {
        return Operation(Operation::e_SUB);
    } else if (op == "MUL") {
        return Operation(Operation::e_MUL);
    }
    assert(false);
}

int main(int argc, char* argv[])
{
    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");
    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);

    // Initialize the SceMi inport
    InportProxyT<Command> inport ("", "scemi_calcxactor_req_inport", sceMi);

    // Initialize the SceMi outport
    OutportQueueT<Value> outport ("", "scemi_calcxactor_resp_outport", sceMi);

    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);

    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread (sceMi);

    Command cmd;

    while (std::cin) {
        std::cout << "$ ";
        std::string op;
        int val;

        std::cin >> op;
        if (isoperation(op)) {
            std::cin >> val;
            cmd.the_tag = Command::tag_Operate;
            cmd.m_Operate.m_val = val;
            cmd.m_Operate.m_op = operationof(op);

            std::cout << "sending " << cmd << std::endl;
            inport.sendMessage(cmd);
            std::cout << outport.getMessage() << std::endl;;

        } else if (op == "CLR") {
            cmd.the_tag = Command::tag_Clear;

            std::cout << "sending " << cmd << std::endl;
            inport.sendMessage(cmd);
            std::cout << outport.getMessage() << std::endl;;

        } else if (op == "exit") {
            break;
        } else {
            std::cout << op << ": unknown operation " << std::endl;
            continue;
        }
    }

    std::cout << "shutting down..." << std::endl;
    shutdown.blocking_send_finish();
    scemi_service_thread->stop();
    scemi_service_thread->join();
    SceMi::Shutdown(sceMi);
    std::cout << "finished" << std::endl;

    return 0;
}

