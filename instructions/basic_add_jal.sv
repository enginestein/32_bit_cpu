// handles the program which has to run

module instruction_input_memory (
    input logic [31:0] addr, // the address of the instruction
    output logic [31:0] instr // the 32 bit instruction, which is returned
);

    /* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off BLKSEQ */

    logic [31:0] mem [0:255]; // this is the storage of memory, has 256 slots, and each slot is 32 bits wide. It can hold 256 instructions.

    initial begin
        mem[0] = 32'h00500093; // addi x1, x0, 5
        mem[1] = 32'h008002EF; // jal  x5, func (pc+8)
        mem[2] = 32'h0000006F; // jal  x0, 0 (loop forever)
        mem[3] = 32'h00A08093; // addi x1, x1, 10
        mem[4] = 32'h00028067; // jalr x0, x5, 0 (return)
    end


    // in 32 bit systems, instructions are 4 bytes long, so each instruction takes 4 bytes. here mem[0] is on address 0, but mem[1] is on address 4 and mem[2] is on address 8.
    // so as the instruction is 4 bytes long, the end of it's binary address is with 00. so we're simply stripping off the last two 0s in this code.
    // this simply divides the address by 4. This is the bit shift, shifting right side by two places.
    // 9 is the ceiling because from n power of 2, the maximum it could go is 8. 8 bits, but only for the 256 slots we assigned.
    assign instr = mem[addr[9:2]]; // finally assigning the output instruction which was 32 bits wide, 

endmodule
