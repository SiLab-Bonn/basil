`timescale 1 ns / 1 ps
`default_nettype none

module test_SimXilinxClockPrimitives #(
    parameter UseBase = 0
);
    reg stopped;
    reg powerdown;
    integer stop_level;
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

    reg [31:0] rounding_multiplier;
    wire [31:0] rounded_period;

    freq_gen rounding_test (
        .M_1000                (rounding_multiplier),
        .D                     (32'd1),
        .O_1000                (32'd1000),
        .RST                   (pll_reset),
        .PWRDWN                (1'b0),
        .period_stable         (1'b1),
        .ref_period_1000       (32'd10000),
        .clk                   (refclk),
        .out                   (),
        .out_period_length_1000(rounded_period)
    );

    // Check rounding below, above and at half a picosecond.
    initial begin
        rounding_multiplier = 32'd3000;
        #100;
        if (rounded_period !== 32'd3333) begin
            $display("FAIL: period must round down to 3333 ps");
            $finish;
        end
        rounding_multiplier = 32'd6000;
        #40;
        if (rounded_period !== 32'd1667) begin
            $display("FAIL: period must round up to 1667 ps");
            $finish;
        end
        rounding_multiplier = 32'd32000;
        #40;
        if (rounded_period !== 32'd313) begin
            $display("FAIL: half-picosecond tie must round up to 313 ps");
            $finish;
        end
    end

    initial begin
        stopped    = 1'b0;
        powerdown  = 1'b0;
        refclk     = 1'b0;
        refclk_n   = 1'b1;
        measure    = 1'b0;
        pll_reset  = 1'b1;
        clk0_edges = 0;
        clk1_edges = 0;
        #30 pll_reset = 1'b0;
    end

    always #5 begin
        if (!stopped) begin
            refclk   = !refclk;
            refclk_n = !refclk_n;
        end
    end

    always @(posedge pll_clk0) begin
        if (measure) clk0_edges = clk0_edges + 1;
    end

    always @(posedge pll_clk1) begin
        if (measure) clk1_edges = clk1_edges + 1;
    end

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
                .CLKIN2  (1'b0),
                .CLKINSEL(1'b1),
                .CLKFBIN (pll_feedback),
                .PWRDWN  (powerdown),
                .RST     (pll_reset),
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

    initial begin
        #1;
        if (gte_clk !== refclk) begin
            $display("FAIL: IBUFDS_GTE2 full-rate output");
            $finish;
        end

        wait (pll_locked === 1'b1);
        clk0_edges = 0;
        clk1_edges = 0;
        measure    = 1'b1;
        #200;
        measure = 1'b0;

        // Check 100 MHz and 400 MHz outputs with one edge of tolerance.
        if ((clk0_edges < 19) || (clk0_edges > 21)) begin
            $display("FAIL: PLLE2_ADV CLKOUT0 edges=%0d", clk0_edges);
            $finish;
        end
        if ((clk1_edges < 79) || (clk1_edges > 81)) begin
            $display("FAIL: PLLE2_ADV CLKOUT1 edges=%0d", clk1_edges);
            $finish;
        end

        // Check reference loss and recovery at both input levels.
        for (stop_level = 0; stop_level < 2; stop_level = stop_level + 1) begin
            if (stop_level == 0) @(negedge refclk);
            else @(posedge refclk);
            #0.001 stopped = 1'b1;
            #40;
            if (pll_locked !== 1'b0) begin
                $display("FAIL: lock survives reference loss");
                $finish;
            end
            clk0_edges = 0;
            clk1_edges = 0;
            measure    = 1'b1;
            #200;
            measure = 1'b0;
            if ((clk0_edges != 0) || (clk1_edges != 0) ||
                (pll_clk0 !== 1'b0) || (pll_clk1 !== 1'b0) ||
                (pll_feedback !== 1'b0) || (pll_locked !== 1'b0)) begin
                $display("FAIL: outputs remain active without reference");
                $finish;
            end
            stopped = 1'b0;
            wait (pll_locked === 1'b1);
            clk0_edges = 0;
            clk1_edges = 0;
            measure    = 1'b1;
            #200;
            measure = 1'b0;
            if ((clk0_edges < 19) || (clk0_edges > 21) ||
                (clk1_edges < 79) || (clk1_edges > 81)) begin
                $display("FAIL: incorrect frequency after reference return");
                $finish;
            end
        end

        powerdown = 1'b1;
        #40;
        if ((pll_locked !== 1'b0) || (pll_clk0 !== 1'b0)) begin
            $display("FAIL: powerdown does not clear lock/output");
            $finish;
        end
        powerdown = 1'b0;
        wait (pll_locked === 1'b1);
        pll_reset = 1'b1;
        #40;
        if ((pll_locked !== 1'b0) || (pll_clk0 !== 1'b0)) begin
            $display("FAIL: reset does not clear lock/output");
            $finish;
        end
        pll_reset = 1'b0;
        wait (pll_locked === 1'b1);

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
