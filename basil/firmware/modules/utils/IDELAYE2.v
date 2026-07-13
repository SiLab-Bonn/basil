/**
 * Behavioral simulation model for the Xilinx 7-series IDELAYE2 primitive.
 */
`ifndef IDELAYE2_SIM
`define IDELAYE2_SIM

`timescale 1ps / 1ps
`default_nettype none

/* verilator lint_off ZERODLY */
/* verilator lint_off WIDTHEXPAND */

module IDELAYE2 #(
    parameter         CINVCTRL_SEL          = "FALSE",
    parameter         DELAY_SRC             = "IDATAIN",
    parameter         HIGH_PERFORMANCE_MODE = "FALSE",
    parameter         IDELAY_TYPE           = "FIXED",
    parameter integer IDELAY_VALUE          = 0,
    parameter         IS_C_INVERTED         = 1'b0,
    parameter         IS_DATAIN_INVERTED    = 1'b0,
    parameter         IS_IDATAIN_INVERTED   = 1'b0,
    parameter         PIPE_SEL              = "FALSE",
    parameter real    REFCLK_FREQUENCY      = 200.0,
    parameter         SIGNAL_PATTERN        = "DATA"
) (
    output wire [4:0] CNTVALUEOUT,
    output reg        DATAOUT,
    input  wire       C,
    input  wire       CE,
    input  wire       CINVCTRL,
    input  wire [4:0] CNTVALUEIN,
    input  wire       DATAIN,
    input  wire       IDATAIN,
    input  wire       INC,
    input  wire       LD,
    input  wire       LDPIPEEN,
    input  wire       REGRST
);
    // A 7-series IDELAYE2 has 32 taps across half a REFCLK period and a nominal
    // 600 ps fixed insertion delay in the functional model.
    localparam real FixedDelayPs = 600.0;
    localparam real TapDelayPs = 1000000.0 / (64.0 * REFCLK_FREQUENCY);

    wire delay_input;
    wire delay_clock;
    reg [4:0] tap_count;
    reg [4:0] pipelined_count;

    assign delay_input = (DELAY_SRC == "DATAIN") ?
    (DATAIN ^ IS_DATAIN_INVERTED) : (IDATAIN ^ IS_IDATAIN_INVERTED);
    assign delay_clock = (C ^ IS_C_INVERTED) ^ ((CINVCTRL_SEL == "TRUE") ? CINVCTRL : 1'b0);
    assign CNTVALUEOUT = tap_count;

    initial begin
        tap_count = ((IDELAY_TYPE == "VAR_LOAD") ||
                 (IDELAY_TYPE == "VAR_LOAD_PIPE")) ? 5'b0 : IDELAY_VALUE[4:0];
        pipelined_count = 5'b0;
        DATAOUT = 1'b0;
    end

    always @(posedge delay_clock) begin
        if (REGRST) pipelined_count <= 5'b0;
        else if (LDPIPEEN) pipelined_count <= CNTVALUEIN;

        if (IDELAY_TYPE != "FIXED") begin
            if (LD) begin
                if (IDELAY_TYPE == "VARIABLE") tap_count <= IDELAY_VALUE[4:0];
                else if (PIPE_SEL == "TRUE") tap_count <= pipelined_count;
                else tap_count <= CNTVALUEIN;
            end else if (CE) begin
                if (INC) tap_count <= (tap_count == 5'd31) ? 5'd0 : tap_count + 1'b1;
                else tap_count <= (tap_count == 5'd0) ? 5'd31 : tap_count - 1'b1;
            end
        end
    end

    // Delay expressions are evaluated when the input changes, allowing VARIABLE
    // and VAR_LOAD modes to use the current tap count as well as FIXED mode.
    always @(delay_input) DATAOUT <= #(FixedDelayPs + tap_count * TapDelayPs) delay_input;

endmodule

/* verilator lint_on ZERODLY */
/* verilator lint_on WIDTHEXPAND */

`endif
