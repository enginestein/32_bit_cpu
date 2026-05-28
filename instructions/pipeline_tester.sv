module instruction_input_memory (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] mem [0:255];

    initial begin

        mem[ 0] = 32'h00100093; // addi x1, x0, 1
        mem[ 1] = 32'h00200113; // addi x2, x0, 2
        mem[ 2] = 32'h00300193; // addi x3, x0, 3

        mem[ 3] = 32'h00208233; // add  x4, x1, x2       EX forwarding: x4=3

        mem[ 4] = 32'h00120293; // addi x5, x4, 1        chained fwd: x5=4
        mem[ 5] = 32'h00228313; // addi x6, x5, 2        chained fwd: x6=6

        mem[ 6] = 32'h00102023; // sw   x1, 0(x0)        store 1 to dmem[0]
        mem[ 7] = 32'h00002383; // lw   x7, 0(x0)        LOAD-USE HAZARD: x7=1
        mem[ 8] = 32'h00738433; // add  x8, x7, x7       must stall: x8=2

        mem[ 9] = 32'h003104B3; // add  x9, x2, x3       x9=5

        mem[10] = 32'h00108463; // beq  x1, x1, +8       taken: skip mem[11,12]
        mem[11] = 32'h06400513; // addi x10, x0, 100     MUST BE FLUSHED
        mem[12] = 32'h06400513; // addi x10, x0, 100     MUST BE FLUSHED
        mem[13] = 32'h00000013; // nop

        mem[14] = 32'h00208063; // beq  x1, x2, +0       not taken (1!=2)
        mem[15] = 32'h06300593; // addi x11, x0, 99      must execute: x11=99

        mem[16] = 32'hF0000637; // lui  x12, 0xF0000     x12 = 0xF0000000
        mem[17] = 32'h04F00693; // addi x13, x0, 79      'O'
        mem[18] = 32'h00D62023; // sw   x13, 0(x12)      UART: 'O'
        mem[19] = 32'h04B00693; // addi x13, x0, 75      'K'
        mem[20] = 32'h00D62023; // sw   x13, 0(x12)      UART: 'K'
        mem[21] = 32'h00A00693; // addi x13, x0, 10      '\n'
        mem[22] = 32'h00D62023; // sw   x13, 0(x12)      UART: '\n'

        mem[23] = 32'h02310733; // mul  x14, x2, x3      muldiv stall: x14=6
        mem[24] = 32'h00070793; // addi x15, x14, 0      forwarded from muldiv: x15=6

        mem[25] = 32'h0000006F; // jal  x0, 0            halt

    end

    assign instr = mem[addr[9:2]];
endmodule