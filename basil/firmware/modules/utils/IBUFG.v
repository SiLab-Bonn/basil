/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef BASIL_UTILS_IBUFG_V
`define BASIL_UTILS_IBUFG_V

`timescale 1ps/1ps
`default_nettype none


module IBUFG #(
    parameter IBUF_LOW_PWR = "TRUE",
    parameter IOSTANDARD = "DEFAULT"
) (
    output wire O,
    input wire I
);

assign O = I;

endmodule

`endif
