/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef BASIL_UTILS_BUFG_V
`define BASIL_UTILS_BUFG_V

`timescale 1ps/1ps
`default_nettype none


module BUFG (
    input wire I,
    output wire O
);

assign O = I;

endmodule

`endif
