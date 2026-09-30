/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef ODDR_SIM
`define ODDR_SIM

`timescale 1ps / 1ps
`default_nettype none


// Functional interface: UG953 2026.1 and Vivado 2025.2 UNISIM.
module ODDR #(
    parameter       DDR_CLK_EDGE   = "OPPOSITE_EDGE",
    parameter       INIT           = 1'b0,
    parameter [0:0] IS_C_INVERTED  = 1'b0,
    parameter [0:0] IS_D1_INVERTED = 1'b0,
    parameter [0:0] IS_D2_INVERTED = 1'b0,
    parameter       SRTYPE         = "SYNC"
) (
    output reg  Q,
    input  wire C,
    input  wire CE,
    input  wire D1,
    input  wire D2,
    input  wire R,
    input  wire S
);
    pulldown reset_default (R);
    pulldown set_default (S);


    // Explicit leading zeros avoid implicit string-width expansion without
    // narrowing parameter overrides (including invalid longer strings).
    wire clock_internal = C ^ IS_C_INVERTED;
    wire data1_internal = D1 ^ IS_D1_INVERTED;
    wire data2_internal = D2 ^ IS_D2_INVERTED;
    wire reset_asserted = (R === 1'b1);
    wire set_asserted = (R === 1'b0) && (S === 1'b1);
    wire controls_inactive = (R === 1'b0) && (S === 1'b0);
    wire async_reset = ({40'b0, SRTYPE} == "ASYNC") && reset_asserted;
    wire async_set = ({40'b0, SRTYPE} == "ASYNC") && set_asserted;
    reg falling_data;

    initial begin
        Q            = INIT;
        falling_data = INIT;
        if ((({152'b0, DDR_CLK_EDGE} != "OPPOSITE_EDGE") &&
             ({152'b0, DDR_CLK_EDGE} != "SAME_EDGE")) ||
            (({40'b0, SRTYPE} != "SYNC") && ({40'b0, SRTYPE} != "ASYNC")) ||
            ((INIT !== 1'b0) && (INIT !== 1'b1))) begin
            $display("ERROR: ODDR invalid DDR_CLK_EDGE, SRTYPE or INIT (%m)");
            $finish;
        end
    end

    always @(posedge clock_internal or posedge async_reset or posedge async_set) begin
        if (reset_asserted) begin
            Q            <= 1'b0;
            falling_data <= 1'b0;
        end else if (set_asserted) begin
            Q            <= 1'b1;
            falling_data <= 1'b1;
        end else if (controls_inactive) begin
            if (CE === 1'b1) begin
                Q            <= data1_internal;
                falling_data <= data2_internal;
            end else if (CE == 1'b0) begin
                // UNISIM saves the held output on a disabled rising edge.
                falling_data <= Q;
            end
        end
    end

    always @(negedge clock_internal or posedge async_reset or posedge async_set) begin
        if (reset_asserted) Q <= 1'b0;
        else if (set_asserted) Q <= 1'b1;
        else if (controls_inactive && (CE === 1'b1)) begin
            Q <= ({152'b0, DDR_CLK_EDGE} == "SAME_EDGE") ? falling_data : data2_internal;
        end
    end

endmodule

`default_nettype wire
`endif
