#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    while (!Verilated::gotFinish()) { }
    return 0;
}
