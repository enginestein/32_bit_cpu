A RISC-V processor core targeting simulation with Verilator and eventual FPGA synthesis. Most instructions run in a single cycle. Multiply and divide are handled by a dedicated multi-cycle unit. The interrupt and trap system is fully wired.

---

## Table of Contents

- [What it is](#what-it-is)
- [What it supports](#what-it-supports)
- [How it's structured](#how-its-structured)
- [Building and simulating](#building-and-simulating)

---

## What it is

Right now this is a **single-cycle RV32IM core with a multi-cycle M-extension unit and a wired interrupt system**. The pipeline registers are structurally present (IF/ID stage) but the full pipeline isn't committed yet that's the next major step.

The core can:

- Execute all RV32I base instructions in a single cycle
- Execute RV32M multiply and divide through a dedicated unit (3 cycles for mul, 8 for div)
- Handle synchronous traps — ECALL, EBREAK, illegal instruction, misaligned access
- Handle asynchronous hardware interrupts through the PLIC, gated by `mstatus.MIE`
- Talk to memory-mapped peripherals over a simple bus (UART at `0xF000_0xxx`, PLIC at `0xF001_0xxx`)
- Stall the pipeline cleanly during multi-cycle operations so nothing gets corrupted

---

## What it supports

### RV32I base ISA

```
R-type : add  sub  and  or  xor  sll  srl  sra  slt  sltu
I-type : addi andi ori  xori slli srli srai slti sltiu
Load   : lb   lh   lw   lbu  lhu
Store  : sb   sh   sw
Branch : beq  bne  blt  bge  bltu bgeu
Jump   : jal  jalr
Other  : lui  auipc
System : ecall ebreak mret
CSR    : csrrw csrrs csrrc csrrwi csrrsi csrrci
```

### RV32M extension

```
mul  mulh  mulhsu  mulhu
div  divu  rem     remu
```

### CSRs implemented

| CSR     | Address | Notes                          |
|---------|---------|--------------------------------|
| mstatus | 0x300   | MIE bit controls interrupt gate |
| mie     | 0x304   | Per-source interrupt enable     |
| mtvec   | 0x305   | Trap vector base address        |
| mepc    | 0x341   | Exception program counter       |
| mcause  | 0x342   | Trap/interrupt cause            |
| mip     | 0x344   | Interrupt pending (read-only from software, driven by PLIC) |

---

## How it's structured

```
┌─────────────────────────────────────────────────────────┐
│                     cpu_top.sv                          │
│                                                         │
│  PC → imem → decoder → control_unit                     │
│                  ↓             ↓                        │
│             regfile        imm_gen                      │
│                  ↓             ↓                        │
│                    →  ALU  ←                            │
│                       ↓                                 │
│                  muldiv_unit (M-ext)                    │
│                       ↓                                 │
│              bus → dmem / uart / plic                   │
│                       ↓                                 │
│                   writeback → regfile                   │
│                                                         │
│  Interrupt path:                                        │
│  plic.irq_pending → irq gate → sys_trap → pc_next       │
│  csr.mstatus_mie ──────────┘                            │
└─────────────────────────────────────────────────────────┘
```

The `cpu_top.sv` module is the integration point for everything.

---

---

## Building and simulating

Uses [Verilator](https://verilator.org) for simulation.

```bash
# compile
verilator --cc --exe --build -j0 \
  --trace-fst \
  all_the_files.sv \
  --top-module cpu_top

# run
./obj_dir/Vcpu_top

# view waveform (requires GTKWave or Surfer)
gtkwave dump.fst
```

or you can just use the bashfile

```bash

bash build.sh cpu # runs the CPU
bash build.sh tb # runs the testbench
bash build.sh all # runs both

```


---