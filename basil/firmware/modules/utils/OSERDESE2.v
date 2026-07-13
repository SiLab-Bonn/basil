/*
 * Behavioral simulation model for the Xilinx 7-series OSERDESE2 primitive.
 *
 * The D1-first DDR mapping and 10-bit master/slave cascade convention are
 * based on https://github.com/fcayci/vhdl-hdmi-out commit 8c3317a
 * (rtl/serializer.vhd).
 *
 * Copyright 2017 Furkan Cayci
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *
 * SPDX-License-Identifier: MIT
 */
`ifndef OSERDESE2_SIM
`define OSERDESE2_SIM

`timescale 1ps / 1ps
`default_nettype none

module OSERDESE2 #(
    parameter         DATA_RATE_OQ       = "DDR",
    parameter         DATA_RATE_TQ       = "DDR",
    parameter integer DATA_WIDTH         = 4,
    parameter         INIT_OQ            = 1'b0,
    parameter         INIT_TQ            = 1'b0,
    parameter         IS_CLKDIV_INVERTED = 1'b0,
    parameter         IS_CLK_INVERTED    = 1'b0,
    parameter         IS_D1_INVERTED     = 1'b0,
    parameter         IS_D2_INVERTED     = 1'b0,
    parameter         IS_D3_INVERTED     = 1'b0,
    parameter         IS_D4_INVERTED     = 1'b0,
    parameter         IS_D5_INVERTED     = 1'b0,
    parameter         IS_D6_INVERTED     = 1'b0,
    parameter         IS_D7_INVERTED     = 1'b0,
    parameter         IS_D8_INVERTED     = 1'b0,
    parameter         IS_T1_INVERTED     = 1'b0,
    parameter         IS_T2_INVERTED     = 1'b0,
    parameter         IS_T3_INVERTED     = 1'b0,
    parameter         IS_T4_INVERTED     = 1'b0,
    parameter         SERDES_MODE        = "MASTER",
    parameter         SRVAL_OQ           = 1'b0,
    parameter         SRVAL_TQ           = 1'b0,
    parameter         TBYTE_CTL          = "FALSE",
    parameter         TBYTE_SRC          = "FALSE",
    parameter integer TRISTATE_WIDTH     = 4
) (
    output wire OFB,
    output reg  OQ,
    output wire SHIFTOUT1,
    output wire SHIFTOUT2,
    output wire TBYTEOUT,
    output wire TFB,
    output reg  TQ,
    input  wire CLK,
    input  wire CLKDIV,
    input  wire D1,
    input  wire D2,
    input  wire D3,
    input  wire D4,
    input  wire D5,
    input  wire D6,
    input  wire D7,
    input  wire D8,
    input  wire OCE,
    input  wire RST,
    input  wire SHIFTIN1,
    input  wire SHIFTIN2,
    input  wire T1,
    input  wire T2,
    input  wire T3,
    input  wire T4,
    input  wire TBYTEIN,
    input  wire TCE
);
    localparam integer ModelDataWidth = (DATA_WIDTH > 10) ? 10 : DATA_WIDTH;

    wire clk_internal;
    wire clkdiv_internal;
    wire [7:0] data_inputs;
    wire [3:0] tristate_inputs;
    reg [9:0] parallel_data;
    reg [3:0] parallel_tristate;
    integer data_index;

    assign clk_internal = CLK ^ IS_CLK_INVERTED;
    assign clkdiv_internal = CLKDIV ^ IS_CLKDIV_INVERTED;
    assign data_inputs = {
        D8 ^ IS_D8_INVERTED,
        D7 ^ IS_D7_INVERTED,
        D6 ^ IS_D6_INVERTED,
        D5 ^ IS_D5_INVERTED,
        D4 ^ IS_D4_INVERTED,
        D3 ^ IS_D3_INVERTED,
        D2 ^ IS_D2_INVERTED,
        D1 ^ IS_D1_INVERTED
    };
    assign tristate_inputs = {
        T4 ^ IS_T4_INVERTED, T3 ^ IS_T3_INVERTED, T2 ^ IS_T2_INVERTED, T1 ^ IS_T1_INVERTED
    };

    assign OFB = OQ;
    assign TFB = TQ;
    assign TBYTEOUT = TBYTEIN;

    // In the 10-bit cascade shown by the reference design, slave D3 and D4
    // become the master's ninth and tenth serialized bits through these ports.
    assign SHIFTOUT1 = (SERDES_MODE == "SLAVE") ? data_inputs[2] : 1'b0;
    assign SHIFTOUT2 = (SERDES_MODE == "SLAVE") ? data_inputs[3] : 1'b0;

    initial begin
        parallel_data     = {10{INIT_OQ}};
        parallel_tristate = {4{INIT_TQ}};
        data_index        = 0;
        OQ                = INIT_OQ;
        TQ                = INIT_TQ;
    end

    // Capture the parallel word in the divided-clock domain.  Bits D1 through D8
    // occupy indices 0 through 7 so the serializer emits D1 first.  SHIFTIN1 and
    // SHIFTIN2 supply indices 8 and 9 for the common 10-bit master/slave cascade.
    always @(posedge clkdiv_internal or posedge RST) begin
        if (RST) begin
            parallel_data     <= {10{SRVAL_OQ}};
            parallel_tristate <= {4{SRVAL_TQ}};
        end else begin
            if (OCE) parallel_data <= {SHIFTIN2, SHIFTIN1, data_inputs};
            if (TCE) parallel_tristate <= tristate_inputs;
        end
    end

    generate
        if (DATA_RATE_OQ == "DDR") begin : g_ddr_output
            always @(posedge clk_internal or negedge clk_internal or posedge RST) begin
                if (RST) begin
                    OQ         <= SRVAL_OQ;
                    TQ         <= SRVAL_TQ;
                    data_index <= 0;
                end else begin
                    if (OCE) begin
                        OQ <= parallel_data[data_index];

                        if (data_index == ModelDataWidth - 1) data_index <= 0;
                        else data_index <= data_index + 1;
                    end

                    if (TBYTE_CTL == "TRUE" && TBYTE_SRC == "TRUE") begin
                        TQ <= TBYTEIN;
                    end else if (TCE) begin
                        if (TRISTATE_WIDTH == 1) TQ <= parallel_tristate[0];
                        else TQ <= parallel_tristate[data_index%4];
                    end
                end
            end
        end else begin : g_sdr_output
            always @(posedge clk_internal or posedge RST) begin
                if (RST) begin
                    OQ         <= SRVAL_OQ;
                    TQ         <= SRVAL_TQ;
                    data_index <= 0;
                end else begin
                    if (OCE) begin
                        OQ <= parallel_data[data_index];

                        if (data_index == ModelDataWidth - 1) data_index <= 0;
                        else data_index <= data_index + 1;
                    end

                    if (TBYTE_CTL == "TRUE" && TBYTE_SRC == "TRUE") begin
                        TQ <= TBYTEIN;
                    end else if (TCE) begin
                        if (TRISTATE_WIDTH == 1) TQ <= parallel_tristate[0];
                        else TQ <= parallel_tristate[data_index%4];
                    end
                end
            end
        end
    endgenerate

endmodule

`endif
