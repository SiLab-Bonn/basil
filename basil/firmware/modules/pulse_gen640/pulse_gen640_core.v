/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module pulse_gen640_core
#(
    parameter ABUSWIDTH = 16,
    parameter CLKDV = 4, //only 4 will work for now
    parameter OUTPUT_SIZE =2 
)
(
    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    
    input wire PULSE_CLK,
    input wire PULSE_CLK160,
    input wire PULSE_CLK320,
    input wire EXT_START,
    output wire [OUTPUT_SIZE-1:0] PULSE,
    output wire DEBUG
);

localparam VERSION = 1;

wire SOFT_RST;
wire START;
reg CONF_EN;
reg [31:0] CONF_DELAY;
reg [31:0] CONF_WIDTH;
reg [31:0] CONF_REPEAT;
//reg [CLKDV*4-1:0] CONF_PHASE;
reg [15:0] CONF_PHASE;
reg CONF_DONE;

always@(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= {7'b0, CONF_DONE};
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= {7'b0, CONF_EN};
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= CONF_DELAY[7:0];
        else if(BUS_ADD == 4)
            BUS_DATA_OUT <= CONF_DELAY[15:8];
        else if(BUS_ADD == 5)
            BUS_DATA_OUT <= CONF_DELAY[23:16];
        else if(BUS_ADD == 6)
            BUS_DATA_OUT <= CONF_DELAY[31:24];
        else if(BUS_ADD == 7)
            BUS_DATA_OUT <= CONF_WIDTH[7:0];
        else if(BUS_ADD == 8)
            BUS_DATA_OUT <= CONF_WIDTH[15:8];
        else if(BUS_ADD == 9)
            BUS_DATA_OUT <= CONF_WIDTH[23:16];
        else if(BUS_ADD == 10)
            BUS_DATA_OUT <= CONF_WIDTH[31:24];
        else if(BUS_ADD == 11)
            BUS_DATA_OUT <= CONF_REPEAT[7:0];
        else if(BUS_ADD == 12)
            BUS_DATA_OUT <= CONF_REPEAT[15:8];
        else if(BUS_ADD == 13)
            BUS_DATA_OUT <= CONF_REPEAT[23:16];
        else if(BUS_ADD == 14)
            BUS_DATA_OUT <= CONF_REPEAT[31:24];
        else if(BUS_ADD == 15)
            BUS_DATA_OUT <= CONF_PHASE[7:0];
        else if(BUS_ADD == 16)
            BUS_DATA_OUT <= CONF_PHASE[15:8];
        // debug
        else if(BUS_ADD == 17)
            BUS_DATA_OUT <= CNT[7:0];
        else if(BUS_ADD == 18)
            BUS_DATA_OUT <= CNT[15:8];
        else if(BUS_ADD == 19)
            BUS_DATA_OUT <= CNT[23:16];
        else if(BUS_ADD == 20)
            BUS_DATA_OUT <= CNT[31:24];
        else if(BUS_ADD == 21)
            BUS_DATA_OUT <= {6'b0,PULSE_REF, CNT[32]};
        else
            BUS_DATA_OUT <= 8'b0;
    end
end

assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST;

always @(posedge BUS_CLK) begin
    if(RST) begin
        CONF_EN <= 0;
        CONF_DELAY <= 0;
        CONF_WIDTH <= 0;
        CONF_REPEAT <= 1;
    end
    else if(BUS_WR) begin
        if(BUS_ADD == 2)
            CONF_EN <= BUS_DATA_IN[0];
        else if(BUS_ADD == 3)
            CONF_DELAY[7:0] <= BUS_DATA_IN;
        else if(BUS_ADD == 4)
            CONF_DELAY[15:8] <= BUS_DATA_IN;
        else if(BUS_ADD == 5)
            CONF_DELAY[23:16] <= BUS_DATA_IN;
        else if(BUS_ADD == 6)
            CONF_DELAY[31:24] <= BUS_DATA_IN;
        else if(BUS_ADD == 7)
            CONF_WIDTH[7:0] <= BUS_DATA_IN;
        else if(BUS_ADD == 8)
            CONF_WIDTH[15:8] <= BUS_DATA_IN;
        else if(BUS_ADD == 9)
            CONF_WIDTH[23:16] <= BUS_DATA_IN;
        else if(BUS_ADD == 10)
            CONF_WIDTH[31:24] <= BUS_DATA_IN;
        else if(BUS_ADD == 11)
            CONF_REPEAT[7:0] <= BUS_DATA_IN;
        else if(BUS_ADD == 12)
            CONF_REPEAT[15:8] <= BUS_DATA_IN;
        else if(BUS_ADD == 13)
            CONF_REPEAT[23:16] <= BUS_DATA_IN;
        else if(BUS_ADD == 14)
            CONF_REPEAT[31:24] <= BUS_DATA_IN;
        else if(BUS_ADD == 15)
            CONF_PHASE[7:0] <= BUS_DATA_IN;
        else if(BUS_ADD == 16)
            CONF_PHASE[15:8] <= BUS_DATA_IN;
    end
end

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(PULSE_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;


wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(PULSE_CLK), .pulse_out(START_SYNC));

wire EXT_START_SYNC;
reg [2:0] EXT_START_FF;
always @(posedge PULSE_CLK) // first stage
begin
    EXT_START_FF[0] <= EXT_START;
    EXT_START_FF[1] <= EXT_START_FF[0];
    EXT_START_FF[2] <= EXT_START_FF[1];
end

assign EXT_START_SYNC = !EXT_START_FF[2] & EXT_START_FF[1];

reg [31:0] CNT;
wire [32:0] LAST_CNT;
assign LAST_CNT = CONF_DELAY + CONF_WIDTH;

reg [31:0] REAPAT_CNT;

always @ (posedge PULSE_CLK) begin
    if (RST_SYNC)
        REAPAT_CNT <= 0;
    else if(START_SYNC || (EXT_START_SYNC && CONF_EN))
        REAPAT_CNT <= CONF_REPEAT;
    else if(REAPAT_CNT != 0 && CNT == 1)
        REAPAT_CNT <= REAPAT_CNT - 1;
end

always @ (posedge PULSE_CLK) begin
    if (RST_SYNC)
        CNT <= 0; //IS THIS RIGHT?
    else if(START_SYNC || (EXT_START_SYNC && CONF_EN))
        CNT <= 1;
    else if(CNT == LAST_CNT && REAPAT_CNT != 0)
        CNT <= 1;
    else if(CNT == LAST_CNT && CONF_REPEAT==0)
        CNT <= 1;
    else if(CNT == LAST_CNT && REAPAT_CNT == 0)
        CNT <= 0;
    else if(CNT != 0)
        CNT <= CNT + 1;
end

reg [CLKDV*4-1:0] PULSE_DES;
reg PULSE_REF;
always @ (posedge PULSE_CLK) begin
    if(RST_SYNC || START_SYNC || (EXT_START_SYNC && CONF_EN)) begin
        PULSE_DES <= 0;
        PULSE_REF<=0;
    end
    else if(CNT == CONF_DELAY && CNT > 0) begin
        PULSE_REF<=1;
        PULSE_DES <= CONF_PHASE;
    end
    else if(CNT == CONF_DELAY+1) begin
        PULSE_DES <= 16'b1111111111111111;
        PULSE_REF<=1;
    end
    else if(CNT == LAST_CNT) begin
        PULSE_DES <= 0;
        PULSE_REF<=0;
    end
end
assign DEBUG = PULSE_REF;
wire PULSE_CLK_PULSE;
reg [1:0] PULSE_CLK_FF;

always @ (posedge PULSE_CLK160)
    PULSE_CLK_FF[1:0] <= {PULSE_CLK_FF[0],PULSE_CLK};
assign PULSE_CLK_PULSE = PULSE_CLK & ~PULSE_CLK_FF[0];

reg [CLKDV*4-1:0] PULSE_DES_DIV;
always @ (negedge PULSE_CLK160) begin
    if(RST_SYNC || START_SYNC || (EXT_START_SYNC && CONF_EN))
        PULSE_DES_DIV <= 0;
    else if (PULSE_CLK_PULSE==1)
        PULSE_DES_DIV <= PULSE_DES;
    else
        PULSE_DES_DIV[CLKDV*4-2:0] <= {PULSE_DES_DIV[CLKDV*4-1],PULSE_DES_DIV[CLKDV*4-1],
                                       PULSE_DES_DIV[CLKDV*4-1],PULSE_DES_DIV[CLKDV*4-1:4]};
end

genvar i;
generate
for (i=0; i<2; i=i+1) begin
    OSERDESE2 # (
        .DATA_RATE_OQ("DDR"),
        .DATA_WIDTH(4),
        .SERDES_MODE("MASTER")
    ) i_OSERDESE2_0 (
        .OQ(PULSE[i]),
        .OFB(),
        .TQ(),
        .TFB(),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .CLK(PULSE_CLK320),
        .CLKDIV(PULSE_CLK160),
        .D1(PULSE_DES_DIV[0]),
        .D2(PULSE_DES_DIV[1]),
        .D3(PULSE_DES_DIV[2]),
        .D4(PULSE_DES_DIV[3]),
        .D5(),
        .D6(),
        .D7(),
        .D8(),
        .TCE(0),
        .OCE(1),
        .TBYTEIN(),
        .TBYTEOUT(),
        .RST(RST_SYNC),
        .SHIFTIN1(),
        .SHIFTIN2(),
        .T1(0),
        .T2(0),
        .T3(0),
        .T4(0)
    );
end
endgenerate

wire DONE;
assign DONE = (CNT == 0);

wire DONE_SYNC;
cdc_pulse_sync done_pulse_sync (.clk_in(PULSE_CLK), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));

wire EXT_START_SYNC_BUS;
cdc_pulse_sync ex_start_pulse_sync (.clk_in(PULSE_CLK), .pulse_in(EXT_START && CONF_EN), .clk_out(BUS_CLK), .pulse_out(EXT_START_SYNC_BUS));

always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(START || EXT_START_SYNC_BUS)
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;

endmodule
