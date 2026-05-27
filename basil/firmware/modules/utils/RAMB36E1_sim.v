`timescale 1ps/1ps
`default_nettype none

module RAMB36E1 #(
    parameter DO_REG = 0,
    parameter WRITE_MODE = "WRITE_FIRST"
) (
    input wire CLKARDCLK,
    input wire CLKBWRCLK,
    input wire ENARDEN,
    input wire ENBWREN,
    input wire REGCEB,
    input wire RSTRAMARSTRAM,
    input wire RSTRAMB,
    input wire RSTREGARSTREG,
    input wire RSTREGB,
    input wire [14:0] ADDRARDADDR,
    input wire [14:0] ADDRBWRADDR,
    input wire [31:0] DIADI,
    input wire [3:0] DIPADIP,
    input wire [31:0] DIBDI,
    input wire [3:0] DIPBDIP,
    input wire [3:0] WEA,
    input wire [3:0] WEB,
    output reg [31:0] DOADO,
    output reg [3:0] DOPADOP,
    output reg [31:0] DOBDO,
    output reg [3:0] DOPBDOP
);

reg [31:0] mem [0:1023];
reg [3:0] mem_p [0:1023];

reg [31:0] do_b_mid;
reg [3:0] dop_b_mid;

wire [9:0] wr_addr = ADDRARDADDR[9:0];
wire [9:0] rd_addr = ADDRBWRADDR[9:0];

wire same_addr_collision = (ENARDEN && (|WEA) && (wr_addr == rd_addr));

always @(posedge CLKARDCLK) begin
    if (ENARDEN) begin
        if (WEA[0]) mem[wr_addr][7:0] <= DIADI[7:0];
        if (WEA[1]) mem[wr_addr][15:8] <= DIADI[15:8];
        if (WEA[2]) mem[wr_addr][23:16] <= DIADI[23:16];
        if (WEA[3]) mem[wr_addr][31:24] <= DIADI[31:24];
        if (&WEA) mem_p[wr_addr] <= DIPADIP;
    end
end

generate
    if (DO_REG == 0) begin : gen_do_reg0
        always @(posedge CLKBWRCLK) begin
            if (ENBWREN) begin
                if (same_addr_collision && (WRITE_MODE == "WRITE_FIRST")) begin
                    DOBDO <= DIADI;
                    DOPBDOP <= DIPADIP;
                end else begin
                    DOBDO <= mem[rd_addr];
                    DOPBDOP <= mem_p[rd_addr];
                end
            end
        end
    end else begin : gen_do_reg1
        always @(posedge CLKBWRCLK) begin
            if (ENBWREN) begin
                if (same_addr_collision && (WRITE_MODE == "WRITE_FIRST")) begin
                    do_b_mid <= DIADI;
                    dop_b_mid <= DIPADIP;
                end else begin
                    do_b_mid <= mem[rd_addr];
                    dop_b_mid <= mem_p[rd_addr];
                end
            end
        end
        always @(posedge CLKBWRCLK) begin
            if (REGCEB) begin
                DOBDO <= do_b_mid;
                DOPBDOP <= dop_b_mid;
            end
        end
    end
endgenerate

endmodule
