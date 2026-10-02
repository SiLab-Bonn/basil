`timescale 1 ns / 1 ps

module test_Sim7seriesClockPrimitives #(
    parameter       UseBase        = 0,
    parameter [2:0] InvertControls = 3'b0
);
    reg powerdown;
    reg refclk;
    reg refclk_n;
    reg pll_reset;
    wire gte_clk;
    wire gte_clk_div2;
    wire pll_clk0;
    wire pll_clk1;
    wire pll_feedback;
    wire pll_locked;
    wire [15:0] pll_do;
    wire pll_drdy;

    IBUFDS_GTE2 input_buffer (
        .O    (gte_clk),
        .ODIV2(gte_clk_div2),
        .CEB  (1'b0),
        .I    (refclk),
        .IB   (refclk_n)
    );

    generate
        if (UseBase) begin : g_base
            PLLE2_BASE #(
                .CLKFBOUT_MULT (8),
                .CLKIN1_PERIOD (10.0),
                .DIVCLK_DIVIDE (1),
                .CLKOUT0_DIVIDE(8),
                .CLKOUT1_DIVIDE(2)
            ) pll_under_test (
                .CLKOUT0 (pll_clk0),
                .CLKOUT1 (pll_clk1),
                .CLKOUT2 (),
                .CLKOUT3 (),
                .CLKOUT4 (),
                .CLKOUT5 (),
                .CLKFBOUT(pll_feedback),
                .LOCKED  (pll_locked),
                .CLKIN1  (gte_clk),
                .CLKFBIN (pll_feedback),
                .PWRDWN  (powerdown),
                .RST     (pll_reset)
            );
        end else begin : g_adv
            PLLE2_ADV #(
                .IS_CLKINSEL_INVERTED(InvertControls[0]),
                .IS_PWRDWN_INVERTED  (InvertControls[1]),
                .IS_RST_INVERTED     (InvertControls[2]),
                .CLKFBOUT_MULT       (8),
                .CLKIN1_PERIOD       (10.0),
                .DIVCLK_DIVIDE       (1),
                .CLKOUT0_DIVIDE      (8),
                .CLKOUT1_DIVIDE      (2)
            ) pll_under_test (
                .CLKOUT0 (pll_clk0),
                .CLKOUT1 (pll_clk1),
                .CLKOUT2 (),
                .CLKOUT3 (),
                .CLKOUT4 (),
                .CLKOUT5 (),
                .CLKFBOUT(pll_feedback),
                .LOCKED  (pll_locked),
                .CLKIN1  (gte_clk),
                .CLKIN2  (1'b0),
                .CLKINSEL(1'b1 ^ InvertControls[0]),
                .CLKFBIN (pll_feedback),
                .PWRDWN  (powerdown ^ InvertControls[1]),
                .RST     (pll_reset ^ InvertControls[2]),
                .DADDR   (7'd0),
                .DCLK    (refclk),
                .DEN     (1'b0),
                .DWE     (1'b0),
                .DI      (16'd0),
                .DO      (pll_do),
                .DRDY    (pll_drdy)
            );

        end
    endgenerate

endmodule
