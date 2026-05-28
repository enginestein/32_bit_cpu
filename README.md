## Table of Contents
- [What it is](#what-it-is)
- [What it supports](#what-it-supports)
- [How it's structured](#how-its-structured)
- [Building and simulating](#building-and-simulating)

---

## What it is

This is a **5-stage pipelined RV32IM core** with full hazard handling, forwarding, and a wired interrupt system.

The pipeline stages are IF → ID → EX → MEM → WB, connected through registered stage boundaries with proper flush and stall control.

The core can:
- Execute all RV32I base instructions through a 5-stage pipeline
- Execute RV32M multiply and divide through a dedicated multi-cycle unit (stalls the pipeline until ready)
- Forward results EX→EX and MEM→EX to avoid RAW hazards without stalling
- Stall and flush on load-use hazards (one bubble inserted automatically)
- Flush IF/ID and ID/EX stages on taken branches and jumps
- Handle synchronous traps — ECALL, EBREAK, illegal instruction, misaligned access
- Handle asynchronous hardware interrupts through the PLIC, gated by `mstatus.MIE`
- Redirect the PC to `mtvec` on any trap or IRQ, and return with `mret`
- Talk to memory-mapped peripherals over a simple bus (UART at `0xF000_0xxx`, PLIC at `0xF001_0xxx`)

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

### Hazard handling
| Hazard type | Mechanism |
|---|---|
| RAW (non-load) | EX→EX and MEM→EX forwarding via `hazard_unit` |
| Load-use RAW | 1-cycle stall + ID/EX bubble |
| Control (branch/jump) | IF/ID and ID/EX flush on taken |
| Trap / IRQ | Full pipeline flush + PC redirect to `mtvec` |
| M-extension stall | Pipeline frozen until `muldiv_ready` asserts |

### CSRs implemented
| CSR | Address | Notes |
|---|---|---|
| mstatus | 0x300 | MIE bit controls interrupt gate |
| mie | 0x304 | Per-source interrupt enable |
| mtvec | 0x305 | Trap vector base address |
| mepc | 0x341 | Exception program counter |
| mcause | 0x342 | Trap/interrupt cause |
| mip | 0x344 | Interrupt pending (read-only from software, driven by PLIC) |

---

## How it's structured

<img width="1122" height="1402" alt="4aea9060-cf07-4619-9381-4fcb8821bd0c" src="https://github.com/user-attachments/assets/fc2c7604-3e93-470c-9fe7-297e37aa1558" />

`cpu_top.sv` is the integration point. The major submodules are:

| Module | Stage | Role |
|---|---|---|
| `pc` | IF | Program counter register |
| `instruction_input_memory` | IF | Instruction memory |
| `decoder` | ID | Instruction decode, field extraction |
| `imm_gen` | ID | Immediate sign-extension |
| `control_unit` | ID | Control signal generation |
| `regfile` | ID/WB | 32-entry register file (write at WB, read at ID) |
| `alu_control_unit` | EX | Maps opcode/funct fields to ALU op |
| `alu` | EX | Main integer ALU |
| `muldiv_unit` | EX | Multi-cycle multiply/divide |
| `branch_unit` | EX | Branch condition evaluation |
| `hazard_unit` | EX | Stall, flush, and forwarding control |
| `bus` | MEM | Address decode and peripheral routing |
| `dmem` | MEM | Data memory |
| `uart` | MEM | UART transmitter |
| `plic` | MEM | Platform-level interrupt controller |
| `csr` | MEM | Control and status registers |
| `trap` | MEM | Trap/IRQ arbitration and PC redirect |

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

or just use the build script:

```bash
bash build.sh cpu   # runs the CPU
bash build.sh tb    # runs the testbench
bash build.sh all   # runs both
```
