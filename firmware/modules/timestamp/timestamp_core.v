/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module timestamp_core
#(
    parameter ABUSWIDTH = 16,
    parameter IDENTIFIER = 4'b0001
)(
    input wire CLK,
    input wire DI,
    input wire EXT_ENABLE,
    output wire [63:0] TIMESTAMP,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD
); 

localparam VERSION = 1;

//output format:
//31-28: ID, 27-24: 0x1, 23-0: 23-0th bit of timestamp data
//31-28: ID, 27-24: 0x2, 23-0: 47-24th bit of timestamp data
//31-28: ID, 27-24: 0x3, 23-16: 0x00, 15-0: 63-48th bit timestamp data

wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 

reg CONF_EN;  //TODO add enable/disable by software
reg [7:0] LOST_DATA_CNT;

always @(posedge BUS_CLK) begin
    if(RST) begin
        CONF_EN <= 0;
    end
    else if(BUS_WR) begin
        if(BUS_ADD == 2)
            CONF_EN <= BUS_DATA_IN[0];
    end
end

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= {7'b0, CONF_EN};
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= LOST_DATA_CNT;
        else
            BUS_DATA_OUT <= 8'b0;
    end
end

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;


reg [7:0] sync_cnt;
always@(posedge BUS_CLK) begin
    if(RST)
        sync_cnt <= 120;
    else if(sync_cnt != 100)
        sync_cnt <= sync_cnt +1;
end 
wire RST_LONG;
assign RST_LONG = sync_cnt[7];


reg DI_FF;
always@(posedge CLK) begin
    if(RST_SYNC)
      DI_FF <=0;
    else
      DI_FF <= DI;
end

reg [63:0] curr_timestamp;
always@(posedge CLK) begin
    if(RST_SYNC)
        curr_timestamp <= 0;
    else
        curr_timestamp <= curr_timestamp + 1;
end

reg [63:0] timestamp_out;
reg [1:0] cdc_fifo_write_reg;
reg [3:0] bit_cnt;

always@(posedge CLK) begin
    if(RST_SYNC) begin
        timestamp_out <= 0;
	cdc_fifo_write_reg<=0;
    end
    else if(~DI_FF & DI & cdc_fifo_write_reg==0) begin
        timestamp_out <= curr_timestamp;
	cdc_fifo_write_reg<=1;
    end
    else if (cdc_fifo_write_reg==1)
        cdc_fifo_write_reg<=2;
    else
        cdc_fifo_write_reg<=0;
end
assign TIMESTAMP=timestamp_out;

wire [63:0] cdc_data_in;
assign cdc_data_in = timestamp_out;

wire cdc_fifo_write;
assign cdc_fifo_write = cdc_fifo_write_reg[1];

wire fifo_full,fifo_write,cdc_fifo_empty;

wire wfull;
always@(posedge CLK) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && cdc_fifo_write && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT +1;
end

wire [63:0] cdc_data_out;   
wire cdc_fifo_read;
cdc_syncfifo 
#(.DSIZE(64), .ASIZE(8))
 cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data_in),
    .winc(cdc_fifo_write), .wclk(CLK), .wrst(RST_LONG),
    .rinc(cdc_fifo_read), .rclk(BUS_CLK), .rrst(RST_LONG)
);
 
reg [1:0] byte2_cnt, byte2_cnt_prev;
always@(posedge BUS_CLK)
    byte2_cnt_prev <= byte2_cnt;
assign cdc_fifo_read = (byte2_cnt_prev==0 & byte2_cnt!=0);
assign fifo_write = byte2_cnt_prev != 0;

always@(posedge BUS_CLK)
    if(RST)
        byte2_cnt <= 0;
    else if(!cdc_fifo_empty && !fifo_full && byte2_cnt == 0 ) 
        byte2_cnt <= 3;
    else if (!fifo_full & byte2_cnt != 0)
        byte2_cnt <= byte2_cnt - 1;

reg [63:0] data_buf;
always@(posedge BUS_CLK)
    if(cdc_fifo_read)
        data_buf <= cdc_data_out;

wire [31:0] fifo_write_data_byte [3:0];
assign fifo_write_data_byte[0]={IDENTIFIER,4'b0001,data_buf[23:0]};
assign fifo_write_data_byte[1]={IDENTIFIER,4'b0010,data_buf[47:24]};
assign fifo_write_data_byte[2]={IDENTIFIER,4'b0011,8'b0,data_buf[63:48]};
wire [31:0] fifo_data_in;
assign fifo_data_in = fifo_write_data_byte[byte2_cnt];

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(1024))  fifo_i
( .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
    .write(fifo_write),
    .read(FIFO_READ), 
    .data_in(fifo_data_in), 
    .full(fifo_full), 
    .empty(FIFO_EMPTY), 
    .data_out(FIFO_DATA[31:0]), .size() 
);

endmodule
