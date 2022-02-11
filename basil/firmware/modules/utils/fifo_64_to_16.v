/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module fifo_64_to_16 #(
    parameter DEPTH = 1024*4
) (
    input wire CLK,
    input wire RST,
    input wire WRITE,
    input wire READ,
    input wire [63:0] DATA_IN,
    output wire FULL,
    output wire EMPTY,
    output wire [15:0] DATA_OUT
);

reg [1:0] byte_cnt;
wire FIFO_EMPTY, READ_FIFO;
wire [63:0] FIFO_DATA_OUT;

assign EMPTY = byte_cnt==0 & FIFO_EMPTY;
assign READ_FIFO = (byte_cnt==0 & !FIFO_EMPTY && READ);

gerneric_fifo #(
    .DATA_SIZE(64),
    .DEPTH(DEPTH)
) fifo_i (
    .clk(CLK),
    .reset(RST),
    .write(WRITE),
    .read(READ_FIFO),
    .data_in(DATA_IN),
    .full(FULL),
    .empty(FIFO_EMPTY),
    .data_out(FIFO_DATA_OUT),
    .size()
);

always @(posedge CLK)
    if(RST)
        byte_cnt <= 0;
    else if (READ)
        byte_cnt <= byte_cnt + 1;

reg [63:0] DATA_BUF;
always @(posedge CLK)
    if(READ_FIFO)
        DATA_BUF <= FIFO_DATA_OUT;

wire [15:0] FIFO_DATA_OUT_BYTE [3:0];
assign FIFO_DATA_OUT_BYTE[0] = FIFO_DATA_OUT[15:0];
assign FIFO_DATA_OUT_BYTE[1] = DATA_BUF[31:16];
assign FIFO_DATA_OUT_BYTE[2] = DATA_BUF[47:32];
assign FIFO_DATA_OUT_BYTE[3] = DATA_BUF[63:48];
assign DATA_OUT = FIFO_DATA_OUT_BYTE[byte_cnt];

endmodule
