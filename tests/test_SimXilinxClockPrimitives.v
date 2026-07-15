`timescale 1 ns / 1 ps
`default_nettype none

module test_SimXilinxClockPrimitives;
    reg refclk;
    reg refclk_n;
    reg measure;
    reg pll_reset;
    wire gte_clk;
    wire gte_clk_div2;
    wire pll_clk0;
    wire pll_clk1;
    wire pll_feedback;
    wire pll_locked;
    wire [15:0] pll_do;
    wire pll_drdy;
    integer clk0_edges;
    integer clk1_edges;

    initial begin
        refclk = 1'b0;
        refclk_n = 1'b1;
        measure = 1'b0;
        pll_reset = 1'b1;
        clk0_edges = 0;
        clk1_edges = 0;
        #30 pll_reset = 1'b0;
    end

    always #5 begin
        refclk = !refclk;
        refclk_n = !refclk_n;
    end

    always @(posedge pll_clk0) begin
        if (measure) clk0_edges = clk0_edges + 1;
    end

    always @(posedge pll_clk1) begin
        if (measure) clk1_edges = clk1_edges + 1;
    end

    IBUFDS_GTE2 input_buffer (
        .O(gte_clk),
        .ODIV2(gte_clk_div2),
        .CEB(1'b0),
        .I(refclk),
        .IB(refclk_n)
    );

    PLLE2_ADV #(
        .CLKFBOUT_MULT(8),
        .CLKIN1_PERIOD(10.0),
        .DIVCLK_DIVIDE(1),
        .CLKOUT0_DIVIDE(8),
        .CLKOUT1_DIVIDE(2)
    ) pll_under_test (
        .CLKOUT0(pll_clk0),
        .CLKOUT1(pll_clk1),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKFBOUT(pll_feedback),
        .LOCKED(pll_locked),
        .CLKIN1(gte_clk),
        .CLKIN2(1'b0),
        .CLKINSEL(1'b1),
        .CLKFBIN(pll_feedback),
        .PWRDWN(1'b0),
        .RST(pll_reset),
        .DADDR(7'd0),
        .DCLK(refclk),
        .DEN(1'b0),
        .DWE(1'b0),
        .DI(16'd0),
        .DO(pll_do),
        .DRDY(pll_drdy)
    );

    initial begin
        #1;
        if (gte_clk !== refclk) begin
            $display("FAIL: IBUFDS_GTE2 full-rate output");
            $finish;
        end

        wait (pll_locked === 1'b1);
        clk0_edges = 0;
        clk1_edges = 0;
        measure = 1'b1;
        #200;
        measure = 1'b0;

        // FIN=100 MHz, M=8 and D=1. O0=8 gives 100 MHz; O1=2 gives
        // 400 MHz. Allow one boundary edge of tolerance at each endpoint.
        if ((clk0_edges < 19) || (clk0_edges > 21)) begin
            $display("FAIL: PLLE2_ADV CLKOUT0 edges=%0d", clk0_edges);
            $finish;
        end
        if ((clk1_edges < 79) || (clk1_edges > 81)) begin
            $display("FAIL: PLLE2_ADV CLKOUT1 edges=%0d", clk1_edges);
            $finish;
        end

        $display("PASS: Xilinx clock primitive models");
        $finish;
    end

    initial begin
        #5000;
        $display("FAIL: timeout waiting for PLLE2_ADV lock");
        $finish;
    end
endmodule

`default_nettype wire
