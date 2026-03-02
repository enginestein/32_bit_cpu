#include "Vcpu_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <string>

static const std::string RESET  = "\033[0m";
static const std::string BOLD   = "\033[1m";
static const std::string CYAN   = "\033[36m";
static const std::string GREEN  = "\033[32m";
static const std::string YELLOW = "\033[33m";
static const std::string RED    = "\033[31m";
static const std::string BLUE   = "\033[34m";
static const std::string DIM    = "\033[2m";

static std::string hex32(uint32_t v) {
    std::ostringstream s;
    s << "0x" << std::hex << std::setw(8) << std::setfill('0') << v;
    return s.str();
}

static std::string pc_label(uint32_t pc) {
    switch (pc) {
        case 0x00: return "addi x1, x0, 0       ; i = 0";
        case 0x04: return "addi x2, x0, 0       ; sum = 0";
        case 0x08: return "addi x3, x0, 10      ; limit = 10";
        case 0x0C: return "addi x1, x1, 1       ; loop: i++";
        case 0x10: return "add  x2, x2, x1      ; sum += i";
        case 0x14: return "blt  x1, x3, loop    ; branch if i < 10";
        case 0x18: return "sw   x2, 0(x0)       ; store sum";
        case 0x1C: return "ecall                ; exit";
        default:   return "???";
    }
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vcpu_top* top = new Vcpu_top;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("dump.vcd");

    std::cout << "\n";
    std::cout << BOLD << CYAN;
    std::cout << "  +------------------------------------------+\n";
    std::cout << RESET << "\n";

    // reset
    top->reset = 1;
    top->clk   = 0;
    for (int i = 0; i < 4; i++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(i);
    }
    top->reset = 0;

    const int MAX_CYCLES = 100;
    int      cycle       = 0;
    int      loop_iter   = 0;
    bool     done        = false;
    uint32_t prev_pc     = 0xFFFFFFFF;
    uint32_t snap_x1     = 0;
    uint32_t snap_x2     = 0;

    for (int tick = 4; tick < MAX_CYCLES * 2 + 4 && !done; tick++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(tick);

        if (!top->clk) continue;

        cycle++;
        uint32_t pc = top->pc_dbg;
        uint32_t x1 = top->dbg_x1;
        uint32_t x2 = top->dbg_x2;

        if (pc == 0x00 && prev_pc != 0x00)
            std::cout << BOLD << YELLOW << "\n  -- INIT --\n" << RESET;
        if (pc == 0x0C && prev_pc != 0x0C)
            std::cout << BOLD << BLUE   << "\n  -- LOOP --\n" << RESET;
        if (pc == 0x18 && prev_pc != 0x18)
            std::cout << BOLD << GREEN  << "\n  -- STORE --\n" << RESET;

        if (pc == 0x0C) loop_iter++;

        std::cout << DIM    << "  [cy " << std::setw(3) << cycle << "]  " << RESET;
        std::cout << CYAN   << hex32(pc) << RESET;
        std::cout << "  " << std::left << std::setw(42) << pc_label(pc);
        std::cout << DIM    << "  x1=" << std::setw(4) << x1
                            << "  x2=" << std::setw(4) << x2 << RESET << "\n";

        if (pc == 0x1C) {
            snap_x1 = x1;
            snap_x2 = x2;
            top->clk = !top->clk; top->eval(); tfp->dump(tick + 1);
            top->clk = !top->clk; top->eval(); tfp->dump(tick + 2);
            done = true;
        }

        prev_pc = pc;
    }

    std::cout << "\n";
    std::cout << BOLD << GREEN;
    std::cout << "  +------------------------------------------+\n";
    std::cout << "  |            ECALL  --  EXIT               |\n";
    std::cout << "  +------------------------------------------+\n";
    std::cout << RESET << "\n";

    std::cout << "  Loop iterations : " << BOLD << loop_iter << "\n" << RESET;
    std::cout << "  x1  (i)         : " << BOLD << snap_x1  << "\n" << RESET;
    std::cout << "  x2  (sum)       : " << BOLD << snap_x2  << "   <- expected 55\n" << RESET;
    std::cout << "  Cycles total    : " << BOLD << cycle     << "\n" << RESET;

    if (snap_x2 == 55)
        std::cout << "\n  " << BOLD << GREEN << "PASS -- sum(1..10) = 55\n" << RESET << "\n";
    else
        std::cout << "\n  " << BOLD << RED   << "FAIL -- got " << snap_x2 << ", expected 55\n" << RESET << "\n";

    tfp->close();
    delete top;
    return (snap_x2 == 55) ? 0 : 1;
}