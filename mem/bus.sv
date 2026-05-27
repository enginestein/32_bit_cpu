/*

- Memory Bus -

Determines if the operation has to go into dmem or uart.

    Address map:
      0x0000_0000 – 0xEFFF_FFFF   SRAM / dmem
      0xF000_0xxx                  UART    (addr[31:20] == 12'hF00)
      0xF001_0xxx                  PLIC    (addr[31:12] == 20'hF001_0)


*/

module bus (
    input  logic        clk,
    input  logic        reset,
 
    input  logic        we,
    input  logic        re,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic [31:0] funct3,
    output logic [31:0] rdata,
    output logic        misaligned,
 
    // dmem
    output logic        dmem_we,
    output logic        dmem_re,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,
    input  logic        dmem_misaligned,
 
    // uart
    output logic        uart_cs,
    output logic        uart_we,
    output logic [31:0] uart_addr,
    output logic [31:0] uart_wdata,
    input  logic [31:0] uart_rdata,
 
    // plic
    output logic        plic_cs,
    output logic        plic_we,
    output logic [31:0] plic_addr,
    output logic [31:0] plic_wdata,
    input  logic [31:0] plic_rdata
);
 
    wire is_uart = (addr[31:20] == 12'hF00);          // 0xF000_0xxx
    wire is_plic = (addr[31:12] == 20'hF0010);        // 0xF001_0xxx
    wire is_ram  = ~is_uart & ~is_plic;
 
    // dmem
    assign dmem_we    = we && is_ram;
    assign dmem_re    = re && is_ram;
    assign dmem_addr  = addr;
    assign dmem_wdata = wdata;
 
    // uart
    assign uart_cs    = (we || re) && is_uart;
    assign uart_we    = we && is_uart;
    assign uart_addr  = addr;
    assign uart_wdata = wdata;
 
    // plic
    assign plic_cs    = (we || re) && is_plic;
    assign plic_we    = we && is_plic;
    assign plic_addr  = addr;
    assign plic_wdata = wdata;
 
    // read mux
    always_comb begin
        if (is_uart)
            rdata = uart_rdata;
        else if (is_plic)
            rdata = plic_rdata;
        else
            rdata = dmem_rdata;
    end
 
    assign misaligned = dmem_misaligned && is_ram;
 
endmodule