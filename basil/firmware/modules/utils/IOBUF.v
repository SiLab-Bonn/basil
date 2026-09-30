/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IOBUF_SIM
`define IOBUF_SIM

`timescale 1ps / 1ps
`default_nettype none


module IOBUF #(
    parameter integer DRIVE        = 12,
    parameter         IBUF_LOW_PWR = "TRUE",
    parameter         IOSTANDARD   = "DEFAULT",
    parameter         SLEW         = "SLOW"
) (
    output wire O,
    inout  wire IO,
    input  wire I,
    input  wire T
);

    assign IO = T ? 1'bz : I;
    buf input_buffer (O, IO);

endmodule

`endif
