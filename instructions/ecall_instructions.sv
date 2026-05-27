module instruction_input_memory (
    input  logic [31:0] addr,
    output logic [31:0] instr
);


    logic [31:0] mem [0:255];

    initial begin
        //  Computes sum of 1..10, stores to dmem[0], then ECALL
        //
        //  x1 = i (counter)
        //  x2 = sum (accumulator)
        //  x3 = limit (10)
        //
        //  PC 0x00:  addi x1, x0, 0       i = 0
        //  PC 0x04:  addi x2, x0, 0       sum = 0
        //  PC 0x08:  addi x3, x0, 10      limit = 10
        //  PC 0x0C:  addi x1, x1, 1       loop: i++
        //  PC 0x10:  add  x2, x2, x1      sum += i
        //  PC 0x14:  blt  x1, x3, -8      if i < 10 goto loop
        //  PC 0x18:  sw   x2, 0(x0)       mem[0] = sum (55)
        //  PC 0x1C:  ecall                exit

        mem[0] = 32'h00000093; // addi x1, x0, 0
        mem[1] = 32'h00000113; // addi x2, x0, 0
        mem[2] = 32'h00A00193; // addi x3, x0, 10
        mem[3] = 32'h00108093; // addi x1, x1, 1 
        mem[4] = 32'h00110133; // add  x2, x2, x1
        mem[5] = 32'hFE30CCE3; // blt x1, x3, -8
        mem[6] = 32'h00202023; // sw   x2, 0(x0)
        mem[7] = 32'h00000073; // ecall
    end

    assign instr = mem[addr[9:2]];

endmodule
