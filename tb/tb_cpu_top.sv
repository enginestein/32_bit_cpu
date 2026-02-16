/* verilator lint_off UNOPTFLAT */
/* verilator lint_off STMTDLY */

module tb_cpu_top;

    logic clk;
    logic reset;
    logic [31:0] pc_dbg;
    logic [31:0] x1, x2, x3;

    cpu_top dut (
        .clk(clk),
        .reset(reset),
        .pc_dbg(pc_dbg),
        .dbg_x1(x1),
        .dbg_x2(x2),
        .dbg_x3(x3)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        #10;
        reset = 0;

        // Let program run 20 cycles
        #200;

        $display("FINAL STATE:");
        $display("x1 = %0d", x1);
        $display("x2 = %0d", x2);
        $display("x3 = %0d", x3);

        $finish;
    end

endmodule
