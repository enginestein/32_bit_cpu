/*
    - Multi-Cycle Multiply / Divide Unit -

    Handles the RISC-V M-extension operations that are too expensive for a
    single-cycle ALU path:

        MUL / MULH / MULHSU / MULHU   (MUL_CYCLES latency)
        DIV / DIVU / REM  / REMU      (DIV_CYCLES latency)

    Interface
    ---------
    start  : pulse high for exactly ONE cycle to begin an operation.
             Ignored while busy is high.
    op     : alu_control encoding (must be stable while start is high)
    a, b   : operands (must be stable while start is high)
    ready  : pulses HIGH for exactly one cycle when the result is valid.
    result : valid on the cycle ready is high, then holds until next start.

    Latency parameters can be tuned without changing any other file.
*/

module muldiv_unit (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [4:0]  op,
    output logic [31:0] result,
    output logic        ready
);

/* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off BLKSEQ */

    // ---------- tuneable latencies ----------
    localparam int MUL_CYCLES = 3;   // cycles to complete a multiply
    localparam int DIV_CYCLES = 8;   // cycles to complete a divide / remainder
    // ----------------------------------------

    logic [5:0]  counter;
    logic [5:0]  target;
    logic        busy;

    // latch inputs so the rest of the datapath is free to move on
    logic [31:0] a_r, b_r;
    logic [4:0]  op_r;

    // ---------- combinatorial result from latched operands ----------
    logic [31:0] computed;

    always_comb begin
        case (op_r)
            5'b01110: computed = a_r * b_r;                                          // MUL
            5'b01111: computed = ($signed(a_r) * $signed(b_r)) >>> 32;               // MULH
            5'b10000: computed = ($signed(a_r) * b_r)          >>> 32;               // MULHSU
            5'b10001: computed = (a_r           * b_r)          >>> 32;               // MULHU
            5'b10010: computed = (b_r != 0) ? ($signed(a_r) / $signed(b_r))
                                            : 32'hFFFF_FFFF;                          // DIV
            5'b10011: computed = (b_r != 0) ? (a_r / b_r)
                                            : 32'hFFFF_FFFF;                          // DIVU
            5'b10100: computed = (b_r != 0) ? ($signed(a_r) % $signed(b_r))
                                            : a_r;                                    // REM
            5'b10101: computed = (b_r != 0) ? (a_r % b_r)
                                            : a_r;                                    // REMU
            default:  computed = 32'd0;
        endcase
    end

    // ---------- cycle-counter state machine ----------
    always_ff @(posedge clk) begin
        if (reset) begin
            busy    <= 1'b0;
            counter <= 6'd0;
            target  <= 6'd0;
            ready   <= 1'b0;
            result  <= 32'd0;
            a_r     <= 32'd0;
            b_r     <= 32'd0;
            op_r    <= 5'd0;
        end else begin
            ready <= 1'b0; // default: deasserted every cycle

            if (start && !busy) begin
                // latch inputs and begin countdown
                a_r     <= a;
                b_r     <= b;
                op_r    <= op;
                busy    <= 1'b1;
                counter <= 6'd1;
                target  <= (op == 5'b10010 || op == 5'b10011 ||
                            op == 5'b10100 || op == 5'b10101)
                           ? DIV_CYCLES[5:0]
                           : MUL_CYCLES[5:0];

            end else if (busy) begin
                if (counter >= target) begin
                    // operation complete
                    result  <= computed;
                    ready   <= 1'b1;
                    busy    <= 1'b0;
                    counter <= 6'd0;
                end else begin
                    counter <= counter + 6'd1;
                end
            end
        end
    end

endmodule
