/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef OBUFDS_SIM
`define OBUFDS_SIM

`timescale 1ps / 1ps
`default_nettype none

module OBUFDS #(
    parameter CAPACITANCE = "DONT_CARE",
    parameter IOSTANDARD  = "DEFAULT",
    parameter SLEW        = "SLOW"
) (
    output wire O,
    output wire OB,
    input  wire I
);

    buf positive_buffer (O, I);
    not negative_buffer (OB, I);

endmodule

`endif
