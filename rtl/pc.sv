// Program Counter (PC) Module
// This holds the memory address of the next instructino, represented by numbers here 1-4
// This module increments the program counter by 4 on each clock cycle.
// It resets to 0 when the reset signal is high.
// The limit of the pc_out is 32 bits.

module pc (
    input logic clk, 
    input logic reset, 
    output logic [31:0] pc_out
); 

    always_ff @(posedge clk) begin 
        if (reset)
            pc_out <= 32'd0;
        else 
            pc_out <= pc_out + 32'd4; // 32'd4 = 4
    end

endmodule