// Xilinx UG472: https://docs.amd.com/v/u/en-US/ug472_7Series_Clocking
// Adapted from: https://github.com/nmi-leipzig/sim-x-pll/tree/850f59a
// Author: Till Mahlburg (Universität Leipzig); Year: 2019-2020; License: ISC
// Copyright 2019 Till Mahlburg
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
// SPDX-License-Identifier: ISC
`ifndef SIM_X_PLL_PERIOD_COUNT
`define SIM_X_PLL_PERIOD_COUNT

// verilator lint_off REALCVT

// period_count.v: Measures the length of the period of the input signal.

`timescale 1 ns / 1 ps

module period_count #(
    // polling resolution of the missing-clock watchdog, in ns
    parameter real RESOLUTION = 0.01
) (
    input              RST,
    input              PWRDWN,
    input              clk,
    output reg  [31:0] period_length_1000,
    output wire        clock_present
);
    realtime last_edge;
    reg have_edge;
    reg recent_edge;

    initial begin
        last_edge          = 0.0;
        have_edge          = 1'b0;
        recent_edge        = 1'b0;
        period_length_1000 = 0;
    end

    // Measure the period between two reference edges.
    always @(posedge clk or posedge RST or posedge PWRDWN) begin
        if (RST || PWRDWN) begin
            have_edge          <= 1'b0;
            period_length_1000 <= 0;
        end else begin
            if (have_edge)
                period_length_1000 <= $unsigned($rtoi(($realtime - last_edge) * 1000.0 + 0.5));
            last_edge <= $realtime;
            have_edge <= 1'b1;
        end
    end

    // Model reference loss after two periods; hardware timing differs.
    always begin
        #RESOLUTION;
        recent_edge = have_edge && (period_length_1000 != 0) &&
                      (($realtime - last_edge) <= 2.0 * period_length_1000 / 1000.0);
    end

    assign clock_present = recent_edge && !RST && !PWRDWN;

endmodule

// verilator lint_on REALCVT

`endif
