/*
 * Adapted from https://github.com/nmi-leipzig/sim-x-pll commit 850f59a
 * (freq_gen.v). Local changes add an include guard and simulator-lint
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
`ifndef SIM_X_PLL_FREQ_GEN
`define SIM_X_PLL_FREQ_GEN

/* verilator lint_off REALCVT */
/* verilator lint_off ZERODLY */

/*
 * freq_gen.v: Generates the frequency depending on the given period length
 * while allowing manipulation using
 *     the inputs provided. Starts frequency generation on the first rising
 *    edge of the input clk after the period_stable input is 1.
 * author: Till Mahlburg
 * year: 2019-2020
 * organization: Universität Leipzig
 * license: ISC
 *
 */

`timescale 1 ns / 1 ps

module freq_gen (
    /* global multiplier in the PLL, multiplied by 1000 */
    input [31:0] M_1000,
    /* global divisor in the PLL */
    input [31:0] D,
    /* output specific divisor in the PLL, multiplied by 1000 */
    input [31:0] O_1000,

    input             RST,
    input             PWRDWN,
    /* informs the module if the given period length (ref_period) can be trusted */
    input             period_stable,
    input      [31:0] ref_period_1000,
    /* needed to achieve phase lock, by detecting the first rising edge of the clk
     * and aligning the output clk to it */
    input             clk,
    output reg        out,
    /* period length is multiplied by 1000 for higher precision */
    output reg [31:0] out_period_length_1000
);

    /* tracks when to start the frequency generation */
    reg start;

    /* generate the wanted frequency */
    always begin
        if (PWRDWN) begin
            out   <= 1'bx;
            start <= 1'bx;
            #1;
        end else if (RST) begin
            out   <= 1'b0;
            start <= 1'b0;
            #1;
        end else if (ref_period_1000 > 0 && start) begin
            /* The formula used is based on Equation 3-2 on page 72 of Xilinx UG472,
             * but adjusted to calculate the period length not the frequency.
             * Multiplying by 1.0 forces verilog to calculate with floating
             * point number. Multiplying the out_period_length_1000 by 1000 is an
             * easy solution to returning floating point numbers.
             */
            out_period_length_1000 <=
                ((ref_period_1000 / 1000.0) *
                 ((D * (O_1000 / 1000.0) * 1.0) / (M_1000 / 1000.0)) * 1000);
            out <= ~out;
            #(
                ((ref_period_1000 / 1000.0) *
                 ((D * (O_1000 / 1000.0) * 1.0) / (M_1000 / 1000.0))) / 2.0
            );
        end else begin
            out <= 1'b0;
            #1;
        end
    end

    /* detect the first rising edge of the input clk, after period_stable is achieved */
    always @(posedge clk) begin
        if (period_stable && !start) begin
            #((ref_period_1000 / 1000.0) - 1);
            start <= 1'b1;
        end else if (!period_stable) begin
            start <= 1'b0;
        end
    end

endmodule

/* verilator lint_on REALCVT */
/* verilator lint_on ZERODLY */

`endif
