verilator -Wall -Wno-UNUSED --trace \
  --cc rtl/alu.sv rtl/cpu_top.sv rtl/decoder.sv rtl/dmem.sv \
  rtl/imem.sv rtl/imm_gen.sv rtl/pc.sv rtl/regfile.sv rtl/alu_control_unit.sv rtl/control_unit.sv \
  --exe sim/tb.cpp \
  --top-module cpu_top \
  --build

./obj_dir/Vcpu_top