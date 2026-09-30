/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IDDR_SIM
`define IDDR_SIM

`timescale 1ps / 1ps
`default_nettype none


// Functional interface: UG953 2026.1 and Vivado 2025.2 UNISIM.
module IDDR #(
    parameter       DDR_CLK_EDGE  = "OPPOSITE_EDGE",
    parameter       INIT_Q1       = 1'b0,
    parameter       INIT_Q2       = 1'b0,
    parameter [0:0] IS_C_INVERTED = 1'b0,
    parameter [0:0] IS_D_INVERTED = 1'b0,
    parameter       SRTYPE        = "SYNC"
) (
    output wire Q1,
    output wire Q2,
    input  wire C,
    input  wire CE,
    input  wire D,
    input  wire R,
    input  wire S
);
    // Explicit leading zeros avoid implicit string-width expansion without
    // narrowing parameter overrides (including invalid longer strings).
    wire clock_internal = C ^ IS_C_INVERTED;
    wire data_internal = D ^ IS_D_INVERTED;
    wire async_reset = ({40'b0, SRTYPE} == "ASYNC") && R;
    wire async_set = ({40'b0, SRTYPE} == "ASYNC") && S;
    reg rising_data;
    reg falling_data;
    reg rising_pipelined;
    reg falling_pipelined;

    assign Q1 = ({152'b0, DDR_CLK_EDGE} == "SAME_EDGE_PIPELINED") ? rising_pipelined : rising_data;
    assign Q2 = ({152'b0, DDR_CLK_EDGE} == "OPPOSITE_EDGE") ? falling_data : falling_pipelined;

    initial begin
        rising_data       = INIT_Q1;
        falling_data      = INIT_Q2;
        rising_pipelined  = INIT_Q1;
        falling_pipelined = INIT_Q2;
        if ((({152'b0, DDR_CLK_EDGE} != "OPPOSITE_EDGE") &&
             ({152'b0, DDR_CLK_EDGE} != "SAME_EDGE") &&
             ({152'b0, DDR_CLK_EDGE} != "SAME_EDGE_PIPELINED")) ||
            (({40'b0, SRTYPE} != "SYNC") && ({40'b0, SRTYPE} != "ASYNC")) ||
            ((INIT_Q1 !== 1'b0) && (INIT_Q1 !== 1'b1)) ||
            ((INIT_Q2 !== 1'b0) && (INIT_Q2 !== 1'b1))) begin
            $display("ERROR: IDDR invalid DDR_CLK_EDGE, SRTYPE or INIT_Q1/INIT_Q2 (%m)");
            $finish;
        end
    end

    // SAME_EDGE re-times Q2; SAME_EDGE_PIPELINED also delays Q1 by one cycle.
    always @(posedge clock_internal or posedge async_reset or posedge async_set) begin
        if (R) begin
            rising_data       <= 1'b0;
            rising_pipelined  <= 1'b0;
            falling_pipelined <= 1'b0;
        end else if (S) begin
            rising_data       <= 1'b1;
            rising_pipelined  <= 1'b1;
            falling_pipelined <= 1'b1;
        end else if (CE) begin
            rising_data       <= data_internal;
            rising_pipelined  <= rising_data;
            falling_pipelined <= falling_data;
        end
    end

    always @(negedge clock_internal or posedge async_reset or posedge async_set) begin
        if (R) falling_data <= 1'b0;
        else if (S) falling_data <= 1'b1;
        else if (CE) falling_data <= data_internal;
    end


endmodule

`endif
