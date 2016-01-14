/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module spi_core
#(
    parameter ABUSWIDTH = 16,
    parameter MEM_BYTES = 16
)(
    input wire                      BUS_CLK,
    input wire                      BUS_RST,
    input wire     [ABUSWIDTH-1:0]  BUS_ADD,
    input wire     [7:0]            BUS_DATA_IN,
    input wire                      BUS_RD,
    input wire                      BUS_WR,
    output reg [7:0]                BUS_DATA_OUT,
    
    input wire SPI_CLK,
    
    output wire SCLK,
    input wire SDO,
    output reg SDI,
    input wire EXT_START,
    
    output reg SEN,
    output reg SLD
);

localparam VERSION = 2;

reg [7:0] status_regs [15:0];

wire RST;
wire SOFT_RST;

assign RST = BUS_RST || SOFT_RST;

localparam DEF_BIT_OUT = 8*MEM_BYTES;

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 0;
        status_regs[3] <= DEF_BIT_OUT[7:0]; //bits
        status_regs[4] <= DEF_BIT_OUT[15:8]; //bits
        status_regs[5] <= 4; //wait
        status_regs[6] <= 0; //wait
        status_regs[7] <= 0; //wait
        status_regs[8] <= 0; //wait
        status_regs[9] <= 1; //repeat
        status_regs[10] <= 0; //repeat
        status_regs[11] <= 0; //repeat
        status_regs[12] <= 0; //repeat
        status_regs[13] <= 0; //0:enable external start
    end
    else if(BUS_WR && BUS_ADD < 16)
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
end

reg [7:0] BUS_IN_MEM;
reg [7:0] BUS_OUT_MEM;

wire START;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

wire [15:0] CONF_BIT_OUT;
assign CONF_BIT_OUT = {status_regs[4],status_regs[3]};

// TODO: not yet used
wire [7:0] CONF_CLK_DIV;
assign CONF_CLK_DIV = status_regs[2];
reg CONF_DONE;

wire [31:0] CONF_WAIT;
assign CONF_WAIT = {status_regs[8], status_regs[7], status_regs[6], status_regs[5]};

wire [31:0] CONF_REPEAT;
assign CONF_REPEAT = {status_regs[12], status_regs[11], status_regs[10], status_regs[9]};

wire CONF_EN;
assign CONF_EN = status_regs[13][0];

reg [7:0] BUS_DATA_OUT_REG;
always@(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT_REG <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT_REG <= {7'b0, CONF_DONE};
         else if(BUS_ADD == 13)
            BUS_DATA_OUT_REG <= {7'b0, CONF_EN};
        else if(BUS_ADD == 14)
            BUS_DATA_OUT_REG <= MEM_BYTES[7:0];
        else if(BUS_ADD == 15)
            BUS_DATA_OUT_REG <= MEM_BYTES[15:8];
        else if (BUS_ADD < 16)
            BUS_DATA_OUT_REG <= status_regs[BUS_ADD[3:0]];
    end
end

// if one has a synchronous memory need this to give data on next clock after read
// limitation: this module still needs to be addressed
reg [ABUSWIDTH-1:0]  PREV_BUS_ADD;
always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        PREV_BUS_ADD <= BUS_ADD;
    end
end

always @(*) begin
    if(PREV_BUS_ADD < 16)
        BUS_DATA_OUT = BUS_DATA_OUT_REG;
    else if(PREV_BUS_ADD < 16+MEM_BYTES)
        BUS_DATA_OUT = BUS_IN_MEM;
    else if(PREV_BUS_ADD < 16+MEM_BYTES+MEM_BYTES)
        BUS_DATA_OUT = BUS_OUT_MEM;
    else
        BUS_DATA_OUT = 8'hxx;
end

reg [32:0] out_bit_cnt;


wire [13:0] memout_addrb;
assign memout_addrb = out_bit_cnt;
wire [10:0] memout_addra;
assign memout_addra = (BUS_ADD-16);

reg [7:0] BUS_DATA_IN_IB;
wire [7:0] BUS_IN_MEM_IB;
wire [7:0] BUS_OUT_MEM_IB;
integer i;
always @(*) begin
    for(i=0;i<8;i=i+1) begin
        BUS_DATA_IN_IB[i] = BUS_DATA_IN[7-i];
        BUS_IN_MEM[i] = BUS_IN_MEM_IB[7-i];
        BUS_OUT_MEM[i] = BUS_OUT_MEM_IB[7-i];
    end
end

wire SDI_MEM;

blk_mem_gen_8_to_1_2k memout(
    .CLKA(BUS_CLK),
    .CLKB(SPI_CLK),
    .DOUTA(BUS_IN_MEM_IB),
    .DOUTB(SDI_MEM),
    .WEA(BUS_WR && BUS_ADD >=16 && BUS_ADD < 16+MEM_BYTES),
    .WEB(1'b0),
    .ADDRA(memout_addra),
    .ADDRB(memout_addrb),
    .DINA(BUS_DATA_IN_IB),
    .DINB(1'b0)
);


wire [10:0] ADDRA_MIN;
assign ADDRA_MIN = (BUS_ADD-16-MEM_BYTES);
wire [13:0] ADDRB_MIN;
assign ADDRB_MIN = out_bit_cnt-1;
reg SEN_INT;

blk_mem_gen_8_to_1_2k memin(
    .CLKA(BUS_CLK),
    .CLKB(SPI_CLK),
    .DOUTA(BUS_OUT_MEM_IB),
    .DOUTB(),
    .WEA(1'b0),
    .WEB(SEN_INT),
    .ADDRA(ADDRA_MIN),
    .ADDRB(ADDRB_MIN),
    .DINA(BUS_DATA_IN_IB),
    .DINB(SDO)
);

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(SPI_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(SPI_CLK), .pulse_out(START_SYNC));

wire EXT_START_PULSE;
reg [2:0] EXT_START_FF;
always @(posedge SPI_CLK) // first stage
begin
    EXT_START_FF[0] <= EXT_START;
    EXT_START_FF[1] <= EXT_START_FF[0];
    EXT_START_FF[2] <= EXT_START_FF[1];
end
assign EXT_START_PULSE = !EXT_START_FF[2] & EXT_START_FF[1];

wire [32:0] STOP_BIT;
assign STOP_BIT = CONF_BIT_OUT + CONF_WAIT;
reg [31:0] REPEAT_COUNT;

wire REP_START;
assign REP_START = (out_bit_cnt == STOP_BIT && (CONF_REPEAT==0 || REPEAT_COUNT < CONF_REPEAT));

reg REP_START_DLY;
always @ (posedge SPI_CLK)
    REP_START_DLY <= REP_START;
 
always @ (posedge SPI_CLK)
    if (RST_SYNC)
        SEN_INT <= 0;
    else if(START_SYNC || (EXT_START_PULSE && CONF_EN) || REP_START_DLY)
        SEN_INT <= 1;
    else if(out_bit_cnt == CONF_BIT_OUT)
        SEN_INT <= 0;

always @ (posedge SPI_CLK)
    if (RST_SYNC)
        out_bit_cnt <= 0;
    else if(START_SYNC || (EXT_START_PULSE && CONF_EN))
        out_bit_cnt <= 1;
    else if(out_bit_cnt == STOP_BIT)
        out_bit_cnt <= 0;
    //else if(out_bit_cnt == CONF_BIT_OUT & REPEAT_COUNT == CONF_REPEAT & CONF_REPEAT!=0)
    //    out_bit_cnt <= 0;
    else if(REP_START_DLY)
        out_bit_cnt <= 1;
    else if(out_bit_cnt != 0)
        out_bit_cnt <= out_bit_cnt + 1;

always @ (posedge SPI_CLK)
    if (RST_SYNC || START_SYNC || (EXT_START_PULSE && CONF_EN))
        REPEAT_COUNT <= 1;
    else if(out_bit_cnt == STOP_BIT)
        REPEAT_COUNT <= REPEAT_COUNT + 1;


reg [1:0] sync_ld;
always @(posedge SPI_CLK) begin
    sync_ld[0] <= SEN_INT;
    sync_ld[1] <= sync_ld[0];
end

always @(posedge SPI_CLK)
    SLD <= (sync_ld[1]==1 && sync_ld[0]==0);

wire DONE = out_bit_cnt == STOP_BIT && REPEAT_COUNT >= CONF_REPEAT;
wire DONE_SYNC, EXT_START_PULSE_SYNC;
cdc_pulse_sync done_pulse_sync (.clk_in(SPI_CLK), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));
cdc_pulse_sync done_pulse_ext_start (.clk_in(SPI_CLK), .pulse_in(EXT_START_PULSE), .clk_out(BUS_CLK), .pulse_out(EXT_START_PULSE_SYNC));

always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(START || (EXT_START_PULSE_SYNC && CONF_EN))
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;

CG_MOD_pos icg2(.ck_in(SPI_CLK), .enable(SEN), .ck_out(SCLK));

always @(negedge SPI_CLK)
    SDI <= SDI_MEM & SEN_INT;

always @(negedge SPI_CLK)
    SEN <= SEN_INT;

endmodule
