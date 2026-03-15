What I define this as right now is a: **Single-Cycle Core with Multi-Cycle M-Extension, pipeline in process**

---

# 1. CPU Architecture Overview

This processor is a **32-bit RISC-V core implementing the RV32I instruction set**, with **partial support for the M extension** (multiply and divide operations).

The design is intentionally simple and educational while still covering a large portion of the RISC-V base ISA. Most instructions complete in a **single cycle**, while multiply and divide operations are handled by a **separate multi-cycle unit**.

Key architectural characteristics:

• 32-bit datapath
• Single-cycle execution for most instructions
• Multi-cycle execution for multiply and divide operations
• 32-register RISC-V register file
• Separate instruction and data memory
• Basic CSR support for trap handling
• Branch and jump control flow support
• Detection of misaligned memory accesses

Conceptually, instruction execution follows the standard CPU stages:

```
PC → FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK
```

Although the processor is **not physically pipelined**, the datapath still follows these logical stages internally.

The **main integration point for the entire processor is the `cpu_top.sv` module**, which connects all components and defines the overall datapath.

---

# 2. Top-Level CPU (`cpu_top.sv`)

The `cpu_top` module acts as the **central coordinator for the processor**. It instantiates all major components and wires them together to form the complete datapath.

### Inputs

| Signal | Width | Description      |
| ------ | ----- | ---------------- |
| clk    | 1     | System clock     |
| reset  | 1     | Global CPU reset |

### Debug Outputs

These signals expose internal state for simulation and debugging.

| Signal    | Description                                           |
| --------- | ----------------------------------------------------- |
| pc_dbg    | Current value of the program counter                  |
| dbg_x1    | Register x1                                           |
| dbg_x2    | Register x2                                           |
| dbg_x3    | Register x3                                           |
| dbg_mem0  | Memory contents at address 0                          |
| dbg_mem4  | Memory contents at address 4                          |
| dbg_stall | Indicates when the CPU is stalled by the mul/div unit |

---

# 3. Major Datapath Components

The following diagram shows the major blocks that make up the processor datapath.

```
           +-------------+
           |   PC        |
           +-------------+
                  |
                  v
           +-------------+
           | Instruction |
           |  Memory     |
           +-------------+
                  |
                  v
           +-------------+
           |  Decoder    |
           +-------------+
                  |
                  v
           +-------------+
           | Control Unit|
           +-------------+
                  |
      +-----------+-----------+
      |                       |
      v                       v
+------------+        +--------------+
| Register   |        | Immediate    |
| File       |        | Generator    |
+------------+        +--------------+
      |                       |
      +-----------+-----------+
                  |
                  v
              +--------+
              |  ALU   |
              +--------+
                  |
                  v
          +---------------+
          | Mul/Div Unit  |
          +---------------+
                  |
                  v
          +---------------+
          | Data Memory   |
          +---------------+
                  |
                  v
            Writeback
```

Each block performs a specific role in instruction execution.

---

# 4. Instruction Fetch

### Program Counter

Module: `pc.sv`

The program counter keeps track of the **address of the current instruction**.

Its behavior is straightforward:

```
if reset:
    pc_out = 0
else:
    pc_out = pc_next
```

The PC updates on the **rising edge of the clock**.

---

### Instruction Memory

Module: `instruction_input_memory.sv`

Instruction memory is implemented as a **ROM-style array**:

```
logic [31:0] mem [0:255]
```

Instructions are fetched using:

```
instr = mem[addr[9:2]]
```

Because RISC-V instructions are **word-aligned**, the lower two address bits are discarded.

---

# 5. Instruction Decode

### Module

`decoder.sv`

The decoder extracts the different fields from a 32-bit instruction.

| Field  | Bits    |
| ------ | ------- |
| opcode | [6:0]   |
| rd     | [11:7]  |
| funct3 | [14:12] |
| rs1    | [19:15] |
| rs2    | [24:20] |
| funct7 | [31:25] |

A typical R-type instruction looks like:

```
| funct7 | rs2 | rs1 | funct3 | rd | opcode |
```

These fields are passed to the control unit and other datapath components.

---

# 6. Control Unit

### Module

`control_unit.sv`

The control unit decides **how the rest of the hardware should behave** for each instruction.

Inputs:

```
opcode
funct3
instr
```

Outputs include:

| Signal     | Purpose                           |
| ---------- | --------------------------------- |
| reg_we     | Enables register writes           |
| alu_src    | Selects ALU operand source        |
| alu_op     | Determines ALU operation category |
| mem_we     | Enables memory write              |
| mem_re     | Enables memory read               |
| mem_to_reg | Selects memory data for writeback |
| branch     | Indicates branch instruction      |
| trap       | Indicates trap event              |
| trap_cause | Specifies trap reason             |

Example control logic:

```
if opcode == R-type:
    reg_we = 1
    alu_op = ALU_OP

if opcode == LOAD:
    mem_re = 1
    mem_to_reg = 1
```

---

# 7. Immediate Generator

### Module

`imm_gen.sv`

This module produces the **correct 32-bit immediate value** for each instruction format.

Supported formats:

| Type   | Example  |
| ------ | -------- |
| I-type | addi, lw |
| S-type | sw       |
| B-type | beq      |
| U-type | lui      |
| J-type | jal      |

Example:

```
imm = sign_extend(instr[31:20])
```

The immediate is then used by the ALU or branch logic.

---

# 8. Register File

### Module

`regfile.sv`

The register file implements the **32 general-purpose RISC-V registers**.

```
logic [31:0] regs [0:31]
```

A special rule in RISC-V:

```
x0 is always 0
```

Reads occur combinationally:

```
rd1 = regs[rs1]
rd2 = regs[rs2]
```

Writes occur on the clock edge:

```
if (we && rd != 0)
    regs[rd] <= wd
```

---

# 9. ALU

### Module

`alu.sv`

The ALU performs arithmetic and logical operations.

Inputs:

```
a
b
alu_control
```

Output:

```
y
```

Supported operations include:

| Operation | Code  |
| --------- | ----- |
| ADD       | 00000 |
| SUB       | 00001 |
| AND       | 00010 |
| OR        | 00011 |
| XOR       | 00100 |
| SLL       | 00101 |
| SRL       | 00110 |
| SRA       | 00111 |
| SLT       | 01000 |
| SLTU      | 01001 |

The ALU also handles branch comparisons.

Multiply and divide instructions are handled separately by the **mul/div unit**.

---

# 10. ALU Control Unit

### Module

`alu_control_unit.sv`

This module translates high-level ALU operation categories into **specific ALU control signals**.

Inputs:

```
alu_op
funct3
funct7
```

Example mapping:

```
alu_op = 00 → ADD
alu_op = 01 → branch comparison
alu_op = 10 → determined by funct3/funct7
```

The unit also identifies instructions belonging to the **M extension**.

---

# 11. Multiply/Divide Unit

### Module

`muldiv_unit.sv`

This module executes slow arithmetic operations:

```
MUL
DIV
REM
```

These operations take multiple cycles:

| Operation | Cycles |
| --------- | ------ |
| Multiply  | 3      |
| Divide    | 8      |

Interface:

```
start  → begin operation
ready  → result available
result → final value
```

Internally, a cycle counter tracks progress:

```
counter increments each cycle
when counter reaches target
    ready = 1
```

---

# 12. Stall Logic

Stall logic is implemented inside `cpu_top`.

Its purpose is to **pause the CPU while a mul/div operation completes**.

Condition:

```
stall = is_muldiv && !muldiv_ready
```

When stalled:

```
PC does not advance
register writes are disabled
```

This ensures the CPU does not execute new instructions until the result is ready.

---

# 13. Data Memory

### Module

`dmem.sv`

Data memory is implemented as **byte-addressable RAM**:

```
logic [7:0] mem [0:4095]
```

The memory supports several load and store instructions:

| Instruction | funct3 |
| ----------- | ------ |
| LB / SB     | 000    |
| LH / SH     | 001    |
| LW / SW     | 010    |
| LBU         | 100    |
| LHU         | 101    |

The module also checks for **misaligned accesses**.

Example:

```
word access must align to 4 bytes
addr[1:0] must equal 00
```

---

# 14. Writeback Stage

The writeback stage determines which value is written to the register file.

Selection logic:

```
writeback_data =
    mret        ? csr_rdata
    csr         ? csr_rdata
    jal/jalr    ? pc+4
    load        ? mem_data
    mul/div     ? muldiv_result
    else        ? alu_out
```

---

# 15. CSR System

### Module

`csr.sv`

This module implements a subset of machine-mode CSRs.

| CSR     | Address |
| ------- | ------- |
| mstatus | 0x300   |
| mtvec   | 0x305   |
| mepc    | 0x341   |
| mcause  | 0x342   |

When a trap occurs:

```
mepc   = PC
mcause = trap cause
```

---

# 16. Trap Handler

### Module

`trap.sv`

The trap module redirects execution when an exception occurs.

```
if trap:
    pc_next = mtvec
else:
    pc_next = normal_pc_next
```

This transfers control to the trap handler.

---

# 17. Control Flow

Branch logic is implemented inside `cpu_top`.

A branch is taken when:

```
jal
jalr
branch condition
```

Branch targets are calculated as:

```
jal   → pc + imm
jalr  → rs1 + imm
branch→ pc + imm
```

---

# 18. Execution Timeline Example

Example: `DIV`

| Cycle    | Event                     |
| -------- | ------------------------- |
| T        | mul/div operation starts  |
| T+1..T+7 | CPU stalled               |
| T+8      | result becomes available  |
| T+9      | next instruction executes |

---

# 19. Debug System

During simulation the CPU prints detailed debug information every cycle, including:

• Program counter
• Current instruction
• Decoded fields
• ALU inputs and operation
• Memory control signals
• Register write activity
• Register snapshots

This makes it possible to **trace the complete execution of a program step by step**.

---

# 20. Instruction Support

### RV32I Base ISA

R-type instructions:

```
add sub and or xor sll srl sra slt sltu
```

I-type instructions:

```
addi andi ori xori slli srli srai slti sltiu
```

Memory operations:

```
lb lh lw lbu lhu
sb sh sw
```

Control flow:

```
beq bne blt bge bltu bgeu
jal jalr
```

Other instructions:

```
lui
auipc
```

---

### M Extension

Supported instructions:

```
mul
mulh
mulhsu
mulhu
div
divu
rem
remu
```

---

# 21. Reset Behavior

When reset is asserted:

```
pc = 0
mul/div state cleared
CSR registers initialized
```

Execution then begins at **instruction memory address 0**.