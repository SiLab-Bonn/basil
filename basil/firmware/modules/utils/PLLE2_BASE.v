// Blackbox simulation model for PLLE2_BASE primitive
// Xilinx PLL base module
(* blackbox *)
module PLLE2_BASE #(
    parameter BANDWIDTH = "OPTIMIZED",
    parameter CLKFBOUT_MULT = 4,
    parameter CLKFBOUT_PHASE = 0.0,
    parameter CLKIN1_PERIOD = 0.0,
    parameter DIVCLK_DIVIDE = 1,
    parameter REF_JITTER1 = 0.0,
    parameter STARTUP_WAIT = "FALSE",
    parameter CLKOUT0_DIVIDE = 1,
    parameter CLKOUT0_DUTY_CYCLE = 50.0,
    parameter CLKOUT0_PHASE = 0.0,
    parameter CLKOUT1_DIVIDE = 1,
    parameter CLKOUT1_DUTY_CYCLE = 50.0,
    parameter CLKOUT1_PHASE = 0.0,
    parameter CLKOUT2_DIVIDE = 1,
    parameter CLKOUT2_DUTY_CYCLE = 50.0,
    parameter CLKOUT2_PHASE = 0.0,
    parameter CLKOUT3_DIVIDE = 1,
    parameter CLKOUT3_DUTY_CYCLE = 50.0,
    parameter CLKOUT3_PHASE = 0.0,
    parameter CLKOUT4_DIVIDE = 1,
    parameter CLKOUT4_DUTY_CYCLE = 50.0,
    parameter CLKOUT4_PHASE = 0.0,
    parameter CLKOUT5_DIVIDE = 1,
    parameter CLKOUT5_DUTY_CYCLE = 50.0,
    parameter CLKOUT5_PHASE = 0.0
)(
    output wire CLKFBOUT,
    output wire CLKOUT0,
    output wire CLKOUT1,
    output wire CLKOUT2,
    output wire CLKOUT3,
    output wire CLKOUT4,
    output wire CLKOUT5,
    output wire LOCKED,
    input wire CLKIN1,
    input wire PWRDWN,
    input wire RST,
    input wire CLKFBIN
);
endmodule
