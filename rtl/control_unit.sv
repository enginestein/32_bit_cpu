module control_unit  (
    input logic [6:0] opcode,
    output logic reg_we,
    output logic alu_src,
    output logic [1:0] alu_op
);

    always_comb begin 
        reg_we = 0;
        alu_src = 0;
        alu_op = 2'b00;

        case (opcode) 
           7'b0110011: begin
                reg_we = 1;
                alu_src = 0;
                alu_op = 2'b10;
            end
            7'b0010011: begin
                reg_we = 1;
                alu_op = 2'b10;
                alu_src = 1;
            end
        
            default: begin

            end
        endcase
    end

endmodule