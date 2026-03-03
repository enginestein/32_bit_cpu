/* verilator lint_off UNOPTFLAT */

module tb_alu;

    logic [31:0] a, b;
    logic [4:0]  alu_control;
    logic [31:0] y;

    alu dut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .y(y)
    );

    task check(input [31:0] expected);
        if (y !== expected) begin
            $display("❌ FAIL: a=%0d b=%0d ctrl=%b → got=%0d expected=%0d",
                      a, b, alu_control, y, expected);
            $fatal;
        end
        else begin
            $display("✅ PASS");
        end
    endtask

initial begin
    // ADD
    a = 10; b = 5; alu_control = 5'b00000;
    check(15);

    // SUB
    alu_control = 5'b00001;
    check(5);

    // AND
    a = 32'hF0F0; b = 32'h0FF0; alu_control = 5'b00010;
    check(a & b);

    // OR
    alu_control = 5'b00011;
    check(a | b);

    // SLT
    a = -1; b = 1; alu_control = 5'b10000;
    check(1);

    $display("ALU TEST COMPLETE");
    $finish;
end


endmodule
