// Xilinx UG953 (2026.1): https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/PLLE2_ADV
// Xilinx UG472: https://docs.amd.com/v/u/en-US/ug472_7Series_Clocking
// Xilinx XAPP888: https://docs.amd.com/v/u/en-US/xapp888_7Series_DynamicRecon
// Adapted from: https://github.com/nmi-leipzig/sim-x-pll/tree/850f59a
// Author: Till Mahlburg (Universität Leipzig); Copyright: 2019; License: ISC
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
`ifndef SIM_X_PLL_PLLE2_ADV
`define SIM_X_PLL_PLLE2_ADV

`timescale 1 ns / 1 ps

module PLLE2_ADV #(
    parameter               BANDWIDTH            = "OPTIMIZED",
    parameter integer       CLKFBOUT_MULT        = 5,
    parameter real          CLKFBOUT_PHASE       = 0.000,
    parameter real          CLKIN1_PERIOD        = 0.000,
    parameter real          CLKIN2_PERIOD        = 0.000,
    parameter integer       CLKOUT0_DIVIDE       = 1,
    parameter real          CLKOUT0_DUTY_CYCLE   = 0.500,
    parameter real          CLKOUT0_PHASE        = 0.000,
    parameter integer       CLKOUT1_DIVIDE       = 1,
    parameter real          CLKOUT1_DUTY_CYCLE   = 0.500,
    parameter real          CLKOUT1_PHASE        = 0.000,
    parameter integer       CLKOUT2_DIVIDE       = 1,
    parameter real          CLKOUT2_DUTY_CYCLE   = 0.500,
    parameter real          CLKOUT2_PHASE        = 0.000,
    parameter integer       CLKOUT3_DIVIDE       = 1,
    parameter real          CLKOUT3_DUTY_CYCLE   = 0.500,
    parameter real          CLKOUT3_PHASE        = 0.000,
    parameter integer       CLKOUT4_DIVIDE       = 1,
    parameter real          CLKOUT4_DUTY_CYCLE   = 0.500,
    parameter real          CLKOUT4_PHASE        = 0.000,
    parameter integer       CLKOUT5_DIVIDE       = 1,
    parameter real          CLKOUT5_DUTY_CYCLE   = 0.500,
    parameter real          CLKOUT5_PHASE        = 0.000,
    parameter               COMPENSATION         = "ZHOLD",
    parameter integer       DIVCLK_DIVIDE        = 1,
    parameter         [0:0] IS_CLKINSEL_INVERTED = 1'b0,
    parameter         [0:0] IS_PWRDWN_INVERTED   = 1'b0,
    parameter         [0:0] IS_RST_INVERTED      = 1'b0,
    parameter real          REF_JITTER1          = 0.010,
    parameter real          REF_JITTER2          = 0.010,
    parameter               STARTUP_WAIT         = "FALSE"
) (
    output wire        CLKFBOUT,
    output wire        CLKOUT0,
    output wire        CLKOUT1,
    output wire        CLKOUT2,
    output wire        CLKOUT3,
    output wire        CLKOUT4,
    output wire        CLKOUT5,
    output wire [15:0] DO,
    output wire        DRDY,
    output wire        LOCKED,
    input  wire        CLKFBIN,
    input  wire        CLKIN1,
    input  wire        CLKIN2,
    input  wire        CLKINSEL,
    input  wire [ 6:0] DADDR,
    input  wire        DCLK,
    input  wire        DEN,
    input  wire [15:0] DI,
    input  wire        DWE,
    input  wire        PWRDWN,
    input  wire        RST
);

    pll #(
        .BANDWIDTH         (BANDWIDTH),
        .CLKFBOUT_MULT_F   (CLKFBOUT_MULT),
        .CLKFBOUT_PHASE    (CLKFBOUT_PHASE),
        .CLKIN1_PERIOD     (CLKIN1_PERIOD),
        .CLKIN2_PERIOD     (CLKIN2_PERIOD),
        .CLKOUT0_DIVIDE_F  (CLKOUT0_DIVIDE),
        .CLKOUT1_DIVIDE    (CLKOUT1_DIVIDE),
        .CLKOUT2_DIVIDE    (CLKOUT2_DIVIDE),
        .CLKOUT3_DIVIDE    (CLKOUT3_DIVIDE),
        .CLKOUT4_DIVIDE    (CLKOUT4_DIVIDE),
        .CLKOUT5_DIVIDE    (CLKOUT5_DIVIDE),
        .CLKOUT0_DUTY_CYCLE(CLKOUT0_DUTY_CYCLE),
        .CLKOUT1_DUTY_CYCLE(CLKOUT1_DUTY_CYCLE),
        .CLKOUT2_DUTY_CYCLE(CLKOUT2_DUTY_CYCLE),
        .CLKOUT3_DUTY_CYCLE(CLKOUT3_DUTY_CYCLE),
        .CLKOUT4_DUTY_CYCLE(CLKOUT4_DUTY_CYCLE),
        .CLKOUT5_DUTY_CYCLE(CLKOUT5_DUTY_CYCLE),
        .CLKOUT0_PHASE     (CLKOUT0_PHASE),
        .CLKOUT1_PHASE     (CLKOUT1_PHASE),
        .CLKOUT2_PHASE     (CLKOUT2_PHASE),
        .CLKOUT3_PHASE     (CLKOUT3_PHASE),
        .CLKOUT4_PHASE     (CLKOUT4_PHASE),
        .CLKOUT5_PHASE     (CLKOUT5_PHASE),
        .DIVCLK_DIVIDE     (DIVCLK_DIVIDE),
        .REF_JITTER1       (REF_JITTER1),
        .REF_JITTER2       (REF_JITTER2),
        .STARTUP_WAIT      (STARTUP_WAIT),
        .COMPENSATION      (COMPENSATION),
        .MODULE_TYPE       ("PLLE2_ADV")
    ) plle2_adv (
        .CLKOUT0 (CLKOUT0),
        .CLKOUT1 (CLKOUT1),
        .CLKOUT2 (CLKOUT2),
        .CLKOUT3 (CLKOUT3),
        .CLKOUT4 (CLKOUT4),
        .CLKOUT5 (CLKOUT5),
        .CLKFBOUT(CLKFBOUT),
        .LOCKED  (LOCKED),
        .CLKIN1  (CLKIN1),
        .CLKIN2  (CLKIN2),
        .CLKINSEL(CLKINSEL ^ IS_CLKINSEL_INVERTED),
        .CLKFBIN (CLKFBIN),
        .PWRDWN  (PWRDWN ^ IS_PWRDWN_INVERTED),
        .RST     (RST ^ IS_RST_INVERTED),
        .DADDR   (DADDR),
        .DCLK    (DCLK),
        .DEN     (DEN),
        .DWE     (DWE),
        .DI      (DI),
        .DO      (DO),
        .DRDY    (DRDY)
    );

endmodule

`endif
