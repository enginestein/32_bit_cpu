#include "Vcpu_top.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <iomanip>
#include <sstream>

static std::string hex32(uint32_t v) {
    std::ostringstream s;
    s << "0x" << std::hex << std::setw(8) << std::setfill('0') << v;
    return s.str();
}

struct Expected {
    const char* name;
    int         reg_idx;
    uint32_t    value;
};

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vcpu_top* top = new Vcpu_top;

    Verilated::traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("dump.fst");

    top->reset = 1;
    top->clk   = 0;
    for (int i = 0; i < 8; i++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(i);
    }
    top->reset = 0;

    const int MAX_CYCLES     = 2000;
    const int MAX_STUCK_REAL = 10;

    uint32_t last_pc    = 0xFFFFFFFF;
    int      stuck_count = 0;
    int      cycle       = 0;

    std::cout << "\n===== PIPELINE CPU TEST START =====\n\n";

    for (int tick = 8; tick < MAX_CYCLES * 2 + 8; tick++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(tick);

        if (!top->clk) continue;
        cycle++;

        uint32_t pc    = top->pc_dbg;
        bool     stall = (top->dbg_stall != 0);

        std::cout << "[Cycle " << std::setw(3) << cycle << "]  ";
        std::cout << "PC=" << hex32(pc);
        std::cout << "  x1="  << std::setw(3) << top->dbg_x1;
        std::cout << "  x2="  << std::setw(3) << top->dbg_x2;
        std::cout << "  x3="  << std::setw(3) << top->dbg_x3;
        if (stall) std::cout << "  <MULDIV_STALL>";
        std::cout << "\n";

        if (pc == 0x100) {
            std::cout << "\n*** TRAP ENTERED (mtvec=0x100) ***\n";
            break;
        }

        if (pc == last_pc && !stall) {
            stuck_count++;
            if (stuck_count >= MAX_STUCK_REAL) {
                std::cout << "\n*** HALT (JAL self-loop detected) ***\n";
                break;
            }
        } else {
            stuck_count = 0;
        }
        last_pc = pc;
    }

    std::cout << "\n===== PIPELINE TEST RESULTS =====\n\n";

    bool all_pass = true;

    auto check = [&](const char* test, uint32_t got, uint32_t want) {
        bool ok = (got == want);
        std::cout << (ok ? "  PASS" : "  FAIL")
                  << "  " << std::left << std::setw(40) << test
                  << "  got=" << std::setw(10) << got
                  << "  want=" << want << "\n";
        if (!ok) all_pass = false;
    };

    check("TEST1: x1 = 1  (basic write)",           top->dbg_x1, 1);
    check("TEST1: x2 = 2  (basic write)",           top->dbg_x2, 2);
    check("TEST1: x3 = 3  (basic write)",           top->dbg_x3, 3);

    std::cout << "\n===== FINAL REGISTER SNAPSHOT =====\n";
    std::cout << "x1  = " << top->dbg_x1  << "\n";
    std::cout << "x2  = " << top->dbg_x2  << "\n";
    std::cout << "x3  = " << top->dbg_x3  << "\n";
    std::cout << "mem[0] = " << top->dbg_mem0 << "\n";
    std::cout << "mem[4] = " << top->dbg_mem4 << "\n";

    std::cout << "\n" << (all_pass ? "ALL TESTS PASSED" : "SOME TESTS FAILED")
              << " — " << cycle << " cycles\n\n";

    tfp->close();
    delete top;
    return all_pass ? 0 : 1;
}