```
                    ┌─────────────────────────────────────────────────────┐
                    │                     CPU_TOP                         │
                    │                                                     |
┌─────────┐        ┌─────────┐        ┌─────────┐        ┌─────────┐      │
│   PC    │───────▶│  IMEM   │───────▶│ DECODER │───────▶│   RF    │      │
└─────────┘        └─────────┘        └─────────┘        └─────────┘      │
     │                                                     │    │         │
     │                                                     │    │         │
     │                                              ┌──────▼────▼─────┐   │
     │                                              │                 │   │
     │                                              │   ALU + CTRL    │   │
     │                                              │                 │   │
     │                                              └──────┬────┬─────┘   │
     │                                                     │    │         │
     │                                              ┌──────▼────▼─────┐   │
     │                                              │      DMEM       │   │
     │                                              └─────────────────┘   │
     │                                                     │              │
     └─────────────────────────────────────────────────────┘              │
                    │                                                     |
                    └─────────────────────────────────────────────────────┘
```

---


### 1. Program Counter (pc.sv)
**Purpose:** Holds the address of the current instruction and determines the next instruction to fetch.

**Interface:**
```systemverilog
module pc (
    input  logic        clk,           // Clock signal
    input  logic        reset,         // Reset to 0
    input  logic        branch_taken,  // Branch taken flag
    input  logic [31:0] branch_target, // Target address for branches
    output logic [31:0] pc_out         // Current PC value
);
```

**Operation Modes:**
- **Normal:** `pc_out <= pc_out + 32'd4` (increment by 4 bytes)
- **Branch/Jump:** `pc_out <= branch_target` (jump to target)
- **Reset:** `pc_out <= 32'd0` (start from 0)

**Timing Diagram:**
```
clk    ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
       ─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
       
pc_out   0     4     8     12    16    20
       ────▼────▼────▼────▼────▼────▼────
```

---

### 2. Instruction Memory (instruction_input_memory.sv)
**Purpose:** ROM containing the program to execute. 256 32-bit words.

**Memory Map (Current Test Program):**
| Address | Hex Value  | Assembly      | Description                  |
|---------|------------|---------------|------------------------------|
| 0x00    | 00500093   | `addi x1, x0, 5`  | x1 = 5                    |
| 0x04    | 008002ef   | `jal  x5, +8`     | Jump to 0x0C, save PC+4 in x5 |
| 0x08    | 0000006f   | `jal  x0, 0`      | Infinite loop at 0x08      |
| 0x0C    | 00a08093   | `addi x1, x1, 10` | x1 = 15                    |
| 0x10    | 00028067   | `jalr x0, x5, 0`  | Return to 0x08             |

**Address Translation:**
```
32-bit Address: 0x0000000C (12 decimal)
Word Index:     addr[9:2] = 12 >> 2 = 3
Memory Access:  mem[3] = 0x00A08093
```

---

### 3. Decoder (decoder.sv)
**Purpose:** Extracts instruction fields from the 32-bit machine code.

**Field Extraction:**
```
31:25   24:20   19:15   14:12   11:7    6:0
┌───────┬───────┬───────┬───────┬───────┬───────┐
│ funct7│  rs2  │  rs1  │funct3 │  rd   │opcode │
│ [6:0] │ [4:0] │ [4:0] │ [2:0] │ [4:0] │ [6:0] │
└───────┴───────┴───────┴───────┴───────┴───────┘
```

**Example: 0x00500093 (addi x1, x0, 5)**
```
Binary: 000000000101 00000 000 00001 0010011
        [imm=5]     [rs1=0][f3][rd=1][op=addi]
```

---

### 4. Register File (regfile.sv)
**Purpose:** 32 × 32-bit general-purpose registers (x0-x31).

**Special Register: x0**
- Always reads as 0
- Writes are ignored (even if write enable is high)

**Register Snapshot (After Test Program):**
| Register | Value | Purpose            |
|----------|-------|--------------------|
| x0       | 0     | Hardwired zero     |
| x1       | 15    | Counter            |
| x2       | 0     | Unused             |
| x3       | 0     | Unused             |
| x5       | 8     | Return address     |

**Write Operation Timing:**
```
clk    ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
        ─┘ └─┘ └─┘ └─┘ └─┘ └─
        
we     ────────┐   ┌─────────
               └───┘
               
wd      XXXXX──5───XXXXX──15──XXXXX
                ↑        ↑
         Write x1=5   Write x1=15
```

---

### 5. Immediate Generator (imm_gen.sv)
**Purpose:** Extracts and sign-extends immediate values from instructions.

**Immediate Formats:**

```
I-Type (addi, lw):
        ┌─────────────────────┬─────────────┐
        │     imm[11:0]       │    rs1      │
        └─────────────────────┴─────────────┘
        
S-Type (sw):
        ┌─────────┬───────────┬─────────────┐
        │imm[11:5]│   rs2     │   imm[4:0]  │
        └─────────┴───────────┴─────────────┘
        
B-Type (beq):
        ┌─┬─┬─────────┬───────┬─────────┬─┐
        │ │ │         │       │         │ │
        └─┴─┴─────────┴───────┴─────────┴─┘
        12 11 10:5    4:1     11       1 0
        
U-Type (lui):
        ┌─────────────────────────────┬─────┐
        │         imm[31:12]          │     │
        └─────────────────────────────┴─────┘
        
J-Type (jal):
        ┌─┬───────────┬─┬───────────┬───────┐
        │ │           │ │           │       │
        └─┴───────────┴─┴───────────┴───────┘
        20 19:12     20 30:21       20     1
```

---

### 6. Control Unit (control_unit.sv)
**Purpose:** Generates control signals based on opcode.

**Control Signal Matrix:**

| Instruction | opcode  | reg_we | alu_src | alu_op | mem_we | mem_re | mem_to_reg | branch |
|-------------|---------|--------|---------|--------|--------|--------|------------|--------|
| R-Type      | 0110011 | 1      | 0       | 10     | 0      | 0      | 0          | 0      |
| I-Type      | 0010011 | 1      | 1       | 10     | 0      | 0      | 0          | 0      |
| Load        | 0000011 | 1      | 1       | 00     | 0      | 1      | 1          | 0      |
| Store       | 0100011 | 0      | 1       | 00     | 1      | 0      | 0          | 0      |
| Branch      | 1100011 | 0      | 0       | 01     | 0      | 0      | 0          | 1      |
| JAL         | 1101111 | 1      | 0       | 00     | 0      | 0      | 0          | 0      |
| JALR        | 1100111 | 1      | 1       | 00     | 0      | 0      | 0          | 0      |
| LUI         | 0110111 | 1      | 1       | 00     | 0      | 0      | 0          | 0      |
| AUIPC       | 0010111 | 1      | 1       | 00     | 0      | 0      | 0          | 0      |

---

### 7. ALU Control Unit (alu_control_unit.sv)
**Purpose:** Decodes funct3 and funct7 to generate precise ALU operation.

**Truth Table:**

| alu_op | funct3 | funct7      | alu_control | Operation |
|--------|--------|-------------|-------------|-----------|
| 00     | xxx    | xxxxxxx     | 0000        | ADD       |
| 01     | xxx    | xxxxxxx     | 0001        | SUB       |
| 10     | 000    | 0000000     | 0000        | ADD       |
| 10     | 000    | 0100000     | 0001        | SUB       |
| 10     | 111    | 0000000     | 0010        | AND       |
| 10     | 110    | 0000000     | 0011        | OR        |
| 10     | 100    | 0000000     | 0100        | XOR       |
| 10     | 001    | 0000000     | 0101        | SLL       |
| 10     | 101    | 0000000     | 0110        | SRL       |
| 10     | 101    | 0100000     | 0111        | SRA       |
| 10     | 010    | 0000000     | 1000        | SLT       |
| 10     | 011    | 0000000     | 1010        | EQ        |

---

### 8. ALU (alu.sv)
**Purpose:** Performs arithmetic and logical operations.

**Operation Codes:**

| Code | Operation | Formula                  | Example                 |
|------|-----------|--------------------------|-------------------------|
| 0000 | ADD       | `y = a + b`              | `add x3, x1, x2`        |
| 0001 | SUB       | `y = a - b`              | `sub x4, x1, x2`        |
| 0010 | AND       | `y = a & b`              | `and x5, x1, x2`        |
| 0011 | OR        | `y = a | b`              | `or x6, x1, x2`         |
| 0100 | XOR       | `y = a ^ b`              | `xor x7, x1, x2`        |
| 0101 | SLL       | `y = a << b[4:0]`        | `sll x8, x1, x2`        |
| 0110 | SRL       | `y = a >> b[4:0]`        | `srl x9, x1, x2`        |
| 0111 | SRA       | `y = a >>> b[4:0]`       | `sra x10, x1, x2`       |
| 1000 | SLT       | `y = (a < b) ? 1 : 0`    | `slt x11, x1, x2`       |
| 1010 | EQ        | `y = (a == b) ? 1 : 0`   | `beq x1, x2, label`     |

**ALU Input Selection:**

```systemverilog
// ALU input A selection
assign alu_a = (opcode == 7'b0110111) ? 32'd0 :    // LUI uses 0
               (opcode == 7'b0010111) ? pc :       // AUIPC uses PC
               rs1_val;                             // Default: rs1

// ALU input B selection  
assign alu_b = (alu_src) ? imm : rs2_val;          // Immediate or rs2
```

---

### 9. Data Memory (dmem.sv)
**Purpose:** 256 × 32-bit data memory for loads/stores.

**Memory Organization:**
- 256 words (1024 bytes)
- Word-aligned access only
- Byte address → word index: `addr[9:2]`

**Load Operation (lw):**
```
Address: 0x00000100
Word index: 100 >> 2 = 64 (0x40)
Returns: mem[64]
```

**Store Operation (sw):**
```
On rising clock edge with we=1:
mem[addr[9:2]] <= wd

---