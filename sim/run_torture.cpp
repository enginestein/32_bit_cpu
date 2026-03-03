#include "Vcpu_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <iomanip>
#include <sstream>

static std::string hex32(uint32_t v) {
    std::ostringstream s;
    s << "0x" << std::hex << std::setw(8)
      << std::setfill('0') << v;
    return s.str();
}

int main(int argc, char **argv) {

    Verilated::commandArgs(argc, argv);
    Vcpu_top* top = new Vcpu_top;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("dump.vcd");

    // Reset
    top->reset = 1;
    top->clk   = 0;
    for (int i = 0; i < 4; i++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(i);
    }
    top->reset = 0;

    const int MAX_CYCLES = 300;
    uint32_t last_pc = 0xFFFFFFFF;
    int cycle = 0;

    std::cout << "\n===== CPU TORTURE TEST START =====\n\n";

    for (int tick = 4; tick < MAX_CYCLES * 2 + 4; tick++) {

        top->clk = !top->clk;
        top->eval();
        tfp->dump(tick);

        if (!top->clk) continue;

        cycle++;

        uint32_t pc = top->pc_dbg;

        std::cout << "[Cycle " << std::setw(3) << cycle << "]  ";
        std::cout << "PC=" << hex32(pc);
        std::cout << "  x1=" << top->dbg_x1;
        std::cout << "  x2=" << top->dbg_x2;
        std::cout << "  x3=" << top->dbg_x3;
        std::cout << "\n";

        // Detect trap vector entry (mtvec = 0x100)
        if (pc == 0x100) {
            std::cout << "\n*** TRAP ENTERED (mtvec=0x100) ***\n";
            break;
        }

        // Detect PC stuck
        if (pc == last_pc) {
            std::cout << "\n*** PC STUCK — HALTING ***\n";
            break;
        }

        last_pc = pc;
    }

    std::cout << "\n===== FINAL REGISTER SNAPSHOT =====\n";
    std::cout << "x1  = " << top->dbg_x1 << "\n";
    std::cout << "x2  = " << top->dbg_x2 << "\n";
    std::cout << "x3  = " << top->dbg_x3 << "\n";
    std::cout << "mem[0] = " << top->dbg_mem0 << "\n";
    std::cout << "mem[4] = " << top->dbg_mem4 << "\n";
    std::cout << "\nSimulation finished after "
              << cycle << " cycles.\n\n";

    tfp->close();
    delete top;
    return 0;
}