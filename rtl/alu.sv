// simple alu, only adds for now

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);

    assign y = a + b; 

endmodule
