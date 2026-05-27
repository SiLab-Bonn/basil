/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IBUF_SIM
`define IBUF_SIM

`timescale 1ps/1ps
`default_nettype none


module IBUF #(
    parameter IBUF_LOW_PWR = "TRUE",
    parameter IOSTANDARD = "DEFAULT"
) (
    output wire O,
    input wire I
);

assign O = I;

endmodule

`endif
