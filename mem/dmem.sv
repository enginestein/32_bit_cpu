/*

    - Data Memory - 

    This file helps in storing and loading data from the memory. it checks for misaligned data
    as well by checking the address and the funct3 value.

*/

module dmem (
    input  logic        clk,
    input  logic        we,
    input  logic        re,
    input  logic [31:0] addr,
    input  logic [31:0] wd,
    input  logic [2:0]  funct3,
    output logic [31:0] rd,
    output logic misaligned
);
    /* verilator lint_off CASEINCOMPLETE */


    parameter RAM_SIZE = 32 * 1024 * 1024; // 32 MB
    logic [1:0] mem_size; // 00 = byte, 01 = half, 10 = word
    logic mem_signed; // 1 = signed load, 0 = unsigned load
    logic [7:0] mem [0:RAM_SIZE-1];
    localparam ADDR_WIDTH = $clog2(RAM_SIZE); // how many digits my ram needs

    logic [ADDR_WIDTH-1:0] a; // creates a sized wire for that width

    assign a = addr[ADDR_WIDTH-1:0]; // chop off extra bits

    always_comb begin
        mem_size   = 2'b00;
        mem_signed = 1'b0;

        case (funct3)
            3'b000: mem_size = 2'b00; // LB / SB
            3'b001: mem_size = 2'b01; // LH / SH
            3'b010: mem_size = 2'b10; // LW / SW
            3'b100: mem_size = 2'b00; // LBU
            3'b101: mem_size = 2'b01; // LHU
        endcase

        if (re) begin
            case (funct3)
                3'b000, 3'b001, 3'b010: mem_signed = 1'b1; // LB/LH/LW
                default:                mem_signed = 1'b0; // LBU/LHU
            endcase
        end
    end 

    logic misaligned_d;

    always_comb begin 
        misaligned_d = 1'b0;

        if (we || re) begin
            case (mem_size)
                2'b01: if (addr[0]   != 1'b0) misaligned_d= 1'b1;   // half
                2'b10: if (addr[1:0] != 2'b00) misaligned_d = 1'b1;  // word
                default: misaligned_d = 1'b0;                        // byte
            endcase
        end
    end

    always_ff @(posedge clk) begin
        misaligned <= misaligned_d;
    end


    always_ff @(posedge clk) begin
        if (we && !misaligned) begin
            case (mem_size)


                2'b00: begin // byte
                    mem[a] <= wd[7:0];
                end

                2'b01: begin // half
                    mem[a]     <= wd[7:0];
                    mem[a + 1] <= wd[15:8];
                end

                2'b10: begin // word
                    mem[a]     <= wd[7:0];
                    mem[a + 1] <= wd[15:8];
                    mem[a + 2] <= wd[23:16];
                    mem[a + 3] <= wd[31:24];
                end

            endcase
        end
    end


    logic [31:0] load_data;

    always_comb begin
        load_data = 32'b0;

        case (mem_size)

            2'b00: load_data = {24'b0, mem[a]};

            2'b01: load_data = {16'b0, mem[a+1], mem[a]};

            2'b10: load_data = {mem[a+3], mem[a+2],
                                mem[a+1], mem[a]};

        endcase
    end

    always_comb begin
        rd = 32'b0;

        if (re && !misaligned) begin
            case (mem_size)

                2'b00: rd = mem_signed ?
                            {{24{load_data[7]}},  load_data[7:0]}  :
                            {24'b0,               load_data[7:0]};

                2'b01: rd = mem_signed ?
                            {{16{load_data[15]}}, load_data[15:0]} :
                            {16'b0,               load_data[15:0]};

                2'b10: rd = load_data; // word always full 32 bits

            endcase
        end
    end

    endmodule
