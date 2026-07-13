/*
 * Adapted from https://github.com/nmi-leipzig/sim-x-pll commit 850f59a
 * (period_check.v). Local changes add an include guard and simulator-lint
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
`ifndef SIM_X_PLL_PERIOD_CHECK
`define SIM_X_PLL_PERIOD_CHECK

/*
 * period_check.v: Determines if the given input has a stable value.
 * author: Till Mahlburg
 * year: 2019
 * organization: Universität Leipzig
 * license: ISC
 *
 */

`timescale 1 ns / 1 ps

module period_check (
    input             RST,
    input             PWRDWN,
    input             clk,
    input      [31:0] period_length,
    output reg        period_stable
);

    /* tracks the last period length measured */
    integer period_length_last;

    /* checks if the measured period length didn't change since the last rising edge of the clk */
    always @(posedge clk or posedge RST or posedge PWRDWN) begin
        if (PWRDWN) begin
            period_stable      <= 1'bx;
            period_length_last <= 0;
        end else if (RST) begin
            period_stable      <= 1'b0;
            period_length_last <= 0;
        end else if (period_length == period_length_last && period_length != 0) begin
            period_stable      <= 1'b1;
            period_length_last <= period_length;
        end else begin
            period_stable      <= 1'b0;
            period_length_last <= period_length;
        end
    end

endmodule

`endif
