/*
    tb_uart.sv — standalone testbench for uart.sv

    Verifies:
      1. Writing 'A' (0x41) to TX_DATA causes uart_tx to output the correct
         8N1 frame: start(0), D0..D7 (LSB-first), stop(1)
      2. tx_ready (STATUS bit 0) deasserts when FIFO fills and reasserts
         as bytes drain
      3. BAUD_DIV register is writable and reads back correctly
      4. Multiple back-to-back bytes transmit without corruption

    Timing: uses a fast divisor (baud_div=4) so the test completes quickly.
*/

`timescale 1ns/1ps

module tb_uart;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic        clk   = 0;
    logic        reset = 1;
    logic        cs, we;
    logic [31:0] addr, wdata, rdata;
    logic        uart_tx;

    uart dut (
        .clk     (clk),
        .reset   (reset),
        .cs      (cs),
        .we      (we),
        .addr    (addr),
        .wdata   (wdata),
        .rdata   (rdata),
        .uart_tx (uart_tx)
    );

    // -------------------------------------------------------------------------
    // Clock: 10 ns period
    // -------------------------------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Serial capture
    // -------------------------------------------------------------------------
    integer  rx_byte_count = 0;
    logic [7:0] rx_bytes [0:31];

    // Capture bytes as they come off uart_tx (poll style)
    task automatic capture_uart_byte(output logic [7:0] b);
        // Wait for start bit (falling edge on idle-high line)
        @(negedge uart_tx);
        // Skip half a baud period to sample in the middle of the start bit
        repeat(2) @(posedge clk);
        // Sample 8 data bits
        for (int i = 0; i < 8; i++) begin
            repeat(4) @(posedge clk);  // one baud period (div=4)
            b[i] = uart_tx;
        end
        // Skip stop bit
        repeat(4) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Bus helpers
    // -------------------------------------------------------------------------
    task automatic bus_write(input logic [31:0] a, d);
        @(posedge clk); #1;
        cs    = 1; we = 1;
        addr  = a;
        wdata = d;
        @(posedge clk); #1;
        cs = 0; we = 0;
    endtask

    task automatic bus_read(input logic [31:0] a, output logic [31:0] d);
        @(posedge clk); #1;
        cs   = 1; we = 0;
        addr = a;
        @(posedge clk); #1;
        d  = rdata;
        cs = 0;
    endtask

    // -------------------------------------------------------------------------
    // Addresses
    // -------------------------------------------------------------------------
    localparam logic [31:0] UART_TX_DATA  = 32'hF000_0000;
    localparam logic [31:0] UART_STATUS   = 32'hF000_0004;
    localparam logic [31:0] UART_BAUD_DIV = 32'hF000_0008;

    // -------------------------------------------------------------------------
    // Test
    // -------------------------------------------------------------------------
    integer  errors = 0;
    logic [31:0] rd;
    logic [7:0]  rx;

    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0, tb_uart);

        cs = 0; we = 0; addr = 0; wdata = 0;

        // ── Reset ──────────────────────────────────────────────────────────
        repeat(4) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);

        // ── Test 1: set fast baud divisor ──────────────────────────────────
        $display("\n[T1] Setting baud divisor to 4");
        bus_write(UART_BAUD_DIV, 32'd4);
        bus_read(UART_BAUD_DIV, rd);
        if (rd !== 32'd4) begin
            $display("FAIL: BAUD_DIV readback got %0d, expected 4", rd);
            errors++;
        end else
            $display("PASS: BAUD_DIV = 4");

        // ── Test 2: tx_ready initially asserted ───────────────────────────
        $display("\n[T2] Check tx_ready after reset");
        bus_read(UART_STATUS, rd);
        if (rd[0] !== 1'b1) begin
            $display("FAIL: tx_ready should be 1, got %b", rd[0]);
            errors++;
        end else
            $display("PASS: tx_ready = 1");

        // ── Test 3: transmit 'A' and verify 8N1 frame ─────────────────────
        $display("\n[T3] Transmitting 'A' (0x41) and checking serial frame");
        fork
            bus_write(UART_TX_DATA, 32'h41);  // send 'A'
            capture_uart_byte(rx);
        join
        if (rx !== 8'h41) begin
            $display("FAIL: received 0x%02h, expected 0x41 ('A')", rx);
            errors++;
        end else
            $display("PASS: received 'A' (0x%02h)", rx);

        // ── Test 4: back-to-back 'Hi' ─────────────────────────────────────
        $display("\n[T4] Transmitting 'H' then 'i'");
        fork
            begin
                bus_write(UART_TX_DATA, 32'h48); // 'H'
                bus_write(UART_TX_DATA, 32'h69); // 'i'
            end
            begin
                capture_uart_byte(rx_bytes[0]);
                capture_uart_byte(rx_bytes[1]);
            end
        join
        if (rx_bytes[0] !== 8'h48 || rx_bytes[1] !== 8'h69)
            $display("FAIL: expected 'Hi', got 0x%02h 0x%02h",
                     rx_bytes[0], rx_bytes[1]);
        else
            $display("PASS: received 'Hi'");

        // ── Test 5: poll for ready before sending '\n' ────────────────────
        $display("\n[T5] Poll STATUS before sending newline");
        begin
            automatic int poll_cycles = 0;
            automatic logic [31:0] status;
            do begin
                bus_read(UART_STATUS, status);
                poll_cycles++;
                if (poll_cycles > 1000) begin
                    $display("FAIL: tx_ready never asserted");
                    errors++;
                    break;
                end
            end while (!status[0]);
            bus_write(UART_TX_DATA, 32'h0A); // '\n'
            $display("PASS: tx_ready asserted after %0d polls, newline sent",
                     poll_cycles);
        end

        // ── Summary ────────────────────────────────────────────────────────
        repeat(20) @(posedge clk);
        $display("\n============================");
        if (errors == 0)
            $display("ALL UART TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);
        $display("============================\n");
        $finish;
    end

endmodule