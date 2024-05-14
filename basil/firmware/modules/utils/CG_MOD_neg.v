/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module CG_MOD_neg (
    ck_in,
    enable,
    ck_out
);

input ck_in,enable;
output ck_out;
reg enl;

// verilator lint_off LATCH
always @(ck_in or enable)
if (ck_in)
    enl = enable;
// verilator lint_on LATCH

assign ck_out = ck_in | ~enl;

endmodule
