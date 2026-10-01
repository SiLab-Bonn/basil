// Xilinx UG953: https://docs.amd.com/r/2025.2-English/ug953-vivado-7series-libraries/IDELAYE2
// Xilinx UG471: https://docs.amd.com/v/u/en-US/ug471_7Series_SelectIO
// Model the IDELAYE2 primitive.
`ifndef IDELAYE2_SIM
`define IDELAYE2_SIM

`timescale 1ps / 1ps

// verilator lint_off ZERODLY
// verilator lint_off WIDTHEXPAND

module IDELAYE2 #(
    parameter               CINVCTRL_SEL          = "FALSE",
    parameter               DELAY_SRC             = "IDATAIN",
    parameter               HIGH_PERFORMANCE_MODE = "FALSE",
    parameter               IDELAY_TYPE           = "FIXED",
    parameter integer       IDELAY_VALUE          = 0,
    parameter         [0:0] IS_C_INVERTED         = 1'b0,
    parameter         [0:0] IS_DATAIN_INVERTED    = 1'b0,
    parameter         [0:0] IS_IDATAIN_INVERTED   = 1'b0,
    parameter               PIPE_SEL              = "FALSE",
    parameter real          REFCLK_FREQUENCY      = 200.0,
    parameter               SIGNAL_PATTERN        = "DATA"
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
    // Slang does not count parameter uses in delay controls.
    (* maybe_unused *) localparam real FixedDelayPs = 600.0;
    (* maybe_unused *) localparam integer TapDelayPs = (REFCLK_FREQUENCY >= 390.0) ? 39 :
                                                     (REFCLK_FREQUENCY >= 290.0) ? 52 : 78;

    wire delay_input;
    wire delay_clock;
    reg [4:0] tap_count;
    reg [4:0] pipelined_count;
    reg [4:0] valid_count = 5'b0;
    wire [31:0] delayed_taps;
    wire selected_tap;
    genvar tap;

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

    // Unknown count bits retain the last complete input value.
    always @(CNTVALUEIN) begin
        if ((^CNTVALUEIN) !== 1'bx) valid_count = CNTVALUEIN;
    end

    always @(posedge delay_clock) begin
        if (REGRST == 1'b1) pipelined_count <= 5'b0;
        else if ((REGRST == 1'b0) && (LDPIPEEN == 1'b1)) pipelined_count <= valid_count;

        if (IDELAY_TYPE != "FIXED") begin
            if (LD == 1'b1) begin
                if (IDELAY_TYPE == "VARIABLE") tap_count <= IDELAY_VALUE[4:0];
                else if (PIPE_SEL == "TRUE") tap_count <= pipelined_count;
                else tap_count <= valid_count;
            end else if ((LD == 1'b0) && (CE == 1'b1)) begin
                if (INC == 1'b1) tap_count <= (tap_count == 5'd31) ? 5'd0 : tap_count + 1'b1;
                else if (INC == 1'b0) tap_count <= (tap_count == 5'd0) ? 5'd31 : tap_count - 1'b1;
            end
        end
    end

    // Continuous tap delays also model pulse rejection and tap switching
    // while an input transition is in flight. The output delay is transport.
    assign delayed_taps[0] = delay_input;
    generate
        for (tap = 1; tap < 32; tap = tap + 1) begin : g_delay_taps
            assign #(TapDelayPs) delayed_taps[tap] = delayed_taps[tap-1];
        end
    endgenerate
    assign selected_tap = delayed_taps[tap_count];
    always @(selected_tap) DATAOUT <= #(FixedDelayPs) selected_tap;

endmodule

// verilator lint_on ZERODLY
// verilator lint_on WIDTHEXPAND

`endif
