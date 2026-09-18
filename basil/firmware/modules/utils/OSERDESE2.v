// Xilinx UG953: https://docs.amd.com/r/2025.2-English/ug953-vivado-7series-libraries/OSERDESE2
// Xilinx UG471: https://docs.amd.com/v/u/en-US/ug471_7Series_SelectIO
// Adapted from: https://github.com/fcayci/vhdl-hdmi-out/tree/8c3317a/rtl/serializer.vhd
// Author: Furkan Cayci; Year: 2017; License: MIT
// Copyright 2017 Furkan Cayci
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
// SPDX-License-Identifier: MIT
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

    wire clk_internal;
    wire clkdiv_internal;
    wire [7:0] data_inputs;
    wire [3:0] tristate_inputs;
    reg [9:0] parallel_data;
    reg [3:0] parallel_tristate;
    reg [9:0] active_data;
    reg [3:0] active_tristate;
    reg data_loaded;
    reg tristate_loaded;
    reg data_consumed;
    reg tristate_consumed;
    integer data_index;
    integer tristate_index;

    assign clk_internal = CLK ^ (IS_CLK_INVERTED != 0);
    assign clkdiv_internal = CLKDIV ^ (IS_CLKDIV_INVERTED != 0);
    assign data_inputs = {
        D8 ^ (IS_D8_INVERTED != 0),
        D7 ^ (IS_D7_INVERTED != 0),
        D6 ^ (IS_D6_INVERTED != 0),
        D5 ^ (IS_D5_INVERTED != 0),
        D4 ^ (IS_D4_INVERTED != 0),
        D3 ^ (IS_D3_INVERTED != 0),
        D2 ^ (IS_D2_INVERTED != 0),
        D1 ^ (IS_D1_INVERTED != 0)
    };
    assign tristate_inputs = {
        T4 ^ (IS_T4_INVERTED != 0),
        T3 ^ (IS_T3_INVERTED != 0),
        T2 ^ (IS_T2_INVERTED != 0),
        T1 ^ (IS_T1_INVERTED != 0)
    };

    assign OFB = OQ;
    assign TFB = TQ;
    assign TBYTEOUT = 1'b0;

    // Slave D3/D4 supply bits 9/10 to the master.
    assign SHIFTOUT1 = (SERDES_MODE == "SLAVE") ? data_inputs[2] : 1'b0;
    assign SHIFTOUT2 = (SERDES_MODE == "SLAVE") ? data_inputs[3] : 1'b0;

    // Stop simulation if the model does not support the selected mode.
    initial begin
        if (!(((DATA_RATE_OQ == "SDR") && (DATA_WIDTH >= 2) && (DATA_WIDTH <= 8)) ||
              ((DATA_RATE_OQ == "DDR") && ((DATA_WIDTH == 4) || (DATA_WIDTH == 6) ||
                                          (DATA_WIDTH == 8) || (DATA_WIDTH == 10))))) begin
            $display("ERROR: OSERDESE2 unsupported DATA_RATE_OQ/DATA_WIDTH (%m)");
            $finish;
        end
        if ((SERDES_MODE != "MASTER") && (SERDES_MODE != "SLAVE")) begin
            $display("ERROR: OSERDESE2 unsupported SERDES_MODE (%m)");
            $finish;
        end
        if ((SERDES_MODE == "SLAVE") && (DATA_WIDTH != 10)) begin
            $display("ERROR: OSERDESE2 only the 10-bit cascade is supported (%m)");
            $finish;
        end
        if (!(((DATA_RATE_TQ == "BUF") || (DATA_RATE_TQ == "SDR")) &&
              (TRISTATE_WIDTH == 1)) &&
            !((DATA_RATE_TQ == "DDR") &&
              ((TRISTATE_WIDTH == 1) || ((TRISTATE_WIDTH == 4) && (DATA_WIDTH == 4))))) begin
            $display("ERROR: OSERDESE2 unsupported DATA_RATE_TQ/TRISTATE_WIDTH (%m)");
            $finish;
        end
        if ((TBYTE_CTL != "FALSE") || (TBYTE_SRC != "FALSE")) begin
            $display("ERROR: OSERDESE2 tristate byte grouping is not supported (%m)");
            $finish;
        end
    end

    initial begin
        parallel_data     = {10{INIT_OQ}};
        parallel_tristate = {4{INIT_TQ}};
        active_data       = {10{INIT_OQ}};
        active_tristate   = {4{INIT_TQ}};
        data_loaded       = 1'b0;
        tristate_loaded   = 1'b0;
        data_consumed     = 1'b0;
        tristate_consumed = 1'b0;
        data_index        = 0;
        tristate_index    = 0;
        OQ                = INIT_OQ;
    end

    // Keep each active word intact until all bits have been sent.
    always @(posedge clkdiv_internal or posedge RST) begin
        if (RST) begin
            parallel_data     <= {10{SRVAL_OQ}};
            parallel_tristate <= {4{SRVAL_TQ}};
            data_loaded       <= 1'b0;
            tristate_loaded   <= 1'b0;
        end else begin
            if (OCE) begin
                parallel_data <= {SHIFTIN2, SHIFTIN1, data_inputs};
                data_loaded   <= !data_loaded;
            end
            if (TCE) begin
                parallel_tristate <= tristate_inputs;
                tristate_loaded   <= !tristate_loaded;
            end
        end
    end

    // Start each new word at D1 on the next eligible serial edge.
    always @(posedge clk_internal or negedge clk_internal or posedge RST) begin
        if (RST) begin
            OQ            <= SRVAL_OQ;
            active_data   <= {10{SRVAL_OQ}};
            data_consumed <= 1'b0;
            data_index    <= 0;
        end else if ((DATA_RATE_OQ == "DDR") || clk_internal) begin
            if (OCE) begin
                if (data_loaded != data_consumed) begin
                    active_data   <= parallel_data;
                    OQ            <= parallel_data[0];
                    data_consumed <= data_loaded;
                    data_index    <= 1;
                end else begin
                    OQ <= active_data[data_index];
                    if (data_index == DATA_WIDTH - 1) data_index <= 0;
                    else data_index <= data_index + 1;
                end
            end
        end
    end

    generate
        if (DATA_RATE_TQ == "BUF") begin : g_tristate_buffer
            // BUF bypasses clocking, TCE and reset, as a combinational T1 path.
            always @* TQ = tristate_inputs[0];
        end else begin : g_tristate_serializer
            initial TQ = INIT_TQ;
            always @(posedge clk_internal or negedge clk_internal or posedge RST) begin
                if (RST) begin
                    TQ                <= SRVAL_TQ;
                    active_tristate   <= {4{SRVAL_TQ}};
                    tristate_consumed <= 1'b0;
                    tristate_index    <= 0;
                end else if ((DATA_RATE_TQ == "DDR") || clk_internal) begin
                    if (TCE) begin
                        if (tristate_loaded != tristate_consumed) begin
                            active_tristate   <= parallel_tristate;
                            TQ                <= parallel_tristate[0];
                            tristate_consumed <= tristate_loaded;
                            tristate_index    <= (TRISTATE_WIDTH == 1) ? 0 : 1;
                        end else begin
                            TQ <= active_tristate[tristate_index];
                            if (tristate_index == TRISTATE_WIDTH - 1) tristate_index <= 0;
                            else tristate_index <= tristate_index + 1;
                        end
                    end
                end
            end
        end
    endgenerate

endmodule

`default_nettype wire
`endif
