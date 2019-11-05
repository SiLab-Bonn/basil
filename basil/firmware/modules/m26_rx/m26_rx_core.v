/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module m26_rx_core
#(
    parameter ABUSWIDTH = 16,
    parameter HEADER = 0,
    parameter IDENTYFIER = 0
)(
    input wire CLK_RX,
    input wire MKD_RX,
    input wire [1:0] DATA_RX,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    input wire [31:0] TIMESTAMP,

    output wire LOST_ERROR
);

localparam VERSION = 2;

//output format #ID (as parameter IDENTYFIER + 1 frame start + 16 bit data)

// writing to register 0 asserts soft reset
wire SOFT_RST;
assign SOFT_RST = (BUS_ADD == 0 && BUS_WR);

// reset sync
reg SOFT_RST_FF, SOFT_RST_FF2, BUS_RST_FF, BUS_RST_FF2;
always @(posedge BUS_CLK) begin
    SOFT_RST_FF <= SOFT_RST;
    SOFT_RST_FF2 <= SOFT_RST_FF;
    BUS_RST_FF <= BUS_RST;
    BUS_RST_FF2 <= BUS_RST_FF;
end

wire SOFT_RST_FLAG;
assign SOFT_RST_FLAG = ~SOFT_RST_FF2 & SOFT_RST_FF;
wire BUS_RST_FLAG;
assign BUS_RST_FLAG = BUS_RST_FF2 & ~BUS_RST_FF; // trailing edge
wire RST;
assign RST = BUS_RST_FLAG | SOFT_RST_FLAG;

wire RST_SYNC;
flag_domain_crossing rst_flag_domain_crossing_clk_rx (
    .CLK_A(BUS_CLK),
    .CLK_B(CLK_RX),
    .FLAG_IN_CLK_A(RST),
    .FLAG_OUT_CLK_B(RST_SYNC)
);

// registers
reg [7:0] status_regs [1:0];

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 8'b0000_0010;
    end
    else if(BUS_WR && BUS_ADD < 2)
        status_regs[BUS_ADD[0]] <= BUS_DATA_IN;
end

wire CONF_EN;
assign CONF_EN = status_regs[1][0];
wire CONF_TIMESTAMP_HEADER;
assign CONF_TIMESTAMP_HEADER = status_regs[1][1];

reg [7:0] LOST_DATA_CNT;

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= status_regs[1];
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= LOST_DATA_CNT;
        else
            BUS_DATA_OUT <= 8'b0;
    end
end

wire CONF_EN_SYNC;
three_stage_synchronizer conf_en_synchronizer_dv_clk (
    .CLK(CLK_RX),
    .IN(CONF_EN),
    .OUT(CONF_EN_SYNC)
);

wire MKD_RX_IO;
IDDR IDDR_inst_mkd (
    .Q1(),
    .Q2(MKD_RX_IO),
    .C(CLK_RX),
    .CE(1'b1),
    .D(MKD_RX),
    .R(1'b0),
    .S(1'b0)
);

wire [1:0] DATA_RX_IO;
IDDR IDDR_inst_rx0 (
    .Q1(),
    .Q2(DATA_RX_IO[0]),
    .C(CLK_RX),
    .CE(1'b1),
    .D(DATA_RX[0]),
    .R(1'b0),
    .S(1'b0)
);

IDDR IDDR_inst_rx1 (
    .Q1(),
    .Q2(DATA_RX_IO[1]),
    .C(CLK_RX),
    .CE(1'b1),
    .D(DATA_RX[1]),
    .R(1'b0),
    .S(1'b0)
);

reg [4:0] MKD_DLY;
always@(posedge CLK_RX)
    MKD_DLY[4:0] <= {MKD_DLY[3:0], MKD_RX_IO};

reg [4:0] DATA1_DLY;
always@(posedge CLK_RX)
    DATA1_DLY[4:0] <= {DATA1_DLY[3:0], DATA_RX_IO[1]};

reg DATA0_DLY;
always@(posedge CLK_RX)
    DATA0_DLY <= DATA_RX_IO[0];

wire [1:0] WRITE;
wire FRAME_START, FRAME_START1;
wire [15:0] DATA [1:0];

m26_rx_ch m26_rx_ch0(
    .RST(RST_SYNC),
    .CLK_RX(CLK_RX),
    .MKD_RX(MKD_DLY[0]),
    .DATA_RX(DATA0_DLY),
    .WRITE(WRITE[0]),
    .FRAME_START(FRAME_START),
    .DATA(DATA[0])
);

m26_rx_ch m26_rx_ch1(
    .RST(RST_SYNC),
    .CLK_RX(CLK_RX),
    .MKD_RX(MKD_DLY[4]),
    .DATA_RX(DATA1_DLY[4]),
    .WRITE(WRITE[1]),
    .FRAME_START(FRAME_START1),
    .DATA(DATA[1])
);

reg [31:0] TIMESTAMP_save;
always@(posedge CLK_RX)
    if(FRAME_START)
        TIMESTAMP_save <= TIMESTAMP;

wire [17:0] cdc_data;
wire fifo_full, cdc_fifo_empty;
wire cdc_fifo_write;
reg data_lost_flag;

reg [15:0] data_field;
always@(*) begin
    if(CONF_TIMESTAMP_HEADER & (WRITE[0] && FRAME_START))
        data_field = TIMESTAMP[15:0];
    else if(CONF_TIMESTAMP_HEADER & (WRITE[1] && FRAME_START1))
        data_field = TIMESTAMP_save[31:16];
    else if(WRITE[0])
        data_field = DATA[0];
    else
        data_field = DATA[1];
end

assign cdc_data[17] = data_lost_flag;
assign cdc_data[16] = FRAME_START;
assign cdc_data[15:0] = data_field;

assign cdc_fifo_write = |WRITE & CONF_EN_SYNC;

wire wfull;
always@(posedge CLK_RX) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && cdc_fifo_write && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT +1;
end

always@(posedge CLK_RX) begin
    if(RST_SYNC)
        data_lost_flag <= 0;
    else if (cdc_fifo_write) begin
            if(wfull)
                data_lost_flag <= 1;
            else
                data_lost_flag <= 0;
    end
end

// generate long reset
reg [5:0] rst_cnt;
reg RST_LONG;
always@(posedge BUS_CLK) begin
    if (RST)
        rst_cnt <= 6'b11_1111; // start value
    else if (rst_cnt != 0)
        rst_cnt <= rst_cnt - 1;
    RST_LONG <= |rst_cnt;
end

reg [5:0] rst_cnt_sync;
reg RST_LONG_SYNC;
always@(posedge CLK_RX) begin
    if (RST_SYNC)
        rst_cnt_sync <= 6'b11_1111; // start value
    else if (rst_cnt_sync != 0)
        rst_cnt_sync <= rst_cnt_sync - 1;
    RST_LONG_SYNC <= |rst_cnt_sync;
end

wire [17:0] cdc_data_out;
cdc_syncfifo #(
    .DSIZE(18),
    .ASIZE(3)
) cdc_syncfifo_i (
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write),
    .wclk(CLK_RX),
    .wrst(RST_LONG_SYNC),
    .rinc(!fifo_full),
    .rclk(BUS_CLK),
    .rrst(RST_LONG)
);

gerneric_fifo #(
    .DATA_SIZE(18),
    .DEPTH(1024)
) fifo_i (
    .clk(BUS_CLK),
    .reset(RST_LONG),
    .write(!cdc_fifo_empty),
    .read(FIFO_READ),
    .data_in(cdc_data_out),
    .full(fifo_full),
    .empty(FIFO_EMPTY),
    .data_out(FIFO_DATA[17:0]),
    .size()
);

assign FIFO_DATA[19:18] = 0;
assign FIFO_DATA[23:20] = IDENTYFIER[3:0];
assign FIFO_DATA[31:24] = HEADER[7:0];

assign LOST_ERROR = LOST_DATA_CNT != 0;

endmodule
