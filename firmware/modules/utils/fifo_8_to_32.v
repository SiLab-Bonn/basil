/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module fifo_8_to_32 #(
    parameter DEPTH = 1024
)(
    input wire CLK,
    input wire RST,

    input wire WRITE,
    input wire READ,
    input wire [7:0] DATA_IN,
    output wire FULL,
    output wire EMPTY,
    output wire [31:0] DATA_OUT
);


wire FIFO_EMPTY_8;
wire FIFO_READ_8;
wire [7:0] FIFO_DATA_OUT_8;

gerneric_fifo #(.DATA_SIZE(8), .DEPTH(DEPTH * 4)) fifo_8_i
(
    .clk(CLK),
    .reset(RST),
    .write(WRITE),
    .read(FIFO_READ_8),
    .data_in(DATA_IN),
    .full(FULL),
    .empty(FIFO_EMPTY_8),
    .data_out(FIFO_DATA_OUT_8),
    .size()
);


wire FIFO_FULL_32;
reg FIFO_WRITE_32;
wire [31:0] FIFO_DATA_IN_32;

reg [1:0] byte_cnt;
reg WAIT_FOR_FIFO_32;
always@(posedge CLK)
    if(RST) begin
        byte_cnt <= 0;
        WAIT_FOR_FIFO_32 <= 1'b0;
    end else if(~WAIT_FOR_FIFO_32 && ~FIFO_EMPTY_8 && &byte_cnt) begin
        byte_cnt <= byte_cnt;
        WAIT_FOR_FIFO_32 <= 1'b1;
    end else if((~FIFO_EMPTY_8 && ~&byte_cnt) || (FIFO_WRITE_32 && &byte_cnt)) begin
        byte_cnt <= byte_cnt + 1;
        WAIT_FOR_FIFO_32 <= 1'b0;
    end else begin
        byte_cnt <= byte_cnt;
        WAIT_FOR_FIFO_32 <= WAIT_FOR_FIFO_32;
    end

wire READ_FIFO_8;
assign READ_FIFO_8 = (~FIFO_EMPTY_8 && ~WAIT_FOR_FIFO_32);
assign FIFO_READ_8 = READ_FIFO_8;

always@(posedge CLK)
    if(RST) begin
        FIFO_WRITE_32 <= 1'b0;
    end else if(FIFO_WRITE_32) begin
        FIFO_WRITE_32 <= 1'b0;
    end else if(~FIFO_FULL_32 && &byte_cnt && WAIT_FOR_FIFO_32) begin
        FIFO_WRITE_32 <= 1'b1;
    end

reg [31:0] DATA_BUF;
always@(posedge CLK)
    if(RST) begin
        DATA_BUF = 0;
    end else if(READ_FIFO_8 && byte_cnt  == 0) begin
        DATA_BUF[7:0] <= FIFO_DATA_OUT_8;
    end else if(READ_FIFO_8 && byte_cnt  == 1) begin
        DATA_BUF[15:8] <= FIFO_DATA_OUT_8;
    end else if(READ_FIFO_8 && byte_cnt  == 2) begin
        DATA_BUF[23:16] <= FIFO_DATA_OUT_8;
    end else if(READ_FIFO_8 && byte_cnt  == 3) begin
        DATA_BUF[31:24] <= FIFO_DATA_OUT_8;
    end else begin
        DATA_BUF <= DATA_BUF;
    end

assign FIFO_DATA_IN_32 = DATA_BUF;

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(DEPTH)) fifo_32_i
(
    .clk(CLK),
    .reset(RST),
    .write(FIFO_WRITE_32),
    .read(READ),
    .data_in(FIFO_DATA_IN_32),
    .full(FIFO_FULL_32),
    .empty(EMPTY),
    .data_out(DATA_OUT),
    .size()
);

endmodule
