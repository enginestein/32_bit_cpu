module hazard_unit (
    input  logic        id_ex_mem_re,
    input  logic [4:0]  id_ex_rd,
    input  logic [4:0]  if_id_rs1,
    input  logic [4:0]  if_id_rs2,

    input  logic [4:0]  ex_mem_rd,
    input  logic        ex_mem_reg_we,
    input  logic [31:0] ex_mem_alu_out,

    input  logic [4:0]  mem_wb_rd,
    input  logic        mem_wb_reg_we,
    input  logic [31:0] mem_wb_writeback,

    input  logic [4:0]  id_ex_rs1,
    input  logic [4:0]  id_ex_rs2,

    output logic        stall,
    output logic        if_id_flush,
    output logic        id_ex_flush,

    output logic [1:0]  forward_a,
    output logic [1:0]  forward_b
);

    always_comb begin
        stall       = 1'b0;
        if_id_flush = 1'b0;
        id_ex_flush = 1'b0;

        if (id_ex_mem_re &&
            id_ex_rd != 5'd0 &&
            (id_ex_rd == if_id_rs1 || id_ex_rd == if_id_rs2)) begin
            stall       = 1'b1;
            if_id_flush = 1'b0;
            id_ex_flush = 1'b1;
        end
    end

    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (ex_mem_reg_we &&
            ex_mem_rd != 5'd0 &&
            ex_mem_rd == id_ex_rs1)
            forward_a = 2'b10;

        if (mem_wb_reg_we &&
            mem_wb_rd != 5'd0 &&
            !(ex_mem_reg_we && ex_mem_rd != 5'd0 && ex_mem_rd == id_ex_rs1) &&
            mem_wb_rd == id_ex_rs1)
            forward_a = 2'b01;

        if (ex_mem_reg_we &&
            ex_mem_rd != 5'd0 &&
            ex_mem_rd == id_ex_rs2)
            forward_b = 2'b10;

        if (mem_wb_reg_we &&
            mem_wb_rd != 5'd0 &&
            !(ex_mem_reg_we && ex_mem_rd != 5'd0 && ex_mem_rd == id_ex_rs2) &&
            mem_wb_rd == id_ex_rs2)
            forward_b = 2'b01;
    end

endmodule