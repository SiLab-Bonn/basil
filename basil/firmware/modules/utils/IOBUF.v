/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module IOBUF (
    inout wire IO,
    input wire I,
    output wire O,
    input wire T
);

assign IO = T ? I : 1'bz;
assign O = T ? IO : 1'b0;

endmodule
