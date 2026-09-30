// Xilinx UG953 (2026.1): https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/PLLE2_BASE
// Xilinx UG472: https://docs.amd.com/v/u/en-US/ug472_7Series_Clocking
// Adapted from: https://github.com/nmi-leipzig/sim-x-pll/tree/850f59a
// Author: Till Mahlburg (Universität Leipzig); Copyright: 2019-2020; License: ISC
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
`ifndef SIM_X_PLL_PLLE2_BASE
`define SIM_X_PLL_PLLE2_BASE

// plle2_base.v: Simulates the PLLE2_BASE pll of the xilinx 7 series. This is just a wrapper around
// the actual logic found in pll.v

`timescale 1 ns / 1 ps

// Functional port and parameter order matches Vivado 2025.2 UNISIM.
module PLLE2_BASE #(
    parameter         BANDWIDTH          = "OPTIMIZED",
    parameter integer CLKFBOUT_MULT      = 5,
    parameter real    CLKFBOUT_PHASE     = 0.000,
    parameter real    CLKIN1_PERIOD      = 0.000,
    parameter integer CLKOUT0_DIVIDE     = 1,
    parameter real    CLKOUT0_DUTY_CYCLE = 0.500,
    parameter real    CLKOUT0_PHASE      = 0.000,
    parameter integer CLKOUT1_DIVIDE     = 1,
    parameter real    CLKOUT1_DUTY_CYCLE = 0.500,
    parameter real    CLKOUT1_PHASE      = 0.000,
    parameter integer CLKOUT2_DIVIDE     = 1,
    parameter real    CLKOUT2_DUTY_CYCLE = 0.500,
    parameter real    CLKOUT2_PHASE      = 0.000,
    parameter integer CLKOUT3_DIVIDE     = 1,
    parameter real    CLKOUT3_DUTY_CYCLE = 0.500,
    parameter real    CLKOUT3_PHASE      = 0.000,
    parameter integer CLKOUT4_DIVIDE     = 1,
    parameter real    CLKOUT4_DUTY_CYCLE = 0.500,
    parameter real    CLKOUT4_PHASE      = 0.000,
    parameter integer CLKOUT5_DIVIDE     = 1,
    parameter real    CLKOUT5_DUTY_CYCLE = 0.500,
    parameter real    CLKOUT5_PHASE      = 0.000,
    parameter integer DIVCLK_DIVIDE      = 1,
    parameter real    REF_JITTER1        = 0.010,
    parameter         STARTUP_WAIT       = "FALSE"
) (
    output wire CLKFBOUT,
    output wire CLKOUT0,
    output wire CLKOUT1,
    output wire CLKOUT2,
    output wire CLKOUT3,
    output wire CLKOUT4,
    output wire CLKOUT5,
    output wire LOCKED,
    input  wire CLKFBIN,
    input  wire CLKIN1,
    input  wire PWRDWN,
    input  wire RST
);
    wire [15:0] DO;
    wire DRDY;

    pll #(
        .BANDWIDTH      (BANDWIDTH),
        .CLKFBOUT_MULT_F(CLKFBOUT_MULT),
        .CLKFBOUT_PHASE (CLKFBOUT_PHASE),
        .CLKIN1_PERIOD  (CLKIN1_PERIOD),
        .CLKIN2_PERIOD  (0.000),

        .CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE),
        .CLKOUT1_DIVIDE  (CLKOUT1_DIVIDE),
        .CLKOUT2_DIVIDE  (CLKOUT2_DIVIDE),
        .CLKOUT3_DIVIDE  (CLKOUT3_DIVIDE),
        .CLKOUT4_DIVIDE  (CLKOUT4_DIVIDE),
        .CLKOUT5_DIVIDE  (CLKOUT5_DIVIDE),

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
        .REF_JITTER1  (REF_JITTER1),
        .REF_JITTER2  (0.010),
        .STARTUP_WAIT (STARTUP_WAIT),
        .COMPENSATION ("ZHOLD"),

        .MODULE_TYPE("PLLE2_BASE")
    ) plle2_base (
        .CLKOUT0(CLKOUT0),
        .CLKOUT1(CLKOUT1),
        .CLKOUT2(CLKOUT2),
        .CLKOUT3(CLKOUT3),
        .CLKOUT4(CLKOUT4),
        .CLKOUT5(CLKOUT5),

        .CLKFBOUT(CLKFBOUT),
        .LOCKED  (LOCKED),

        .CLKIN1  (CLKIN1),
        .CLKIN2  (1'b0),
        .CLKINSEL(1'b1),

        .PWRDWN (PWRDWN),
        .RST    (RST),
        .CLKFBIN(CLKFBIN),

        .DADDR(7'h00),
        .DCLK (1'b0),
        .DEN  (1'b0),
        .DWE  (1'b0),
        .DI   (16'h0),

        .DO  (DO),
        .DRDY(DRDY)
    );
endmodule

`endif
