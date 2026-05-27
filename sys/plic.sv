module plic (
    input  logic        clk,
    input  logic        reset,
    // interrupt sources (one bit per peripheral)
    input  logic [2:0]  irq_src,     // [0]=uart_tx, [1]=uart_rx, [2]=timer
    // claim/complete from CPU (memory-mapped registers)
    input  logic        cs,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    // output to CPU
    output logic        irq_pending  // HIGH = at least one unmasked IRQ
);
    logic [2:0] pending_reg;
    logic [2:0] mask_reg;     // software-writable enable mask

    always_ff @(posedge clk) begin
        if (reset) begin
            pending_reg <= 3'd0;
            mask_reg    <= 3'd0;
        end else begin
            // latch rising edges from sources
            pending_reg <= pending_reg | irq_src;
            // claim: CPU writes source bit to clear it
            if (cs && we && addr[3:2] == 2'b01)
                pending_reg <= pending_reg & ~wdata[2:0];
            // mask register at offset 0x00
            if (cs && we && addr[3:2] == 2'b00)
                mask_reg <= wdata[2:0];
        end
    end

    assign irq_pending = |(pending_reg & mask_reg);

    always_comb begin
        rdata = 32'd0;
        if (cs && !we) begin
            case (addr[3:2])
                2'b00: rdata = {29'd0, mask_reg};
                2'b01: rdata = {29'd0, pending_reg};
                default: rdata = 32'd0;
            endcase
        end
    end
endmodule