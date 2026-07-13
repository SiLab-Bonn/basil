/**
 * Behavioral simulation model for the Xilinx 7-series ODELAYE2 primitive.
 */
`ifndef ODELAYE2_SIM
`define ODELAYE2_SIM

`timescale 1ps / 1ps
`default_nettype none

/* verilator lint_off ZERODLY */
/* verilator lint_off WIDTHEXPAND */

module ODELAYE2 #(
    parameter         CINVCTRL_SEL          = "FALSE",
    parameter         DELAY_SRC             = "ODATAIN",
    parameter         HIGH_PERFORMANCE_MODE = "FALSE",
    parameter         IS_C_INVERTED         = 1'b0,
    parameter         IS_ODATAIN_INVERTED   = 1'b0,
    parameter         ODELAY_TYPE           = "FIXED",
    parameter integer ODELAY_VALUE          = 0,
    parameter         PIPE_SEL              = "FALSE",
    parameter real    REFCLK_FREQUENCY      = 200.0,
    parameter         SIGNAL_PATTERN        = "DATA"
) (
    output wire [4:0] CNTVALUEOUT,
    output reg        DATAOUT,
    input  wire       C,
    input  wire       CE,
    input  wire       CINVCTRL,
    input  wire       CLKIN,
    input  wire [4:0] CNTVALUEIN,
    input  wire       INC,
    input  wire       LD,
    input  wire       LDPIPEEN,
    input  wire       ODATAIN,
    input  wire       REGRST
);
    localparam real FixedDelayPs = 600.0;
    localparam real TapDelayPs = 1000000.0 / (64.0 * REFCLK_FREQUENCY);

    wire delay_input;
    wire delay_clock;
    reg [4:0] tap_count;
    reg [4:0] pipelined_count;

    assign delay_input = (DELAY_SRC == "CLKIN") ? CLKIN : (ODATAIN ^ IS_ODATAIN_INVERTED);
    assign delay_clock = (C ^ IS_C_INVERTED) ^ ((CINVCTRL_SEL == "TRUE") ? CINVCTRL : 1'b0);
    assign CNTVALUEOUT = tap_count;

    initial begin
        tap_count = ((ODELAY_TYPE == "VAR_LOAD") ||
                 (ODELAY_TYPE == "VAR_LOAD_PIPE")) ? 5'b0 : ODELAY_VALUE[4:0];
        pipelined_count = 5'b0;
        DATAOUT = 1'b0;
    end

    always @(posedge delay_clock) begin
        if (REGRST) pipelined_count <= 5'b0;
        else if (LDPIPEEN) pipelined_count <= CNTVALUEIN;

        if (ODELAY_TYPE != "FIXED") begin
            if (LD) begin
                if (ODELAY_TYPE == "VARIABLE") tap_count <= ODELAY_VALUE[4:0];
                else if (PIPE_SEL == "TRUE") tap_count <= pipelined_count;
                else tap_count <= CNTVALUEIN;
            end else if (CE) begin
                if (INC) tap_count <= (tap_count == 5'd31) ? 5'd0 : tap_count + 1'b1;
                else tap_count <= (tap_count == 5'd0) ? 5'd31 : tap_count - 1'b1;
            end
        end
    end

    always @(delay_input) DATAOUT <= #(FixedDelayPs + tap_count * TapDelayPs) delay_input;

endmodule

/* verilator lint_on ZERODLY */
/* verilator lint_on WIDTHEXPAND */

`endif
