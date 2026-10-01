/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IBUFG_SIM
`define IBUFG_SIM

`timescale 1ps / 1ps


module IBUFG #(
    parameter CAPACITANCE      = "DONT_CARE",
    parameter IBUF_DELAY_VALUE = "0",
    parameter IBUF_LOW_PWR     = "TRUE",
    parameter IOSTANDARD       = "DEFAULT"
) (
    output wire O,
    input  wire I
);

    IBUF #(
        .CAPACITANCE     (CAPACITANCE),
        .IBUF_DELAY_VALUE(IBUF_DELAY_VALUE),
        .IBUF_LOW_PWR    (IBUF_LOW_PWR),
        .IFD_DELAY_VALUE ("AUTO"),
        .IOSTANDARD      (IOSTANDARD)
    ) input_buffer (
        .O(O),
        .I(I)
    );

endmodule

`endif
