---

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

| ction               | Component               | Output Result                  |
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
