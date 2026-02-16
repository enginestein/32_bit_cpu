/* verilator lint_off UNOPTFLAT */

module tb_control_unit;

    logic [6:0] opcode;
    logic reg_we, alu_src, mem_we, mem_re, mem_to_reg, branch;
    logic [1:0] alu_op;

    control_unit dut (
        .opcode(opcode),
        .reg_we(reg_we),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_we(mem_we),
        .mem_re(mem_re),
        .mem_to_reg(mem_to_reg),
        .branch(branch)
    );

    initial begin

        // R-type
        opcode = 7'b0110011;
        assert(reg_we == 1 && alu_op == 2'b10);

        // LW
        opcode = 7'b0000011;
        assert(mem_re == 1 && mem_to_reg == 1);

        // SW
        opcode = 7'b0100011;
        assert(mem_we == 1);

        // Branch
        opcode = 7'b1100011;
        assert(branch == 1);

        $display("CONTROL UNIT TEST COMPLETE");
        $finish;
    end

endmodule
