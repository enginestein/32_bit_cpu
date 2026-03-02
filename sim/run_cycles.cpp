#include "Vcpu_top.h"
#include "verilated.h"
#include <iostream>
#include "verilated_vcd_c.h"


int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vcpu_top* top = new Vcpu_top;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("dump.vcd");

    top->reset = 1;
    top->clk = 0;

    for (int i = 0; i < 200; i++) {
        if (i == 2) top->reset = 0;

        top->clk = !top->clk;
        top->eval();
        tfp->dump(i);

        std::cout
          << "PC=" << top->pc_dbg
          << " x1=" << top->dbg_x1
          << " x2=" << top->dbg_x2
          << " x3=" << top->dbg_x3
          << std::endl;
    }

    tfp->close();
    delete top;
    return 0;
}
