/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IBUF_SIM
`define IBUF_SIM

`timescale 1ps / 1ps


module IBUF #(
    parameter CAPACITANCE      = "DONT_CARE",
    parameter IBUF_DELAY_VALUE = "0",
    parameter IBUF_LOW_PWR     = "TRUE",
    parameter IFD_DELAY_VALUE  = "AUTO",
    parameter IOSTANDARD       = "DEFAULT"
) (
    output wire O,
    input  wire I
);

    buf output_buffer (O, I);

endmodule

`endif
