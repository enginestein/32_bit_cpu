---
 
# cpu_top.sv mechanism Feb 5 / 2026

// pc sends data -> sends that to imem to store -> then imem sends to decoder 

//PC updates (on clock edge)
//        ↓
//pc wire changes
//        ↓
//imem sees new addr
//        ↓
//instr wire changes
//        ↓
//decoder outputs change
//        ↓
//everything settles


// From the second update after I added ALU, regfile and the imm logic,
// firstly the program counter starts at 0 then points to imem,
// that at address 0 the machine code is 0000011012 etc. and that is the instruction which is returned by the imem.
// After that the instruction is sent to the decoder, which mainly returns rs1 and opcode respectively
// for regfile and ALU. the rs1 and rs2 are the register sources. Meanwhile the imm_gen extracts the constant number, the imm, from that instruction.
// Then the regfile takes the rs1 and rs2 and returns the values of those registers, rs1_val and rs2_val.
// Then the ALU takes the rs1_val and imm and returns the result of the operation.
// the always_comb block checks for the write enable safety switch. if the instruction is supposed to save a result.

// So, let's say the regfile give sthe value for rs1 as 5, and the imm generates the value as 10 so its sent to the ALU and ALU just does y = a + b
// which is 15 on the alu_out wire. The regfile then sees that we is 1
// so the switch for writing is on, it checks the value of alu_out and then it writes it into the rd, taking value from the wd. 
// which gives us dbg_x1 as 15. dbg_x2 and x3 are simply the other registers.


# CLOCK

↓
**PROGRAM COUNTER (PC)**
↓
**INSTRUCTION MEMORY**
↓
**DECODER**
↓
**REGISTER FILE**
↓
**ALU**
↓
**DATA MEMORY**
↓
**WRITE BACK TO REGISTERS**
↺
**PC gets updated → repeat**

---

## --- Feb 5 / 2026 ---

A simple program counter which returns `pc_out + 4`. As 32 bits = 4 bytes, and to move to the next instruction we need to add 4 to the program counter. A next slot in the memory. Then returns the bytes.

It is then sent to imem, let's say 8 is sent to imem. imem works like a lookup table, 256 slots and each slot is 32 bits wide. Now the program counter goes lie 0, 4, 8, 12.... and the imem needs index like 0, 1, 2, 3. So we divide the byte address by 4. the initial block in the imem sends signals to the ALU to addi.

---

## Instruction Breakdown

| The Hex | The Binary (Unpacked by Decoder) | What it means to the Hardware                |
| ------- | -------------------------------- | -------------------------------------------- |
| 003     | 0000 0000 0011                   | Immediate: The value 3.                      |
| 08      | 01000                            | rs1: Read from Register x1 (which holds 5).  |
| 1       | 001                              | funct3: Extra info for the ALU (000 = add).  |
| 1       | 00010                            | rd: Save the result in Register x2.          |
| 13      | 0010011                          | Opcode: "Hey! Use the ALU and an Immediate!" |

The imem assigns hex, the decoder unpacks the hex into binary, and the decoder sends the binary to the ALU.

After this, the regfile is the place where all the data lives while CPU is working.

---

## Component Flow (First Instruction)

**pc.sv (The Trigger):**
On the clock edge, the PC increments from 0 to 4, sending this address out on the pc wire.

**imem.sv (The Lookup):**
It receives the 4, divides it by 4 (to get index 1), and reflects the hex code `32'h00308113` onto the instr wire.

**decoder.sv (The Slicer):**
It instantly chops that hex code into pieces, identifying the opcode as `7'b0010011`, the source as `rs1=1`, and the destination as `rd=2`.

**imm_gen.sv (The Extractor):**
Simultaneously, it grabs the top 12 bits of the instruction and sign-extends them to create the 32-bit constant value 3.

**regfile.sv (The Retrieval):**
It looks at the rs1 wire (value 1), finds that Register 1 currently holds 5, and puts that 5 onto the rs1_val wire.

**alu.sv (The Calculation):**
It sees 5 from the Register File and 3 from the Immediate Generator and immediately outputs 8 onto the alu_out wire.

**cpu_top.sv (The Safety Check):**
The always_comb block sees the opcode `7'b0010011` and flips the reg_we (Write Enable) signal to 1.

**regfile.sv (The Conclusion):**
On the next rising clock edge, seeing that we is high, it pulls the 8 from the wd wire and permanently stores it into Register 2.

---

## Control Summary Table

| action               | Component               | Output Result                  |
| ------------------- | ----------------------- | ------------------------------ |
| Where to go?        | pc.sv                   | Address (e.g., 4)              |
| What to do?         | imem.sv                 | Instruction Hex Code           |
| Who is involved?    | decoder.sv              | Register IDs and Opcode        |
| What values?        | regfile.sv + imm_gen.sv | Raw Numbers (e.g., 5 and 3)    |
| What is the answer? | alu.sv                  | Calculated Result (e.g., 8)    |
| Save it?            | always_comb             | Write Enable Signal (High/Low) |

---

## If the address was something else, lets say 16

**pc.sv (The Trigger):**
The clock ticks, and the PC register updates to 16 (0001_0000 in binary).

**imem.sv (The Lookup):**
It takes the bits [9:2], which is 4, and looks into the array at mem[4]. Since nothing was put there in the initial block, it returns `32'h00000000` on the instr wire.

**decoder.sv (The Slicer):**
It rips the zero-instruction apart:

* Opcode: 0000000 (This is not a valid RISC-V addi opcode).
* rs1 / rd: Both become 0.

**imm_gen.sv (The Extractor):**
It sees all zeros and outputs a 32-bit immediate value of 0.

**regfile.sv (The Retrieval):**
It looks at rs1 (which is 0). Because of your `(rs1 == 0) ? 32'd0 : regs[rs1]` logic, it puts a 0 on the rs1_val wire.

**alu.sv (The Calculation):**
It sees 0 from the register file and 0 from the immediate generator. It outputs 0 on the alu_out wire.

**cpu_top.sv (The Safety Check):**
The always_comb block checks if the opcode is `7'b0010011`. Since the opcode is all zeros, it sets `reg_we = 1'b0`.

**regfile.sv (The Conclusion):**
On the next clock edge, it sees that we (Write Enable) is 0. It does nothing. No registers are updated, and no data is saved.

---

## But if it was 8, which exists in the imem

**pc.sv (The Trigger):**
The clock ticks, and the PC register now holds the value 8.

**imem.sv (The Lookup):**
It sees the 8, shifts it right by two (8 >> 2), finds index 2 in its internal memory, and sends out the hex `32'h00210193` on the instr wire.

**decoder.sv (The Slicer):**
It breaks the hex code into these signals:

* Opcode: 0010011 (It says: "I am an I-type math operation").
* rs1: 00010 (It says: "Go look at Register x2").
* rd: 00011 (It says: "The final answer goes into Register x3").

**imm_gen.sv (The Extractor):**
It pulls the number 2 out of the instruction bits and stretches it into a 32-bit constant.

**regfile.sv (The Retrieval):**
It looks inside Register x2 (which was updated to 8 in the previous clock cycle) and puts that 8 onto the rs1_val wire.

**alu.sv (The Calculation):**
It sees 8 (from the register) and 2 (from the immediate) on its input pins. It instantly outputs 10 on the alu_out wire.

**cpu_top.sv (The Safety Check):**
The always_comb block checks the opcode and flips the reg_we switch to 1 (Allow Writing).

**regfile.sv (The Conclusion):**
On the next rising clock edge, it sees the "Write" switch is on and saves the value 10 into the slot for Register x3.

---

## Execution Table

| Component | Input      | Action       | Output Signal          |
| --------- | ---------- | ------------ | ---------------------- |
| PC        | Clock Edge | Increment    | pc = 8                 |
| IMEM      | addr = 8   | Fetch mem[2] | instr = 32'h00210193   |
| Decoder   | instr      | Slice bits   | rs1=2, rd=3, opcode=19 |
| Regfile   | rs1=2      | Read regs[2] | rs1_val = 8            |
| ALU       | 8 + 2      | Addition     | alu_out = 10           |
| Control   | opcode=19  | Enable Write | reg_we = 1             |

---

## --- Feb 5 / 2026 ---

---

## --- Feb 12 / 2026 ---

## CPU Version 2.0: ALU Update

In this version the ALU has been updated to peform more arithmetic and logical tasks.

---

## New Component: The ALU Control Unit

The `alu_control_unit.sv` acts as the "Brain's Assistant." While the main Control Unit identifies the general instruction type, this unit looks at the specific `funct3` and `funct7` bits to decide the exact math operation.

| ALU_OP | Funct3 | Funct7 | Resulting ALU Action |
| --- | --- | --- | --- |
| `00` | XXX | XXXXXXX | **ADD** (For Loads/Stores) |
| `01` | XXX | XXXXXXX | **SUB** (For Branches) |
| `10` | `000` | `0000000` | **ADD** (Arithmetic) |
| `10` | `000` | `0100000` | **SUB** (Arithmetic) |
| `10` | `111` | `0000000` | **AND** |

---

## Instruction Breakdown (The New R-Type)

It now supports instructions that use two registers (`rs1` and `rs2`) instead of just an immediate value.

| Hex | Binary (Instruction Bits) | Hardware Meaning |
| --- | --- | --- |
| **002** | `0000000` | **funct7**: Addition mode. |
| **08** | `01000` | **rs2**: Read from Register x2. |
| **01** | `01000` | **rs1**: Read from Register x1. |
| **0** | `000` | **funct3**: Standard Add. |
| **0B** | `00011` | **rd**: Save result in Register x3. |
| **33** | `0110011` | **Opcode**: "Hey! This is an R-Type (Register-to-Register) math op!" |

---

## Component Flow: Execution of `add x3, x1, x2`

**1. pc.sv (The Trigger)**
The PC hits `8`.

**2. imem.sv (The Fetch)**
Fetches `32'h002081B3` from memory. It strips the bottom bits to find index `2` in the array.

**3. decoder.sv (The Slicer)**
Identifies the Opcode as `7'b0110011`. It tells the system: "We need two registers, x1 and x2, and we are aiming for x3."

**4. control_unit.sv (The Manager)**
Sees the R-Type opcode. It sets `alu_src = 0` (selecting the register value instead of an immediate) and `reg_we = 1`.

**5. alu_control_unit.sv (The Specialist)**
Combines the `alu_op` from the manager with `funct3` and `funct7`. It outputs `4'b0000` to tell the ALU to perform an Addition.

**6. alu.sv (The Calculation)**
Takes the value from x1 (5) and x2 (10) and produces the sum: **15**.

**7. regfile.sv (The Storage)**
On the next clock tick, it sees `we` is high and captures the 15, storing it into the x3 slot.

---

## Expanded Instruction Support Table

The ALU now handles 14 distinct operations based on the 4-bit `alu_control` signal:

| Control Code | Operation | Usage Example |
| --- | --- | --- |
| `4'b0000` | **ADD** | `addi x1, x0, 5` |
| `4'b0001` | **SUB** | `sub x4, x1, x2` |
| `4'b0010` | **AND** | `and x5, x1, x2` |
| `4'b0101` | **SLL** (Shift Left) | Logical bit shifting |
| `4'b1000` | **SLT** (Set Less Than) | Comparison for sorting/logic |
| `4'b1010` | **EQ** | Checks if `a == b` |

---

## Current Test Suite (Pre-loaded in `imem`)

The CPU currently executes the following sequence upon reset:

1. `addi x1, x0, 5` → **x1 = 5**
2. `addi x2, x1, 3` → **x2 = 8**
3. `add x3, x1, x2` → **x3 = 13**
4. `sub x4, x1, x2` → **x4 = -3**

---

## -- Feb 12 / 2026 --

## -- Feb 16 / 2026 --


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
```

---

## -- Feb 16 / 2026 --