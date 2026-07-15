/*
 * Adapted from https://github.com/nmi-leipzig/sim-x-pll commit 850f59a
 * (plle2_adv.v). Local changes add an include guard and match Basil's
 * Verilog-2005 formatting.
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
`ifndef SIM_X_PLL_PLLE2_ADV
`define SIM_X_PLL_PLLE2_ADV

`timescale 1 ns / 1 ps

/* A reference for the interface can be found in Xilinx UG953 page 503ff. */
module PLLE2_ADV #(
    parameter BANDWIDTH = "OPTIMIZED",
    parameter CLKFBOUT_MULT = 5,
    parameter CLKFBOUT_PHASE = 0.0,
    parameter CLKIN1_PERIOD = 0.0,
    parameter CLKIN2_PERIOD = 0.0,
    parameter CLKOUT0_DIVIDE = 1,
    parameter CLKOUT1_DIVIDE = 1,
    parameter CLKOUT2_DIVIDE = 1,
    parameter CLKOUT3_DIVIDE = 1,
    parameter CLKOUT4_DIVIDE = 1,
    parameter CLKOUT5_DIVIDE = 1,
    parameter CLKOUT0_DUTY_CYCLE = 0.5,
    parameter CLKOUT1_DUTY_CYCLE = 0.5,
    parameter CLKOUT2_DUTY_CYCLE = 0.5,
    parameter CLKOUT3_DUTY_CYCLE = 0.5,
    parameter CLKOUT4_DUTY_CYCLE = 0.5,
    parameter CLKOUT5_DUTY_CYCLE = 0.5,
    parameter CLKOUT0_PHASE = 0.0,
    parameter CLKOUT1_PHASE = 0.0,
    parameter CLKOUT2_PHASE = 0.0,
    parameter CLKOUT3_PHASE = 0.0,
    parameter CLKOUT4_PHASE = 0.0,
    parameter CLKOUT5_PHASE = 0.0,
    parameter DIVCLK_DIVIDE = 1,
    parameter REF_JITTER1 = 0.010,
    parameter REF_JITTER2 = 0.010,
    parameter STARTUP_WAIT = "FALSE",
    parameter COMPENSATION = "ZHOLD",
    parameter FPGA_TYPE = "ARTIX",
    parameter SPEED_GRADE = "-1"
) (
    output CLKOUT0,
    output CLKOUT1,
    output CLKOUT2,
    output CLKOUT3,
    output CLKOUT4,
    output CLKOUT5,
    output CLKFBOUT,
    output LOCKED,
    input CLKIN1,
    input CLKIN2,
    input CLKINSEL,
    input CLKFBIN,
    input PWRDWN,
    input RST,
    input [6:0] DADDR,
    input DCLK,
    input DEN,
    input DWE,
    input [15:0] DI,
    output [15:0] DO,
    output DRDY
);

    pll #(
        .BANDWIDTH(BANDWIDTH),
        .CLKFBOUT_MULT_F(CLKFBOUT_MULT),
        .CLKFBOUT_PHASE(CLKFBOUT_PHASE),
        .CLKIN1_PERIOD(CLKIN1_PERIOD),
        .CLKIN2_PERIOD(CLKIN2_PERIOD),
        .CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE),
        .CLKOUT1_DIVIDE(CLKOUT1_DIVIDE),
        .CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
        .CLKOUT3_DIVIDE(CLKOUT3_DIVIDE),
        .CLKOUT4_DIVIDE(CLKOUT4_DIVIDE),
        .CLKOUT5_DIVIDE(CLKOUT5_DIVIDE),
        .CLKOUT0_DUTY_CYCLE(CLKOUT0_DUTY_CYCLE),
        .CLKOUT1_DUTY_CYCLE(CLKOUT1_DUTY_CYCLE),
        .CLKOUT2_DUTY_CYCLE(CLKOUT2_DUTY_CYCLE),
        .CLKOUT3_DUTY_CYCLE(CLKOUT3_DUTY_CYCLE),
        .CLKOUT4_DUTY_CYCLE(CLKOUT4_DUTY_CYCLE),
        .CLKOUT5_DUTY_CYCLE(CLKOUT5_DUTY_CYCLE),
        .CLKOUT0_PHASE(CLKOUT0_PHASE),
        .CLKOUT1_PHASE(CLKOUT1_PHASE),
        .CLKOUT2_PHASE(CLKOUT2_PHASE),
        .CLKOUT3_PHASE(CLKOUT3_PHASE),
        .CLKOUT4_PHASE(CLKOUT4_PHASE),
        .CLKOUT5_PHASE(CLKOUT5_PHASE),
        .DIVCLK_DIVIDE(DIVCLK_DIVIDE),
        .REF_JITTER1(REF_JITTER1),
        .REF_JITTER2(REF_JITTER2),
        .STARTUP_WAIT(STARTUP_WAIT),
        .COMPENSATION(COMPENSATION),
        .MODULE_TYPE("PLLE2_ADV"),
        .FPGA_TYPE(FPGA_TYPE),
        .SPEED_GRADE(SPEED_GRADE)
    ) plle2_adv (
        .CLKOUT0(CLKOUT0),
        .CLKOUT1(CLKOUT1),
        .CLKOUT2(CLKOUT2),
        .CLKOUT3(CLKOUT3),
        .CLKOUT4(CLKOUT4),
        .CLKOUT5(CLKOUT5),
        .CLKFBOUT(CLKFBOUT),
        .LOCKED(LOCKED),
        .CLKIN1(CLKIN1),
        .CLKIN2(CLKIN2),
        .CLKINSEL(CLKINSEL),
        .CLKFBIN(CLKFBIN),
        .PWRDWN(PWRDWN),
        .RST(RST),
        .DADDR(DADDR),
        .DCLK(DCLK),
        .DEN(DEN),
        .DWE(DWE),
        .DI(DI),
        .DO(DO),
        .DRDY(DRDY)
    );

endmodule

`endif
