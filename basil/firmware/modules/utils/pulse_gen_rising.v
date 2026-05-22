/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef BASIL_UTILS_PULSE_GEN_RISING_V
`define BASIL_UTILS_PULSE_GEN_RISING_V

`timescale 1ps/1ps
`default_nettype none


module pulse_gen_rising (
    input wire clk_in,
    input wire in,
    output wire out
);

reg ff;
always @(posedge clk_in)
    ff <= in;

assign out = !ff && in;

endmodule

`endif
