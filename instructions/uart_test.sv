module instruction_input_memory (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

logic [31:0] mem [0:255];

initial begin

    // ===============================
    // BASIC REGISTER INIT
    // ===============================
    mem[0]  = 32'h00500093; // addi x1, x0, 5
    mem[1]  = 32'h00A00113; // addi x2, x0, 10

    // ===============================
    // UART TEST
    // Load base address 0xF000_0000 into x10 via LUI
    // ===============================
    mem[2]  = 32'hF0000537; // lui  x10, 0xF0000      → x10 = 0xF000_0000

    mem[3]  = 32'h04800593; // addi x11, x0, 72       → x11 = 'H' (0x48)
    mem[4]  = 32'h00B52023; // sw   x11, 0(x10)       → UART TX: write 'H'

    mem[5]  = 32'h06900593; // addi x11, x0, 105      → x11 = 'i' (0x69)
    mem[6]  = 32'h00B52023; // sw   x11, 0(x10)       → UART TX: write 'i'

    mem[7]  = 32'h00A00593; // addi x11, x0, 10       → x11 = '\n' (0x0A)
    mem[8]  = 32'h00B52023; // sw   x11, 0(x10)       → UART TX: write '\n'

    // ===============================
    // READ UART STATUS (addr+4 = 0xF000_0004)
    // ===============================
    mem[9]  = 32'h00452603; // lw   x12, 4(x10)       → x12 = UART status (tx_ready)

    // ===============================
    // HALT — infinite self-loop
    // ===============================
    mem[10] = 32'h0000006F; // jal  x0, 0             → PC stays here forever

end

assign instr = mem[addr[9:2]];

endmodule