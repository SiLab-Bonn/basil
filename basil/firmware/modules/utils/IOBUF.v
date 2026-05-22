/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef BASIL_UTILS_IOBUF_V
`define BASIL_UTILS_IOBUF_V

`timescale 1ps/1ps
`default_nettype none


module IOBUF #(
    parameter DRIVE = 12,
    parameter IBUF_LOW_PWR = "TRUE",
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
    inout wire IO,
    input wire I,
    output wire O,
    input wire T
);

assign IO = T ? 1'bz : I;
assign O = IO;

endmodule

`endif
