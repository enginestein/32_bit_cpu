module trap (
    input  logic        trap,
    input  logic [3:0]  trap_cause,
    input  logic        irq,
    input  logic [31:0] mtvec,
    input  logic [31:0] mepc_in, 
    output logic [31:0] pc_next,       
    input  logic [31:0] pc_normal_next,
    output logic        take_trap,      
    output logic [31:0] mcause_out,  
    output logic        csr_trap_write 
);

    always_comb begin
        if (irq) begin
            take_trap     = 1'b1;
            pc_next       = mtvec;
            mcause_out    = 32'h8000_000B;
            csr_trap_write = 1'b1;
        end else if (trap) begin
            take_trap     = 1'b1;
            pc_next       = mtvec;
            mcause_out    = {28'b0, trap_cause};
            csr_trap_write = 1'b1;
        end else begin
            take_trap     = 1'b0;
            pc_next       = pc_normal_next;
            mcause_out    = 32'd0;
            csr_trap_write = 1'b0;
        end
    end

endmodule