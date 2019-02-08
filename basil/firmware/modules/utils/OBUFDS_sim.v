/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module OBUFDS 
#(
    parameter IOSTANDARD   = "LVDS_25"
 )
(
    output wire O, OB, 
    input wire I
);

assign O = I;
assign OB = !I;

endmodule
