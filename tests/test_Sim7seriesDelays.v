`timescale 1ps / 1ps

module test_Sim7seriesDelays #(
    parameter       OutputDelay  = 0,
    parameter       DelayType    = "VAR_LOAD",
    parameter       PipeSelect   = "FALSE",
    parameter       SourceSelect = 0,
    parameter [0:0] Invert       = 0,
    parameter       Frequency    = 200.0
);
    reg clock = 1'b0;
    reg enable = 1'b0;
    reg increment = 1'b0;
    reg load = 1'b0;
    reg load_pipe = 1'b0;
    reg reset_pipe = 1'b0;
    reg invert_clock = 1'b0;
    reg data = 1'b0;
    reg other_data = 1'b0;
    reg [4:0] count_in = 5'd0;
    wire [4:0] count_out;
    wire delayed_data;

    generate
        if (OutputDelay) begin : g_output
            ODELAYE2 #(
                .ODELAY_TYPE        (DelayType),
                .ODELAY_VALUE       (7),
                .PIPE_SEL           (PipeSelect),
                .REFCLK_FREQUENCY   (Frequency),
                .DELAY_SRC          (SourceSelect ? "CLKIN" : "ODATAIN"),
                .IS_C_INVERTED      (Invert),
                .IS_ODATAIN_INVERTED(Invert),
                .CINVCTRL_SEL       ("TRUE")
            ) dut (
                .DATAOUT    (delayed_data),
                .CNTVALUEOUT(count_out),
                .C          (clock ^ Invert),
                .CE         (enable),
                .INC        (increment),
                .LD         (load),
                .LDPIPEEN   (load_pipe),
                .REGRST     (reset_pipe),
                .CINVCTRL   (invert_clock),
                .CNTVALUEIN (count_in),
                .ODATAIN    (data ^ Invert),
                .CLKIN      (other_data)
            );
        end else begin : g_input
            IDELAYE2 #(
                .IDELAY_TYPE        (DelayType),
                .IDELAY_VALUE       (7),
                .PIPE_SEL           (PipeSelect),
                .REFCLK_FREQUENCY   (Frequency),
                .DELAY_SRC          (SourceSelect ? "DATAIN" : "IDATAIN"),
                .IS_C_INVERTED      (Invert),
                .IS_IDATAIN_INVERTED(Invert),
                .IS_DATAIN_INVERTED (Invert),
                .CINVCTRL_SEL       ("TRUE")
            ) dut (
                .DATAOUT    (delayed_data),
                .CNTVALUEOUT(count_out),
                .C          (clock ^ Invert),
                .CE         (enable),
                .INC        (increment),
                .LD         (load),
                .LDPIPEEN   (load_pipe),
                .REGRST     (reset_pipe),
                .CINVCTRL   (invert_clock),
                .CNTVALUEIN (count_in),
                .IDATAIN    (data ^ Invert),
                .DATAIN     (other_data ^ Invert)
            );
        end
    endgenerate

endmodule
