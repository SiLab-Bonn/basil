/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef OBUFDS_SIM
`define OBUFDS_SIM

`timescale 1ps/1ps
`default_nettype none

module OBUFDS #(
    parameter IOSTANDARD = "LVDS_25",
    parameter SLEW = "SLOW"
) (
    output wire O, OB,
    input wire I
);

assign O = I;
assign OB = !I;

endmodule

`endif
