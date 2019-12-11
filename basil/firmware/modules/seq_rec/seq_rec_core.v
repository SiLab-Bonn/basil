/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

// WARNING! THIS MODULE IS WORK IN PROGRESS! NOT TESTED!
/*
 * Possible extra options:
 * - delay block that allow SEQ_EXT_START in past (enabled by parameter - for speed needed applications a simple memory circular buffer)
 * - SEQ_EXT_START selections as pulse or as gate/enable
 * - multi window recording (sorted with but multiple times)
 */

module seq_rec_core #(
    parameter MEM_BYTES = 2*1024,
    parameter ABUSWIDTH = 16,
    parameter IN_BITS = 8

) (
    BUS_CLK,
    BUS_RST,
    BUS_ADD,
    BUS_DATA_IN,
    BUS_RD,
    BUS_WR,
    BUS_DATA_OUT,

    SEQ_CLK,
    SEQ_IN,
    SEQ_EXT_START
);

localparam VERSION = 0;

input wire                      BUS_CLK;
input wire                      BUS_RST;
input wire     [ABUSWIDTH-1:0]  BUS_ADD;
input wire     [7:0]            BUS_DATA_IN;
input wire                      BUS_RD;
input wire                      BUS_WR;
output reg     [7:0]            BUS_DATA_OUT;

input wire SEQ_CLK;
input wire [IN_BITS-1:0] SEQ_IN;
input wire SEQ_EXT_START;

generate
if (MEM_BYTES > 2048*8*4) begin
    illegal_outputs_parameter non_existing_module();
end
endgenerate

`include "../includes/log2func.v"

localparam ADDR_SIZEA = `CLOG2(MEM_BYTES);
localparam ADDR_SIZEB = (IN_BITS > 8) ? `CLOG2(MEM_BYTES/(IN_BITS/8)) : `CLOG2(MEM_BYTES*(8/IN_BITS));

reg [7:0] status_regs [4:0];

wire RST;
wire SOFT_RST;

assign RST = BUS_RST || SOFT_RST;

localparam DEF_BIT_OUT = MEM_BYTES;

always @(posedge BUS_CLK) begin
    if (RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 0;
        status_regs[3] <= DEF_BIT_OUT[7:0]; //bits
        status_regs[4] <= DEF_BIT_OUT[15:8]; //bits
    end else if (BUS_WR && BUS_ADD < 5) begin
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
    end
end

reg [7:0] BUS_IN_MEM;
reg [7:0] BUS_OUT_MEM;

// 1 - finished

wire CONF_START;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign CONF_START = (BUS_ADD==1 && BUS_WR);

wire [15:0] CONF_COUNT;
assign CONF_COUNT = {status_regs[4], status_regs[3]};

wire CONF_EN_EXT_START;
assign CONF_EN_EXT_START = status_regs[2][0];

reg CONF_READY;

wire [7:0] BUS_STATUS_OUT;
assign BUS_STATUS_OUT = status_regs[BUS_ADD[3:0]];

reg [7:0] BUS_DATA_OUT_REG;
always @(posedge BUS_CLK) begin
    if (BUS_RD)
    begin
        if (BUS_ADD == 0)
            BUS_DATA_OUT_REG <= VERSION;
        else if (BUS_ADD == 1)
            BUS_DATA_OUT_REG <= {7'b0, CONF_READY};
        else if (BUS_ADD == 2)
            BUS_DATA_OUT_REG <= {7'b0, CONF_EN_EXT_START};
        else if (BUS_ADD < 5)
            BUS_DATA_OUT <= status_regs[BUS_ADD[3:0]];
        else if (BUS_ADD < 16)
            BUS_DATA_OUT <= 8'b0;
    end
end

wire CONF_EN_EXT_START_SYNC;
flag_domain_crossing conf_en_ext_start_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(SEQ_CLK),
    .FLAG_IN_CLK_A(CONF_EN_EXT_START),
    .FLAG_OUT_CLK_B(CONF_EN_EXT_START_SYNC)
);

reg [ABUSWIDTH-1:0]  PREV_BUS_ADD;
always @(posedge BUS_CLK) begin
    if (BUS_RD) begin
        PREV_BUS_ADD <= BUS_ADD;
    end
end

always @(*) begin
    if (PREV_BUS_ADD < 16)
        BUS_DATA_OUT = BUS_DATA_OUT_REG;
    else if (PREV_BUS_ADD < 16 + MEM_BYTES)
        BUS_DATA_OUT = BUS_IN_MEM;
    else
        BUS_DATA_OUT = 8'b0;
end

reg [16:0] out_bit_cnt;

wire [ADDR_SIZEB-1:0] memout_addrb;
assign memout_addrb = out_bit_cnt - 1;

wire [ADDR_SIZEA-1:0] memout_addra;
wire [ABUSWIDTH-1:0] BUS_ADD_MEM;
assign BUS_ADD_MEM = BUS_ADD-16;

localparam IN_BYTES = IN_BITS/8;
localparam IN_BYTES_WIDTH = `CLOG2(IN_BYTES);

generate
    if (IN_BITS<=8) begin
        assign memout_addra = BUS_ADD_MEM;
    end else begin
        assign memout_addra = {BUS_ADD_MEM[ADDR_SIZEA:IN_BYTES_WIDTH], {(IN_BYTES_WIDTH){1'b0}}} + (IN_BYTES-1) - BUS_ADD_MEM[IN_BYTES_WIDTH-1:0]; //Byte order
    end
endgenerate

reg [IN_BITS-1:0] SEQ_IN_MEM;

wire WEA, WEB;
assign WEA = BUS_WR && BUS_ADD >=16 && BUS_ADD < 16 + MEM_BYTES && !WEB;

generate
    if (IN_BITS==8) begin
        (* RAM_STYLE="{BLOCK}" *)
        reg [7:0] mem [(2**ADDR_SIZEA)-1:0];


        // synthesis translate_off
        //to make simulator happy (no X propagation)
        integer i;
        initial
            for(i = 0; i < (2**ADDR_SIZEA); i = i + 1)
                mem[i] = 0;
        // synthesis translate_on

        always @(posedge BUS_CLK) begin
            if (WEA)
                mem[memout_addra] <= BUS_DATA_IN;
            BUS_IN_MEM <= mem[memout_addra];
        end

        always @(posedge SEQ_CLK)
            if (WEB)
                mem[memout_addrb] <= SEQ_IN;

    end else begin
        wire [7:0] douta;

        seq_rec_blk_mem memout (
            .clka(BUS_CLK),
            .clkb(SEQ_CLK),
            .douta(douta),
            .doutb(),
            .wea(WEA),
            .web(WEB),
            .addra(memout_addra),
            .addrb(memout_addrb),
            .dina(BUS_DATA_IN),
            .dinb(SEQ_IN)
        );
        always @(*) begin
            BUS_IN_MEM = douta;
        end

    end
endgenerate

assign WEB = out_bit_cnt != 0;

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (
    .clk_in(BUS_CLK),
    .pulse_in(RST),
    .clk_out(SEQ_CLK),
    .pulse_out(RST_SOFT_SYNC)
);
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire CONF_START_FLAG_SYNC;
flag_domain_crossing conf_start_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(SEQ_CLK),
    .FLAG_IN_CLK_A(CONF_START),
    .FLAG_OUT_CLK_B(CONF_START_FLAG_SYNC)
);

wire [15:0] CONF_COUNT_SYNC;
three_stage_synchronizer #(
    .WIDTH(16)
) three_stage_conf_count_synchronizer (
    .CLK(SEQ_CLK),
    .IN(CONF_COUNT),
    .OUT(CONF_COUNT_SYNC)
);
wire [16:0] STOP_BIT;
assign STOP_BIT = {1'b0, CONF_COUNT_SYNC};

wire START_REC;
assign START_REC = CONF_START_FLAG_SYNC | (CONF_EN_EXT_START_SYNC & SEQ_EXT_START);

always @(posedge SEQ_CLK)
    if (RST_SYNC)
        out_bit_cnt <= 0;
    else if (START_REC && DONE)
        out_bit_cnt <= 1;
    else if (out_bit_cnt == STOP_BIT)
        out_bit_cnt <= 0;
    else if (out_bit_cnt != 0)
        out_bit_cnt <= out_bit_cnt + 1;

reg DONE;
always @(posedge SEQ_CLK)
    if (RST_SYNC)
        DONE <= 1'b1;
    else
        if (START_REC && DONE)
            DONE <= 1'b0;
        else if (out_bit_cnt == 0)
            DONE <= 1'b1;

wire START_REC_FLAG_BUS_CLK;
cdc_pulse_sync start_pulse_sync (
    .clk_in(SEQ_CLK),
    .pulse_in(START_REC),
    .clk_out(BUS_CLK),
    .pulse_out(START_REC_FLAG_BUS_CLK)
);

wire DONE_FLAG_BUS_CLK;
cdc_pulse_sync done_pulse_sync (
    .clk_in(SEQ_CLK),
    .pulse_in(DONE),
    .clk_out(BUS_CLK),
    .pulse_out(DONE_FLAG_BUS_CLK)
);

always @(posedge BUS_CLK)
    if (RST)
        CONF_READY <= 1'b1;
    else if (START_REC_FLAG_BUS_CLK || CONF_START)
        CONF_READY <= 1'b0;
    else if (DONE_FLAG_BUS_CLK)
        CONF_READY <= 1'b1;


endmodule
