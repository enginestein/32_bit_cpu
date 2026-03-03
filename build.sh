#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RTL_FILES="exec/alu.sv base/cpu_top.sv decode/decoder.sv mem/dmem.sv \
mem/instruction_input_memory.sv decode/imm_gen.sv base/pc.sv \
reg/regfile.sv decode/alu_control_unit.sv decode/control_unit.sv \
sys/trap.sv sys/csr.sv"

run_cpu() {
    echo -e "${YELLOW}==> Building CPU...${NC}"

    verilator -Wall -Wno-UNUSED --trace \
      --cc $RTL_FILES \
      --exe sim/run.cpp \
      --top-module cpu_top \
      --build

    echo -e "${GREEN}==> Running CPU...${NC}"
    ./obj_dir/Vcpu_top
}

run_tb() {

    for tbfile in tb/*.sv; do
        tbname=$(basename "$tbfile" .sv)

        echo -e "${YELLOW}==> Building TB: $tbname${NC}"

        rm -rf obj_dir

        verilator -Wall -Wno-UNUSED --trace \
          --cc $RTL_FILES $tbfile \
          --exe sim/run_tb.cpp \
          --top-module $tbname \
          --build

        echo -e "${GREEN}==> Running TB: $tbname${NC}"
        ./obj_dir/V$tbname || {
            echo -e "${RED}❌ TB FAILED: $tbname${NC}"
            exit 1
        }

        echo -e "${GREEN}✅ TB PASSED: $tbname${NC}"
    done
}

clean() {
    echo "Cleaning..."
    rm -rf obj_dir
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
