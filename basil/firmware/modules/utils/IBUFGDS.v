/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IBUFGDS_SIM
`define IBUFGDS_SIM

`timescale 1ps / 1ps

module IBUFGDS #(
    parameter CAPACITANCE      = "DONT_CARE",
    parameter DIFF_TERM        = "FALSE",
    parameter IBUF_DELAY_VALUE = "0",
    parameter IBUF_LOW_PWR     = "TRUE",
    parameter IOSTANDARD       = "DEFAULT"
) (
    output wire O,
    input  wire I,
    input  wire IB
);

    // Vivado retargets the clock-input alias to IBUFDS with bias disabled.
    IBUFDS #(
        .CAPACITANCE     (CAPACITANCE),
        .DIFF_TERM       (DIFF_TERM),
        .DQS_BIAS        ("FALSE"),
        .IBUF_DELAY_VALUE(IBUF_DELAY_VALUE),
        .IBUF_LOW_PWR    (IBUF_LOW_PWR),
        .IFD_DELAY_VALUE ("AUTO"),
        .IOSTANDARD      (IOSTANDARD)
    ) input_buffer (
        .O (O),
        .I (I),
        .IB(IB)
    );

endmodule

`endif
