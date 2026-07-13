/*
 * Adapted from https://github.com/nmi-leipzig/sim-x-pll commit 850f59a
 * (period_count.v). Local changes add an include guard and simulator-lint
 * compatibility fixes.
 *
 * Copyright 2019 Till Mahlburg
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * SPDX-License-Identifier: ISC
 */
`ifndef SIM_X_PLL_PERIOD_COUNT
`define SIM_X_PLL_PERIOD_COUNT

/* verilator lint_off REALCVT */
/* verilator lint_off MULTIDRIVEN */

/*
 * period_count.v: Measures the length of the period of the input signal.
 * author: Till Mahlburg
 * year: 2019-2020
 * organization: Universität Leipzig
 * license: ISC
 *
 */

`timescale 1 ns / 1 ps

module period_count #(
    /* set the precision of the period count */
    parameter real RESOLUTION = 0.01
) (
    input             RST,
    input             PWRDWN,
    input             clk,
    output reg [31:0] period_length_1000
);

    integer period_counter;

    /* count up continuously with the given resolution */
    always begin
        #0.001
        if (RST) begin
            period_counter <= 0;
        end else begin
            period_counter <= period_counter + 1;
        end
        #(RESOLUTION - 0.001);
    end

    /* output counted value and reset counter on every rising clk edge */
    always @(posedge clk or posedge RST or posedge PWRDWN) begin
        if (PWRDWN || RST) begin
            period_length_1000 <= 0;
        end else begin
            period_length_1000 <= (period_counter * RESOLUTION * 1000);
            period_counter     <= 0;
        end
    end

endmodule

/* verilator lint_on REALCVT */
/* verilator lint_on MULTIDRIVEN */

`endif
