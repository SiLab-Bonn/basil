/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module fei4_rx_core #(
    parameter           DSIZE = 10,
    parameter           DATA_IDENTIFIER = 0,
    parameter           ABUSWIDTH = 32
) (
    input wire RX_CLK,
    input wire RX_CLK2X,
    input wire DATA_CLK,
    input wire RX_DATA,
    output reg RX_READY,
    output reg RX_8B10B_DECODER_ERR,
    output reg RX_FIFO_OVERFLOW_ERR,

    input wire FIFO_CLK,
    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    output wire RX_FIFO_FULL,
    output wire RX_ENABLED,

    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD
);

localparam VERSION = 3;

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

// writing to register 1 asserts reset RX only
wire RX_RST;
assign RX_RST = (BUS_ADD==1 && BUS_WR);
reg RX_RST_FF, RX_RST_FF2;
always @(posedge BUS_CLK) begin
    RX_RST_FF <= RX_RST;
    RX_RST_FF2 <= RX_RST_FF;
end

wire SOFT_RST_FLAG;
assign SOFT_RST_FLAG = ~SOFT_RST_FF2 & SOFT_RST_FF;
wire BUS_RST_FLAG;
assign BUS_RST_FLAG = BUS_RST_FF2 & ~BUS_RST_FF; // trailing edge
wire RST_FLAG;
assign RST_FLAG = BUS_RST_FLAG | SOFT_RST_FLAG;
wire RX_RST_FLAG;
assign RX_RST_FLAG = ~RX_RST_FF2 & RX_RST_FF;

reg RECEIVER_RST;
always @(posedge BUS_CLK) begin
    RECEIVER_RST <= RST_FLAG | RX_RST_FLAG;
end

// registers
// 0 - soft reset
// 1 - RX reset
// 2 - status
// 3-4 - fifo size
// 5 - 8b10b decoder error counter
// 6 - lost data counter
wire rx_ready_bus_clk;
reg [15:0] fifo_size_bus_clk; // BUS_ADD==3
reg [7:0] fifo_size_buf_read_bus_clk; // BUS_ADD==4
reg [7:0] decoder_err_cnt_bus_clk; // BUS_ADD==5
reg [7:0] lost_data_cnt_bus_clk; // BUS_ADD==6

reg [7:0] status_regs;

wire CONF_EN_INVERT_RX_DATA; // BUS_ADD==2 BIT==1
assign CONF_EN_INVERT_RX_DATA = status_regs[1];
wire CONF_EN_RX; // BUS_ADD==2 BIT==2
assign CONF_EN_RX = status_regs[2];
assign RX_ENABLED = CONF_EN_RX;

always @(posedge BUS_CLK) begin
    if(RST_FLAG)
        status_regs <= 8'b0000_0000; // disable Rx by default
    else if(BUS_WR && BUS_ADD == 2)
        status_regs <= BUS_DATA_IN;
end

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= {status_regs[7:1], rx_ready_bus_clk};
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= fifo_size_bus_clk[7:0];
        else if(BUS_ADD == 4)
            BUS_DATA_OUT <= fifo_size_buf_read_bus_clk;
        else if(BUS_ADD == 5)
            BUS_DATA_OUT <= decoder_err_cnt_bus_clk;
        else if(BUS_ADD == 6)
            BUS_DATA_OUT <= lost_data_cnt_bus_clk;
        else
            BUS_DATA_OUT <= 8'b0;
    end
end


wire CONF_EN_INVERT_RX_DATA_FCLK;
three_stage_synchronizer conf_en_invert_rx_data_synchronizer_rx_clk (
    .CLK(RX_CLK),
    .IN(CONF_EN_INVERT_RX_DATA),
    .OUT(CONF_EN_INVERT_RX_DATA_FCLK)
);

wire CONF_EN_RX_WCLK;
three_stage_synchronizer conf_en_rx_synchronizer_data_clk (
    .CLK(DATA_CLK),
    .IN(CONF_EN_RX),
    .OUT(CONF_EN_RX_WCLK)
);

wire rec_sync_ready;
three_stage_synchronizer rx_ready_synchronizer_bus_clk (
    .CLK(BUS_CLK),
    .IN(rec_sync_ready),
    .OUT(rx_ready_bus_clk)
);

always @(posedge DATA_CLK) begin
    RX_READY <= rec_sync_ready;
end

wire [7:0] decoder_err_cnt;
always @(posedge DATA_CLK) begin
    if(|decoder_err_cnt) begin
        RX_8B10B_DECODER_ERR <= 1;
    end else begin
        RX_8B10B_DECODER_ERR <= 0;
    end
end

wire [7:0] lost_data_cnt;
always @(posedge DATA_CLK) begin
    if(|lost_data_cnt) begin
        RX_FIFO_OVERFLOW_ERR <= 1;
    end else begin
        RX_FIFO_OVERFLOW_ERR <= 0;
    end
end


wire [23:0] FE_DATA;
wire [7:0] DATA_HEADER;
assign DATA_HEADER = DATA_IDENTIFIER;
assign FIFO_DATA = {DATA_HEADER, FE_DATA};


wire [15:0] fifo_size;
reg [15:0] fifo_size_gray;
always @(posedge FIFO_CLK)
    fifo_size_gray <=  (fifo_size>>1) ^ fifo_size;

reg [15:0] fifo_size_cdc0, fifo_size_cdc1;
always @(posedge BUS_CLK) begin
    fifo_size_cdc0 <= fifo_size_gray;
    fifo_size_cdc1 <= fifo_size_cdc0;
end

integer gbi_fifo_size;
always @(*) begin
    fifo_size_bus_clk[15] = fifo_size_cdc1[15];
    for(gbi_fifo_size = 14; gbi_fifo_size >= 0; gbi_fifo_size = gbi_fifo_size - 1) begin
        fifo_size_bus_clk[gbi_fifo_size] = fifo_size_cdc1[gbi_fifo_size] ^ fifo_size_bus_clk[gbi_fifo_size + 1];
    end
end

always @(posedge BUS_CLK)
begin
    if (BUS_ADD == 3 && BUS_RD)
        fifo_size_buf_read_bus_clk <= fifo_size_bus_clk[15:8];
end

reg [7:0] decoder_err_cnt_gray;
always @(posedge DATA_CLK)
    decoder_err_cnt_gray <=  (decoder_err_cnt>>1) ^ decoder_err_cnt;

reg [7:0] decoder_err_cnt_cdc0, decoder_err_cnt_cdc1;
always @(posedge BUS_CLK) begin
    decoder_err_cnt_cdc0 <= decoder_err_cnt_gray;
    decoder_err_cnt_cdc1 <= decoder_err_cnt_cdc0;
end

integer gbi_decoder_err_cnt;
always @(*) begin
    decoder_err_cnt_bus_clk[7] = decoder_err_cnt_cdc1[7];
    for(gbi_decoder_err_cnt = 6; gbi_decoder_err_cnt >= 0; gbi_decoder_err_cnt = gbi_decoder_err_cnt - 1) begin
        decoder_err_cnt_bus_clk[gbi_decoder_err_cnt] = decoder_err_cnt_cdc1[gbi_decoder_err_cnt] ^ decoder_err_cnt_bus_clk[gbi_decoder_err_cnt + 1];
    end
end

reg [7:0] lost_data_cnt_gray;
always @(posedge DATA_CLK)
    lost_data_cnt_gray <=  (lost_data_cnt>>1) ^ lost_data_cnt;

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


receiver_logic #(
    .DSIZE(DSIZE)
) ireceiver_logic (
    .RESET(RECEIVER_RST),
    .WCLK(DATA_CLK),
    .FCLK(RX_CLK),
    .FCLK2X(RX_CLK2X),
    .BUS_CLK(BUS_CLK),
    .RX_DATA(RX_DATA),
    .read(FIFO_READ),
    .data(FE_DATA),
    .empty(FIFO_EMPTY),
    .rx_fifo_full(RX_FIFO_FULL),
    .rec_sync_ready(rec_sync_ready),
    .lost_data_cnt(lost_data_cnt),
    .decoder_err_cnt(decoder_err_cnt),
    .fifo_size(fifo_size),
    .invert_rx_data(CONF_EN_INVERT_RX_DATA_FCLK),
    .enable_rx(CONF_EN_RX_WCLK),
    .FIFO_CLK(FIFO_CLK)
);

endmodule
