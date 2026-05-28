/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IBUFGDS_SIM
`define IBUFGDS_SIM

`timescale 1ps/1ps
`default_nettype none

module IBUFGDS #(
    parameter DIFF_TERM = "TRUE",
    parameter IBUF_LOW_PWR = "FALSE",
    parameter IOSTANDARD = "LVDS_25"
) (
    output wire O,
    input wire I, IB
);

assign O = I && !IB;

endmodule

`endif
