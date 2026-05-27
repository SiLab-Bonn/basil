/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef ODDR
`define ODDR

`timescale 1ps/1ps
`default_nettype none


module ODDR #(
    parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
    parameter INIT = 1'b0,
    parameter SRTYPE = "SYNC"
)(
    output wire Q,
    input wire C,
    input wire CE,
    input wire D1,
    input wire D2,
    input wire R,
    input wire S
);

reg Q1, Q2;

always @(posedge C)
    Q1 <= D1;

always @(negedge C)
    Q2 <= D2;

assign Q = C ? Q1 & CE : Q2 & CE;

endmodule

`endif
