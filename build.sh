#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directories
BUILD_DIR="build"
LOG_DIR="logs"
WAVE_DIR="waves"
COV_DIR="coverage"

mkdir -p $BUILD_DIR $LOG_DIR $WAVE_DIR $COV_DIR

RTL_FILES="exec/alu.sv base/cpu_top.sv decode/decoder.sv mem/dmem.sv \
mem/instruction_input_memory.sv decode/imm_gen.sv base/pc.sv \
reg/regfile.sv decode/alu_control_unit.sv decode/control_unit.sv \
sys/trap.sv sys/csr.sv exec/muldiv_unit.sv exec/branch_unit.sv mem/bus.sv mem/uart.sv sys/plic.sv"

COMMON_FLAGS=" -Wall -Wno-UNUSED --trace --trace-fst --coverage "

run_cpu() {
    mkdir -p $BUILD_DIR $LOG_DIR $WAVE_DIR $COV_DIR

    echo -e "${YELLOW}==> Building CPU...${NC}"

    verilator $COMMON_FLAGS \
      --cc $RTL_FILES \
      --exe sim/run.cpp \
      --top-module cpu_top \
      --Mdir $BUILD_DIR \
      --build

    echo -e "${GREEN}==> Running CPU...${NC}"

    ./$BUILD_DIR/Vcpu_top \
        > $LOG_DIR/cpu.log 2>&1

    mv *.vcd $WAVE_DIR/ 2>/dev/null || true
    mv *.fst $WAVE_DIR/ 2>/dev/null || true
    mv coverage.dat $COV_DIR/ 2>/dev/null || true

    echo -e "${GREEN}✔ CPU run complete${NC}"
}

run_tb() {
    mkdir -p $BUILD_DIR $LOG_DIR $WAVE_DIR $COV_DIR

    for tbfile in tb/*.sv; do
        tbname=$(basename "$tbfile" .sv)

        echo -e "${YELLOW}==> Building TB: $tbname${NC}"

        rm -rf $BUILD_DIR/*

        verilator $COMMON_FLAGS \
          --cc $RTL_FILES $tbfile \
          --exe sim/run_tb.cpp \
          --top-module $tbname \
          --Mdir $BUILD_DIR \
          --build

        echo -e "${GREEN}==> Running TB: $tbname${NC}"

        ./$BUILD_DIR/V$tbname \
            > $LOG_DIR/${tbname}.log 2>&1 || {
            echo -e "${RED}❌ TB FAILED: $tbname${NC}"
            exit 1
        }

        mv *.vcd $WAVE_DIR/${tbname}.vcd 2>/dev/null || true
        mv *.fst $WAVE_DIR/${tbname}.fst 2>/dev/null || true
        mv coverage.dat $COV_DIR/${tbname}.cov 2>/dev/null || true

        echo -e "${GREEN}✅ TB PASSED: $tbname${NC}"
    done
}

clean() {
    echo "Cleaning..."
    rm -rf $BUILD_DIR $LOG_DIR $WAVE_DIR $COV_DIR
}

case "${1:-}" in
    cpu)
        clean
        run_cpu
        ;;
    tb)
        run_tb
        ;;
    all)
        clean
        run_tb
        run_cpu
        ;;
    *)
        echo "Usage: ./build.sh {cpu|tb|all}"
        exit 1
        ;;
esac