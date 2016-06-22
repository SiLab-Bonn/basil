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

localparam VERSION = 1;

//output format #ID (as parameter IDENTYFIER + 1 frame start + 16 bit data) 

wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 

reg CONF_EN;
reg CONF_TIMESTAMP_HEADER;

always @(posedge BUS_CLK) begin
    if(RST) begin
        CONF_EN <= 0;
        CONF_TIMESTAMP_HEADER <= 0;
    end
    else if(BUS_WR) begin
        if(BUS_ADD == 2) begin
            CONF_EN <= BUS_DATA_IN[0];
            CONF_TIMESTAMP_HEADER <= BUS_DATA_IN[1];
        end
    end
end

reg [7:0] LOST_DATA_CNT;

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= {6'b0, CONF_TIMESTAMP_HEADER, CONF_EN};
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= LOST_DATA_CNT;
        else
            BUS_DATA_OUT <= 8'b0;
    end
end

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_reset_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(CLK_RX), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC;

wire CONF_EN_SYNC;
assign CONF_EN_SYNC  = CONF_EN;
 
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

reg [4:0] DATA0_DLY;
always@(posedge CLK_RX)
    DATA0_DLY[4:0] <= {DATA0_DLY[3:0], DATA_RX_IO[0]};

wire [1:0] WRITE;
wire FRAME_START, FRAME_START1;
wire [15:0] DATA [1:0];

m26_rx_ch m26_rx_ch0(
    .RST(RST_SYNC), .CLK_RX(CLK_RX), .MKD_RX(MKD_DLY[0]), .DATA_RX(DATA0_DLY[0]),
    .WRITE(WRITE[0]), .FRAME_START(FRAME_START), .DATA(DATA[0])
); 

m26_rx_ch m26_rx_ch1(
    .RST(RST_SYNC), .CLK_RX(CLK_RX), .MKD_RX(MKD_DLY[4]), .DATA_RX(DATA1_DLY[4]),
    .WRITE(WRITE[1]), .FRAME_START(FRAME_START1), .DATA(DATA[1])
);

//ila_0 ila(
//    .clk(CLK_RX),
//    .probe0({FRAME_START, WRITE, DATA[1], DATA[0]})
//);

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

wire [17:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(18), .ASIZE(3)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write), .wclk(CLK_RX), .wrst(RST_SYNC),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(RST)
);

gerneric_fifo #(.DATA_SIZE(18), .DEPTH(1024))  fifo_i
( .clk(BUS_CLK), .reset(RST), 
    .write(!cdc_fifo_empty),
    .read(FIFO_READ), 
    .data_in(cdc_data_out), 
    .full(fifo_full), 
    .empty(FIFO_EMPTY), 
    .data_out(FIFO_DATA[17:0]), .size() 
);

assign FIFO_DATA[19:18]  =  0; 
assign FIFO_DATA[23:20]  =  IDENTYFIER[3:0]; 
assign FIFO_DATA[31:24]  =  HEADER[7:0]; 

assign LOST_ERROR = LOST_DATA_CNT != 0;

endmodule
