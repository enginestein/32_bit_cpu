
/* verilator lint_off STMTDLY */
/* verilator lint_off UNOPTFLAT */

module tb_alu_control_unit;

    logic [1:0] alu_op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] alu_control;

    alu_control_unit dut (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_control)
    );

    initial begin

        // R-type ADD
        alu_op  = 2'b10;
        funct3  = 3'b000;
        funct7  = 7'b0000000;
        #1;
        assert(alu_control == 5'b00000);

        // R-type SUB
        funct7 = 7'b0100000;
        #1;
        assert(alu_control == 5'b00001);

        // AND
        funct3 = 3'b111;
        #1;
        assert(alu_control == 5'b00010);

        // SRL
        funct3 = 3'b101;
        funct7 = 7'b0000000;
        #1;
        assert(alu_control == 5'b00110);

        $display("ALU CONTROL TEST COMPLETE");
        $finish;
    end


endmodule
