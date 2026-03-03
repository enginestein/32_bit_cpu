module trap(
    input  logic        trap,
    input  logic [31:0] mtvec,
    input  logic [31:0] pc_normal_next,
    output logic [31:0] pc_next
);

always_comb begin
    if (trap)
        pc_next = mtvec;
    else
        pc_next = pc_normal_next;
end

endmodule
