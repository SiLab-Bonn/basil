/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module IBUFDS 
#(   
    parameter DIFF_TERM = "TRUE",
    parameter IOSTANDARD   = "LVDS_25"
 )
(
    output wire O, 
    input wire I, IB
);

assign O = I && !IB;

endmodule
