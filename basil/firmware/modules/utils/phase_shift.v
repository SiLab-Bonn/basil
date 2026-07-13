/*
 * Adapted from https://github.com/nmi-leipzig/sim-x-pll commit 850f59a
 * (phase_shift.v). Local changes add an include guard and simulator-lint
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
`ifndef SIM_X_PLL_PHASE_SHIFT
`define SIM_X_PLL_PHASE_SHIFT

/* verilator lint_off ZERODLY */
/* verilator lint_off MULTIDRIVEN */

/* This timing model updates its clock and lock outputs from independent
 * edge, reset, and power-down processes. */

/*
 * phase_shift.v: Shifts the input clock by the given degree and can change
     it's duty cycle.
 * author: Till Mahlburg
 * year: 2019-2020
 * organization: Universität Leipzig
 * license: ISC
 *
 */

`timescale 1 ns / 1 ps

module phase_shift (
    input               RST,
    input               PWRDWN,
    input               clk,
    /* shift in degrees */
    input signed [31:0] shift_1000,
    /* period length of the clock */
    input        [31:0] clk_period_1000,
    /* duty cycle in percent */
    input        [31:0] duty_cycle,

    output reg lock,
    output reg clk_shifted
);

    /* The formulas used here are composed of the following:
     * - clk_period_1000 / 1000.0 calculates the actual period length, which
     *   has been multiplied by 1000 to enable a higher precision.
     * - shift * ((clk_period_1000 / 1000.0) / 360.0) calculate the basic shift
     *   as a multiple of a 360th of the period of the clk to shift
     * - if the desired shift is negative, we just add a shift by
     *   360 degrees and add the (negative) shift:
     *   clk_period + (shift * (clk_period / 360.0))
     * - to calculate the duty cycle, we delay or rush the output of
     *   0 by adding (or subtracting) the desired duty cycle in 100th
     *   of the input clk period from the default (50):
     *   (duty_cycle + 50.0) * (clk_period / 100.0)
     */

    /* calculate when to put out high */
    always @(posedge clk or posedge RST or posedge PWRDWN) begin
        if (!RST && !PWRDWN) begin
            if (shift_1000 < 0) begin
                clk_shifted <= #(
                    (clk_period_1000 / 1000.0) +
                    ((shift_1000 / 1000.0) *
                     ((clk_period_1000 / 1000.0) / 360.0))
                ) 1;
            end else begin
                clk_shifted <= #((shift_1000 / 1000.0) * ((clk_period_1000 / 1000.0) / 360.0)) 1;
            end
        end
    end

    /* calculate when to put out low and return when the phase and duty cycle is correctly set */
    always @(negedge clk or posedge RST) begin
        if (RST) begin
            clk_shifted <= 1'b0;
            lock        <= 1'b0;
        end else if (lock !== 1'bx) begin
            if (shift_1000 < 0) begin
                clk_shifted <= #(
                    (clk_period_1000 / 1000.0) +
                    ((shift_1000 / 1000.0) *
                     ((clk_period_1000 / 1000.0) / 360.0)) +
                    ((duty_cycle + 50.0) *
                     ((clk_period_1000 / 1000.0) / 100.0))
                ) 0;
                lock <= #(
                    (clk_period_1000 / 1000.0) +
                    ((shift_1000 / 1000.0) *
                     ((clk_period_1000 / 1000.0) / 360.0)) +
                    ((duty_cycle + 50.0) *
                     ((clk_period_1000 / 1000.0) / 100.0))
                ) 1'b1;
            end else begin
                clk_shifted <= #(
                    (shift_1000 / 1000.0) *
                    ((clk_period_1000 / 1000.0) / 360.0) +
                    ((duty_cycle + 50.0) *
                     ((clk_period_1000 / 1000.0) / 100.0))
                ) 0;
                lock <= #(
                    (shift_1000 / 1000.0) *
                    ((clk_period_1000 / 1000.0) / 360.0) +
                    ((duty_cycle + 50.0) *
                     ((clk_period_1000 / 1000.0) / 100.0))
                ) 1'b1;
            end
        end
    end

    /* PWRDWN for good */
    always begin
        if (PWRDWN) begin
            clk_shifted <= 1'bx;
            lock        <= 1'bx;
            #0.001;
        end else begin
            #1;
        end
        ;
    end

endmodule

/* verilator lint_on ZERODLY */
/* verilator lint_on MULTIDRIVEN */

`endif
