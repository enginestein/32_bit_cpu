/* 

- UART -

UART module used for tx and rx to communicate with external devices.

*/

module uart (
    input logic clk,
    input logic reset,

    input logic cs,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    output logic [31:0] rdata,

    output logic uart_tx
);

localparam int FIFO_DEPTH = 16;

logic [31:0] baud_div;
logic [31:0] baud_cnt;
logic baud_tick;

//initial baud_div = 32'd868; // 115200 baud @ 100 MHz used by microcontrollers generally(?)

// reset checker

always_ff @(posedge clk) begin
    if (reset) begin
        baud_cnt <= baud_div;
        baud_tick <= 1'b0;
    end else begin
        if (baud_cnt == 32'd0) begin
            baud_cnt <= baud_div;
            baud_tick <= 1'b1;
        end else begin
            baud_cnt <= baud_cnt - 1;
            baud_tick <= 1'b0;
        end
    end
end

// tx fifo

logic [7:0] fifo [0:FIFO_DEPTH-1];
logic [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
logic [$clog2(FIFO_DEPTH):0] fifo_count;

wire fifo_empty = (fifo_count == 0);
wire fifo_full = (fifo_count == FIFO_DEPTH[($clog2(FIFO_DEPTH)):0]);      

logic fifo_write;
logic fifo_read;

always_ff @(posedge clk) begin
    if (reset) begin
        wr_ptr <= '0;
        rd_ptr <= '0;
        fifo_count <= '0;
    end else begin
        case ({fifo_write & ~fifo_full, fifo_read & ~fifo_empty})
                2'b10: begin  // push only
                    fifo[wr_ptr] <= wdata[7:0];
                    wr_ptr       <= wr_ptr + 1;
                    fifo_count   <= fifo_count + 1;
                end
                2'b01: begin  // pop only
                    rd_ptr     <= rd_ptr + 1;
                    fifo_count <= fifo_count - 1;
                end
                2'b11: begin  // simultaneous push + pop
                    fifo[wr_ptr] <= wdata[7:0];
                    wr_ptr       <= wr_ptr + 1;
                    rd_ptr       <= rd_ptr + 1;
                    // count unchanged
                end
                default:;
        endcase
    end
end

// tx state register (transmitter)

typedef enum logic [1:0] {IDLE, START, DATA, STOP} tx_state_t;

tx_state_t tx_state;
logic [7:0] tx_shift;
logic [2:0] bit_cnt;

assign fifo_read = (tx_state == IDLE) && !fifo_empty && baud_tick;

always_ff @(posedge clk) begin
    if (reset) begin
        tx_state <= IDLE;
        tx_shift <= 8'hFF;
        bit_cnt <= 3'd0;
        uart_tx <= 1'b1;
    end else begin
        case (tx_state)
 
                IDLE: begin
                    uart_tx <= 1'b1;
                    if (!fifo_empty && baud_tick) begin
                        tx_shift <= fifo[rd_ptr];  // latch byte
                        tx_state <= START;
                    end
                end
 
                START: begin
                    if (baud_tick) begin
                        uart_tx  <= 1'b0;  // start bit
                        tx_state <= DATA;
                        bit_cnt  <= 3'd0;
                    end
                end
 
                DATA: begin
                    if (baud_tick) begin
                        uart_tx  <= tx_shift[0];
                        tx_shift <= {1'b1, tx_shift[7:1]};  // LSB first
                        if (bit_cnt == 3'd7)
                            tx_state <= STOP;
                        else
                            bit_cnt <= bit_cnt + 1;
                    end
                end
 
                STOP: begin
                    if (baud_tick) begin
                        uart_tx  <= 1'b1;  // stop bit
                        tx_state <= IDLE;
                    end
                end
 
        endcase
    end
end

wire tx_ready = ~fifo_full;
 
assign fifo_write = cs && we && (addr[3:2] == 2'b00);
 
always_comb begin
    rdata = 32'd0;
    if (cs && !we) begin
        case (addr[3:2])
            2'b01:   rdata = {31'd0, tx_ready};   // STATUS
            2'b10:   rdata = baud_div;             // BAUD_DIV read-back
            default: rdata = 32'd0;
        endcase
    end
end
 
always_ff @(posedge clk) begin
    if (reset)
        baud_div <= 32'd868;
    else if (cs && we && addr[3:2] == 2'b10)
        baud_div <= wdata;
end

endmodule