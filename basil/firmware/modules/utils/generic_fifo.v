/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module gerneric_fifo (
    clk,
    reset,
    write,
    read,
    data_in,
    full,
    empty,
    data_out,
    size
);

parameter DATA_SIZE = 32;
parameter DEPTH = 8;
input wire clk, reset, write, read;
input wire [DATA_SIZE-1:0] data_in;

output wire full;
output reg empty;

output reg [DATA_SIZE-1:0] data_out;
`include "../includes/log2func.v"

reg [DATA_SIZE:0] mem [DEPTH-1:0];

parameter POINTER_SIZE = `CLOG2(DEPTH);

reg [POINTER_SIZE-1:0] rd_pointer, rd_tmp, wr_pointer;
output reg [POINTER_SIZE-1:0] size;

wire empty_loc;


always @(posedge clk) begin
    if(reset)
        rd_pointer <= 0;
    else if(read && !empty) begin
        if(rd_pointer == DEPTH-1'b1)
            rd_pointer <= 0;
        else
            rd_pointer <= rd_pointer + 1'b1;
    end
end

always @(*) begin
    rd_tmp = rd_pointer;
    if(read && !empty) begin
        if(rd_pointer == DEPTH-1'b1)
            rd_tmp = 0;
        else
            rd_tmp = rd_pointer + 1'b1;
    end
end

always @(posedge clk) begin
    if(reset)
        wr_pointer <= 0;
    else if(write && !full) begin
        if(wr_pointer == DEPTH-1'b1)
            wr_pointer <= 0;
        else
            wr_pointer <= wr_pointer + 1;
    end
end

always @(posedge clk)
    if(read && !empty)
        if(rd_pointer == DEPTH-1'b1)
            empty <= (wr_pointer == 0);
        else
            empty <= (wr_pointer == rd_pointer+1'b1);
    else
        empty <= empty_loc;

assign empty_loc = (wr_pointer == rd_pointer);
assign full = ((wr_pointer==(DEPTH-1'b1) && rd_pointer==0) || (wr_pointer!=(DEPTH-1'b1) && wr_pointer+1'b1 == rd_pointer));

always @(posedge clk)
    if(write && !full)
        mem[wr_pointer] <= data_in;

always @(posedge clk)
    //if(read && !empty)
        data_out <= mem[rd_tmp];

always @(*) begin
    if(wr_pointer >= rd_pointer)
        size = wr_pointer - rd_pointer;
    else
        size = wr_pointer + (DEPTH-rd_pointer);
end

endmodule
