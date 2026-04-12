/*

- Memory Bus -

Determines if the operation has to go into dmem or uart.

*/

module bus (
    input logic clk,
    input logic reset,

    input logic we,
    input logic re,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic [31:0] funct3,
    output logic [31:0] rdata,
    output logic misaligned,
    output logic dmem_we,
    output logic dmem_re,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input logic [31:0] dmem_rdata,
    input logic dmem_misaligned,
    output logic uart_cs,
    output logic uart_we,
    output logic [31:0] uart_addr,
    output logic [31:0] uart_wdata,
    input logic [31:0] uart_rdata
);

wire is_uart = (addr[31:20] == 12'hF00); // 0xF000_0000 - UART address.
wire is_ram = ~is_uart; // ~ turns 0 into 1 and 1 into 0, useful enough.

assign dmem_we = we && is_ram;
assign dmem_re = re && is_ram;
assign dmem_addr = addr;
assign dmem_wdata = wdata;

assign uart_cs = (we || re) && is_uart; // if either we or re and uart is high
assign uart_we = we && is_uart;
assign uart_addr = addr;
assign uart_wdata = wdata;

always_comb begin 

    if (is_uart)
        rdata = uart_rdata;
    else 
        rdata = dmem_rdata;

end

assign misaligned = dmem_misaligned && is_ram;

endmodule