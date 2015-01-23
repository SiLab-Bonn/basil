/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module fei4_rx_core
#(
    parameter           DSIZE = 10,
    parameter           DATA_IDENTIFIER = 0,
    parameter           ABUSWIDTH = 32
)
(
    input wire RX_CLK,
    input wire RX_CLK2X,
    input wire DATA_CLK,
    input wire RX_DATA,
    output wire RX_READY,
    output wire RX_8B10B_DECODER_ERR,
    output wire RX_FIFO_OVERFLOW_ERR,
     
    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,
    
    output wire RX_FIFO_FULL,

    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD
);

// 0 - soft reset
// 1 - status
// 2-3 fifo size
// 4 - decoder_err_cnt
// 5 - lost_err_cnt

wire SOFT_RST, FIFO_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign FIFO_RST = (BUS_ADD==1 && BUS_WR); // resets FIFO and FIFO error counters only, keeping status register values
// reset sync
// when write to addr = 0 then reset
reg RST_FF, RST_FF2, BUS_RST_FF, BUS_RST_FF2, FIFO_RST_FF, FIFO_RST_FF2;
always @(posedge BUS_CLK) begin
    RST_FF <= SOFT_RST;
    RST_FF2 <= RST_FF;
    BUS_RST_FF <= BUS_RST;
    BUS_RST_FF2 <= BUS_RST_FF;
    FIFO_RST_FF <= FIFO_RST;
    FIFO_RST_FF2 <= FIFO_RST_FF;
end

wire SOFT_RST_FLAG;
assign SOFT_RST_FLAG = ~RST_FF2 & RST_FF;
wire BUS_RST_FLAG;
assign BUS_RST_FLAG = BUS_RST_FF2 & ~BUS_RST_FF; // trailing edge
wire RST;
assign RST = BUS_RST_FLAG | SOFT_RST_FLAG;
wire FIFO_RST_FLAG;
assign FIFO_RST_FLAG = ~FIFO_RST_FF2 & FIFO_RST_FF;

wire ready_rec;
wire [15:0] fifo_size; // BUS_ADD==3 ,4
reg [7:0] decoder_err_cnt_buf; // BUS_ADD==5
reg [7:0] lost_err_cnt_buf; // BUS_ADD==6

wire [7:0] decoder_err_cnt, lost_err_cnt;
assign RX_READY = (ready_rec==1'b1);
assign RX_8B10B_DECODER_ERR = (decoder_err_cnt!=8'b0);
assign RX_FIFO_OVERFLOW_ERR = (lost_err_cnt!=8'b0);

reg [7:0] status_regs;

wire CONF_EN_INVERT_RX_DATA; // BUS_ADD==2 BIT==1
assign CONF_EN_INVERT_RX_DATA = status_regs[1];

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs <= 8'b0;
    end
    else if(BUS_WR && BUS_ADD == 2)
        status_regs <= BUS_DATA_IN;
end

localparam VERSION = 0;

always @ (posedge BUS_CLK) begin //(*) begin
    if(BUS_ADD == 0)
        BUS_DATA_OUT <= VERSION;
    else if(BUS_ADD == 2)
        BUS_DATA_OUT <= {status_regs[7:1], RX_READY};
    else if(BUS_ADD == 3)
        BUS_DATA_OUT <= fifo_size[7:0];
    else if(BUS_ADD == 4)
        BUS_DATA_OUT <= fifo_size[15:8];
    else if(BUS_ADD == 5)
        BUS_DATA_OUT <= decoder_err_cnt_buf;
    else if(BUS_ADD == 6)
        BUS_DATA_OUT <= lost_err_cnt_buf;
    else
        BUS_DATA_OUT <= 8'b0;
end

wire [23:0] FE_DATA;
wire [7:0] DATA_HEADER;
assign DATA_HEADER = DATA_IDENTIFIER;
assign FIFO_DATA = {DATA_HEADER, FE_DATA};

always @ (posedge BUS_CLK)
begin
    if (RST)
        decoder_err_cnt_buf <= 8'b0;
    else
    begin
        if (BUS_ADD == 4)
            decoder_err_cnt_buf <= decoder_err_cnt;
        else
            decoder_err_cnt_buf <= decoder_err_cnt_buf;
    end
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        lost_err_cnt_buf <= 8'b0;
    else
    begin
        if (BUS_ADD == 5)
            lost_err_cnt_buf <= lost_err_cnt;
        else
            lost_err_cnt_buf <= lost_err_cnt_buf;
    end
end

receiver_logic #(
    .DSIZE(DSIZE)
) ireceiver_logic (
    .RESET((RST | FIFO_RST_FLAG)),
    .WCLK(DATA_CLK),
    .FCLK(RX_CLK),
    .FCLK2X(RX_CLK2X),
    .BUS_CLK(BUS_CLK),
    .RX_DATA(RX_DATA),
    .read(FIFO_READ),
    .data(FE_DATA),
    .empty(FIFO_EMPTY),
    .full(RX_FIFO_FULL),
    .rec_sync_ready(ready_rec),
    .lost_err_cnt(lost_err_cnt),
    .decoder_err_cnt(decoder_err_cnt),
    .fifo_size(fifo_size),
    .invert_rx_data(CONF_EN_INVERT_RX_DATA)
);

//assign fei4_rx_d = {11'b0};

endmodule
