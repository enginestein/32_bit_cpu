// the special file where the outputs from the decoder are sent.

module regfile (
    input logic clk,
    input logic we, // safety switch write enable, 0 or 1.

    input logic [4:0] rs1, // decoder sends rs1 and rs2, the numbers CPU has to grab and send to ALU.
    input logic [4:0] rs2,
    input logic [4:0] rd, // recieved by the decoder
    input logic [31:0] wd, // comes from the ALU, is 32 bit. write data.
    output logic [31:0] rd1,
    output logic [31:0] rd2,
    output logic [31:0] dbg_x1,
    output logic [31:0] dbg_x2,
    output logic [31:0] dbg_x3
);

    logic [31:0] regs [0:31]; // 32 registers, each 32 bits wide

    // 32'd0 = 32 bit wide decimal zero

    assign rd1 = (rs1 == 0) ? 32'd0 : regs[rs1]; // checks if the given register is zero, if yes, then it returns 32 bit wide zero, else it returns the value of the register.
    assign rd2 = (rs2 == 0) ? 32'd0 : regs[rs2];
    assign dbg_x1 = regs[1];
    assign dbg_x2 = regs[2];
    assign dbg_x3 = regs[3];

    always_ff @(posedge clk) begin // waiting for the clock, only then we right. so that the voltage gets on 1.
        if (we && rd != 0)
            regs[rd] <= wd;
    end

endmodule