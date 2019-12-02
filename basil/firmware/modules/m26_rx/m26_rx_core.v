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

    output wire LOST_ERROR,
    output wire INVALID,
    output wire INVALID_FLAG
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
reg [7:0] INVALID_DATA_CNT;

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= status_regs[1];
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= LOST_DATA_CNT;
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= INVALID_DATA_CNT;
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
    if(WRITE_CH0 && FRAME_START_CH0)
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
reg [4:0] rst_cnt;
reg RST_LONG;
always @(posedge BUS_CLK) begin
    if (RST)
        rst_cnt <= 4'b1111; // start value
    else if (rst_cnt != 0)
        rst_cnt <= rst_cnt - 1;
    RST_LONG <= |rst_cnt;
end

reg [4:0] rst_cnt_sync;
reg RST_LONG_SYNC;
always @(posedge CLK_RX) begin
    if (RST_SYNC)
        rst_cnt_sync <= 4'b1111; // start value
    else if (rst_cnt_sync != 0)
        rst_cnt_sync <= rst_cnt_sync - 1;
    RST_LONG_SYNC <= |rst_cnt_sync;
end

// M26 data loss flag
wire fifo_data_lost_sync;
reg m26_data_lost;
always @(posedge CLK_RX) begin
    if(RST_SYNC) begin
        m26_data_lost <= 0;
    end else begin
        if(fifo_data_lost_sync) begin
            m26_data_lost <= 1;
        end else if(FRAME_START_CH0) begin
            m26_data_lost <= 0;
        end
    end
end

reg M26_FRAME_START;
always @(posedge CLK_RX) begin
    M26_FRAME_START <= FRAME_START_CH0;
end

reg INVALID_TOGGLE;
always @(posedge CLK_RX) begin
    if(RST_SYNC)
        INVALID_TOGGLE <= 1'b0;
    else
        if(M26_FRAME_START)
            INVALID_TOGGLE <= 1'b0;
        else if(INVALID_FLAG_CH0 | INVALID_FLAG_CH1)
            INVALID_TOGGLE <= 1'b1;
end

reg INVALID_TOGGLE_FF1, INVALID_TOGGLE_FF2;
always @(posedge CLK_RX) begin
    INVALID_TOGGLE_FF1 <= INVALID_TOGGLE;
    INVALID_TOGGLE_FF2 <= INVALID_TOGGLE_FF1;
end

assign INVALID_FLAG = ~INVALID_TOGGLE_FF2 & INVALID_TOGGLE_FF1;

wire INVALID_FLAG_BUS_CLK;
flag_domain_crossing INVALID_FLAG_domain_crossing_bus_clk (
    .CLK_A(CLK_RX),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(INVALID_FLAG),
    .FLAG_OUT_CLK_B(INVALID_FLAG_BUS_CLK)
);

always @(posedge BUS_CLK) begin
    if(RST)
        INVALID_DATA_CNT <= 0;
    else if (INVALID_FLAG_BUS_CLK && INVALID_DATA_CNT != 8'hff)
        INVALID_DATA_CNT <= INVALID_DATA_CNT + 1;
end

wire [17:0] cdc_data;
assign cdc_data[17] = m26_data_lost;  // M26 data loss flag
assign cdc_data[16] = M26_FRAME_START;  // start of M26 frame flag
assign cdc_data[15:0] = data_field;  // M26 data

reg FIRST_FRAME;
always @(posedge CLK_RX) begin
    if(RST_SYNC)
        FIRST_FRAME <= 1'b0;
    else if(WRITE_CH0 && FRAME_START_CH0)
        FIRST_FRAME <= 1'b1;
end

reg cdc_fifo_write;
always @(posedge CLK_RX) begin
    if((WRITE_CH0 | WRITE_CH1) & CONF_EN_SYNC)
        cdc_fifo_write <= 1'b1;
    else
        cdc_fifo_write <= 1'b0;
end

wire cdc_fifo_empty;
wire [17:0] cdc_data_out;
cdc_syncfifo #(
    .DSIZE(18),
    .ASIZE(3)
) cdc_syncfifo_i (
    .rdata(cdc_data_out),
    .wfull(),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write & FIRST_FRAME),
    .wclk(CLK_RX),
    .wrst(RST_LONG_SYNC),
    .rinc(1'b1),
    .rclk(BUS_CLK),
    .rrst(RST_LONG)
);

reg cdc_fifo_empty_buf, cdc_fifo_empty_buf2;
always @(posedge BUS_CLK) begin
    cdc_fifo_empty_buf <= cdc_fifo_empty;
    cdc_fifo_empty_buf2 <= cdc_fifo_empty_buf;
end
reg [17:0] cdc_data_out_buf, cdc_data_out_buf2;
always @(posedge BUS_CLK) begin
    cdc_data_out_buf <= cdc_data_out;
    cdc_data_out_buf2 <= cdc_data_out_buf;
end

wire fifo_full;
gerneric_fifo #(
    .DATA_SIZE(18),
    .DEPTH(2048)
) fifo_i (
    .clk(BUS_CLK),
    .reset(RST_LONG),
    .write(!cdc_fifo_empty_buf2),
    .read(FIFO_READ),
    .data_in(cdc_data_out_buf2),
    .full(fifo_full),
    .empty(FIFO_EMPTY),
    .data_out(FIFO_DATA[17:0]),
    .size()
);

reg fifo_data_lost;
always @(posedge BUS_CLK) begin
    if(fifo_full && !cdc_fifo_empty_buf2) begin  // write when full
        fifo_data_lost <= 1'b1;
    end else if(!fifo_full && !cdc_fifo_empty_buf2) begin  // write when not full
        fifo_data_lost <= 1'b0;
    end
end

three_stage_synchronizer data_lost_synchronizer_clk_rx (
    .CLK(CLK_RX),
    .IN(fifo_data_lost),
    .OUT(fifo_data_lost_sync)
);

assign FIFO_DATA[19:18] = 0;
assign FIFO_DATA[23:20] = IDENTYFIER[3:0];
assign FIFO_DATA[31:24] = HEADER[7:0];

always @(posedge BUS_CLK) begin
    if(RST)
        LOST_DATA_CNT <= 0;
    else if (fifo_full && !cdc_fifo_empty_buf2 && LOST_DATA_CNT != 8'hff)
        LOST_DATA_CNT <= LOST_DATA_CNT + 1;
end

reg LOST_ERROR_BUS_CLK;
always @(posedge BUS_CLK) begin
    LOST_ERROR_BUS_CLK <= |LOST_DATA_CNT;
end

three_stage_synchronizer lost_error_synchronizer_clk_rx (
    .CLK(CLK_RX),
    .IN(LOST_ERROR_BUS_CLK),
    .OUT(LOST_ERROR)
);

endmodule
