module uart (
    input logic clk,
    input logic we,
    input logic [31:0] wdata
);

always_ff @(posedge clk) begin
    if (we) begin
        $write("%c", wdata[7:0]);
    end
end

endmodule