/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

// synchronizing asynchronous signals/flags, prevents metastable events

module three_stage_synchronizer #(
    parameter WIDTH = 1
) (
    input wire                  CLK,
    input wire  [WIDTH-1:0]     IN,
    output wire [WIDTH-1:0]     OUT
);

(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] out_d_ff_1;
(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] out_d_ff_2;
(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] out_d_ff_3;

always @(posedge CLK) // first stage
begin
    out_d_ff_1 <= IN;
end

always @(posedge CLK) // second stage
begin
    out_d_ff_2 <= out_d_ff_1;
end

always @(posedge CLK) // third stage
begin
    out_d_ff_3 <= out_d_ff_2;
end

assign OUT = out_d_ff_3;

endmodule
