/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef OBUF_SIM
`define OBUF_SIM

`timescale 1ps / 1ps


module OBUF #(
    parameter         CAPACITANCE = "DONT_CARE",
    parameter integer DRIVE       = 12,
    parameter         IOSTANDARD  = "DEFAULT",
    parameter         SLEW        = "SLOW"
) (
    output wire O,
    input  wire I
);

    buf output_buffer (O, I);

endmodule

`endif
