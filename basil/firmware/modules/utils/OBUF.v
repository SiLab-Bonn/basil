/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef OBUF_SIM
`define OBUF_SIM

`timescale 1ps/1ps
`default_nettype none


module OBUF #(
    parameter DRIVE = 12,
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
    output wire O,
    input wire I
);

assign O = I;

endmodule

`endif
