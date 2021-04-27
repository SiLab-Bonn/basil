/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module m26_rx_core #(
    parameter ABUSWIDTH = 16,
    parameter HEADER = 0,
    parameter IDENTIFIER = 0
) (
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

    output reg LOST_ERROR,
    output wire INVALID,
    output reg INVALID_FLAG
);

localparam VERSION = 2;

//output format #ID (as parameter IDENTIFIER + 1 frame start + 16 bit data)

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

reg [7:0] lost_data_cnt_bus_clk;
reg [7:0] invalid_data_cnt_bus_clk;

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= status_regs[1];
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= lost_data_cnt_bus_clk;
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= invalid_data_cnt_bus_clk;
        else
            BUS_DATA_OUT <= 8'b0;
    end
end

wire CONF_EN_SYNC;
three_stage_synchronizer conf_en_synchronizer_clk_rx (
    .CLK(CLK_RX),
    .IN(CONF_EN),
    .OUT(CONF_EN_SYNC)
);

wire CONF_TIMESTAMP_HEADER_SYNC;
three_stage_synchronizer conf_timestamp_header_synchronizer_clk_rx (
    .CLK(CLK_RX),
    .IN(CONF_TIMESTAMP_HEADER),
    .OUT(CONF_TIMESTAMP_HEADER_SYNC)
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
always @(posedge CLK_RX)
    MKD_DLY[4:0] <= {MKD_DLY[3:0], MKD_RX_IO};

reg [4:0] DATA1_DLY;
always @(posedge CLK_RX)
    DATA1_DLY[4:0] <= {DATA1_DLY[3:0], DATA_RX_IO[1]};

reg DATA0_DLY;
always @(posedge CLK_RX)
    DATA0_DLY <= DATA_RX_IO[0];

wire WRITE_CH0, WRITE_CH1;
wire FRAME_START_CH0, FRAME_START_CH1;
wire [15:0] DATA_CH0, DATA_CH1;
wire INVALID_CH0, INVALID_CH1;
wire INVALID_FLAG_CH0, INVALID_FLAG_CH1;

m26_rx_ch m26_rx_ch0(
    .RST(RST_SYNC),
    .CLK_RX(CLK_RX),
    .MKD_RX(MKD_DLY[0]),
    .DATA_RX(DATA0_DLY),
    .WRITE(WRITE_CH0),
    .FRAME_START(FRAME_START_CH0),
    .DATA(DATA_CH0),
    .INVALID(INVALID_CH0),
    .INVALID_FLAG(INVALID_FLAG_CH0)
);

m26_rx_ch m26_rx_ch1(
    .RST(RST_SYNC),
    .CLK_RX(CLK_RX),
    .MKD_RX(MKD_DLY[4]),
    .DATA_RX(DATA1_DLY[4]),
    .WRITE(WRITE_CH1),
    .FRAME_START(FRAME_START_CH1),
    .DATA(DATA_CH1),
    .INVALID(INVALID_CH1),
    .INVALID_FLAG(INVALID_FLAG_CH1)
);

assign INVALID = INVALID_CH0 | INVALID_CH1;

reg [15:0] TIMESTAMP_BUF_31_16;
always @(posedge CLK_RX)
    if (WRITE_CH0 && FRAME_START_CH0)
        TIMESTAMP_BUF_31_16 <= TIMESTAMP[31:16];

reg [15:0] data_field;
always @(posedge CLK_RX) begin
    if (CONF_TIMESTAMP_HEADER_SYNC & (WRITE_CH0 && FRAME_START_CH0))
        data_field <= TIMESTAMP[15:0];
    else if (CONF_TIMESTAMP_HEADER_SYNC & (WRITE_CH1 && FRAME_START_CH1))
        data_field <= TIMESTAMP_BUF_31_16;
    else if (WRITE_CH0)
        data_field <= DATA_CH0;
    else if (WRITE_CH1)
        data_field <= DATA_CH1;
end

// generate long reset
reg [3:0] rst_cnt;
reg RST_LONG;
always @(posedge BUS_CLK) begin
    if (RST)
        rst_cnt <= 4'b1111; // start value
    else if (rst_cnt != 0)
        rst_cnt <= rst_cnt - 1;
    RST_LONG <= |rst_cnt;
end

reg [3:0] rst_cnt_sync;
reg RST_LONG_SYNC;
always @(posedge CLK_RX) begin
    if (RST_SYNC)
        rst_cnt_sync <= 4'b1111; // start value
    else if (rst_cnt_sync != 0)
        rst_cnt_sync <= rst_cnt_sync - 1;
    RST_LONG_SYNC <= |rst_cnt_sync;
end

reg INVALID_FRAME;
always @(posedge CLK_RX) begin
    if(RST_SYNC)
        INVALID_FRAME <= 1'b0;
    else
        if (M26_FRAME_START)
            INVALID_FRAME <= 1'b0;
        else if (INVALID_FLAG_CH0 | INVALID_FLAG_CH1)
            INVALID_FRAME <= 1'b1;
end

reg INVALID_FRAME_FF1, INVALID_FRAME_FF2;
always @(posedge CLK_RX) begin
    INVALID_FRAME_FF1 <= INVALID_FRAME;
    INVALID_FRAME_FF2 <= INVALID_FRAME_FF1;
end

wire INVALID_FRAME_FLAG;
assign INVALID_FRAME_FLAG = ~INVALID_FRAME_FF2 & INVALID_FRAME_FF1;

always @(posedge CLK_RX) begin
    INVALID_FLAG <= INVALID_FRAME_FLAG;
end

reg [7:0] INVALID_DATA_CNT;
always @(posedge CLK_RX) begin
    if (RST)
        INVALID_DATA_CNT <= 0;
    else
        if (INVALID_FRAME_FLAG && WRITE_FRAME && INVALID_DATA_CNT != 8'hff)
            INVALID_DATA_CNT <= INVALID_DATA_CNT + 1;
end

reg [7:0] invalid_data_cnt_gray;
always @(posedge CLK_RX)
    invalid_data_cnt_gray <=  (INVALID_DATA_CNT>>1) ^ INVALID_DATA_CNT;

reg [7:0] invalid_data_cnt_cdc0, invalid_data_cnt_cdc1;
always @(posedge BUS_CLK) begin
    invalid_data_cnt_cdc0 <= invalid_data_cnt_gray;
    invalid_data_cnt_cdc1 <= invalid_data_cnt_cdc0;
end

integer gbi_invalid_data_cnt;
always @(*) begin
    invalid_data_cnt_bus_clk[7] = invalid_data_cnt_cdc1[7];
    for(gbi_invalid_data_cnt = 6; gbi_invalid_data_cnt >= 0; gbi_invalid_data_cnt = gbi_invalid_data_cnt - 1) begin
        invalid_data_cnt_bus_clk[gbi_invalid_data_cnt] = invalid_data_cnt_cdc1[gbi_invalid_data_cnt] ^ invalid_data_cnt_bus_clk[gbi_invalid_data_cnt + 1];
    end
end

// M26 data loss flag
reg fifo_data_lost;
reg m26_data_lost;
always @(posedge CLK_RX) begin
    if (RST_SYNC) begin
        m26_data_lost <= 0;
    end else begin
        if(FRAME_START_CH0) begin  // keep data lost bit until end of frame
            m26_data_lost <= 1'b0;
        end else if (fifo_data_lost) begin
            m26_data_lost <= 1'b1;
        end
    end
end

reg M26_FRAME_START;
always @(posedge CLK_RX) begin
    M26_FRAME_START <= FRAME_START_CH0;
end

wire [17:0] cdc_data;
assign cdc_data[17] = m26_data_lost;  // M26 data loss flag
assign cdc_data[16] = M26_FRAME_START;  // start of M26 frame flag
assign cdc_data[15:0] = data_field;  // M26 data

reg WRITE_FRAME;
always @(posedge CLK_RX) begin
    if (RST_SYNC)
        WRITE_FRAME <= 1'b0;
    else
        if (WRITE_CH0 && FRAME_START_CH0 && CONF_EN_SYNC == 1'b0)  // disable write full frame
            WRITE_FRAME <= 1'b0;
        else if (WRITE_CH0 && FRAME_START_CH0 && CONF_EN_SYNC == 1'b1)  // enable write full frame
            WRITE_FRAME <= 1'b1;
end

reg cdc_fifo_write;
always @(posedge CLK_RX) begin
    if(WRITE_CH0 | WRITE_CH1)
        cdc_fifo_write <= 1'b1;
    else
        cdc_fifo_write <= 1'b0;
end

wire wfull;
wire fifo_full, cdc_fifo_empty;
wire [17:0] cdc_data_out;
cdc_syncfifo #(
    .DSIZE(18),
    .ASIZE(3)
) cdc_syncfifo_i (
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write & WRITE_FRAME),
    .wclk(CLK_RX),
    .wrst(RST_LONG_SYNC),
    .rinc(!fifo_full),
    .rclk(BUS_CLK),
    .rrst(RST_LONG)
);

gerneric_fifo #(
    .DATA_SIZE(18),
    .DEPTH(2048)
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

always @(posedge CLK_RX) begin
    if (wfull && cdc_fifo_write && WRITE_FRAME) begin  // assert when write and FIFO full
        fifo_data_lost <= 1'b1;
    end else if (!wfull && cdc_fifo_write && WRITE_FRAME) begin  // de-assert when write and FIFO not full
        fifo_data_lost <= 1'b0;
    end
end

reg [7:0] LOST_DATA_CNT;
always @(posedge CLK_RX) begin
    if (RST_SYNC)
        LOST_DATA_CNT <= 0;
    else
        if (wfull && cdc_fifo_write && WRITE_FRAME && LOST_DATA_CNT != 8'hff)
            LOST_DATA_CNT <= LOST_DATA_CNT + 1;
end

reg [7:0] lost_data_cnt_gray;
always @(posedge CLK_RX)
    lost_data_cnt_gray <=  (LOST_DATA_CNT>>1) ^ LOST_DATA_CNT;

reg [7:0] lost_data_cnt_cdc0, lost_data_cnt_cdc1;
always @(posedge BUS_CLK) begin
    lost_data_cnt_cdc0 <= lost_data_cnt_gray;
    lost_data_cnt_cdc1 <= lost_data_cnt_cdc0;
end

integer gbi_lost_data_cnt;
always @(*) begin
    lost_data_cnt_bus_clk[7] = lost_data_cnt_cdc1[7];
    for(gbi_lost_data_cnt = 6; gbi_lost_data_cnt >= 0; gbi_lost_data_cnt = gbi_lost_data_cnt - 1) begin
        lost_data_cnt_bus_clk[gbi_lost_data_cnt] = lost_data_cnt_cdc1[gbi_lost_data_cnt] ^ lost_data_cnt_bus_clk[gbi_lost_data_cnt + 1];
    end
end

always @(posedge CLK_RX) begin
    LOST_ERROR <= |LOST_DATA_CNT;
end

assign FIFO_DATA[19:18] = 0;
assign FIFO_DATA[23:20] = IDENTIFIER[3:0];
assign FIFO_DATA[31:24] = HEADER[7:0];


endmodule
