/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module CG_MOD_pos (
    input wire ck_in,
    input wire enable,
    output wire ck_out
);

wire ck_inb;
reg enl;

assign ck_inb = ~ck_in;
always_latch
if (ck_inb)
    enl = enable;
assign ck_out = ck_in & enl;

endmodule
