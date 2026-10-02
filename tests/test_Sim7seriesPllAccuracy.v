`timescale 1ps / 1ps

module test_Sim7seriesPllAccuracy #(
    parameter UseBase = 0
);
    reg clock = 1'b0;
    reg reset = 1'b1;
    reg powerdown = 1'b0;
    wire [5:0] clocks;
    wire feedback;
    wire locked;

    generate
        if (UseBase) begin : g_base
            PLLE2_BASE #(
                .CLKIN1_PERIOD     (10.0),
                .CLKFBOUT_MULT     (10),
                .CLKOUT0_DIVIDE    (2),
                .CLKOUT1_DIVIDE    (4),
                .CLKOUT2_DIVIDE    (6),
                .CLKOUT3_DIVIDE    (8),
                .CLKOUT4_DIVIDE    (10),
                .CLKOUT5_DIVIDE    (12),
                .CLKOUT1_DUTY_CYCLE(0.25),
                .CLKOUT2_PHASE     (90.0)
            ) dut (
                .CLKIN1  (clock),
                .CLKFBIN (feedback),
                .CLKFBOUT(feedback),
                .RST     (reset),
                .PWRDWN  (powerdown),
                .CLKOUT0 (clocks[0]),
                .CLKOUT1 (clocks[1]),
                .CLKOUT2 (clocks[2]),
                .CLKOUT3 (clocks[3]),
                .CLKOUT4 (clocks[4]),
                .CLKOUT5 (clocks[5]),
                .LOCKED  (locked)
            );
        end else begin : g_advanced
            PLLE2_ADV #(
                .CLKIN1_PERIOD     (10.0),
                .CLKFBOUT_MULT     (10),
                .CLKOUT0_DIVIDE    (2),
                .CLKOUT1_DIVIDE    (4),
                .CLKOUT2_DIVIDE    (6),
                .CLKOUT3_DIVIDE    (8),
                .CLKOUT4_DIVIDE    (10),
                .CLKOUT5_DIVIDE    (12),
                .CLKOUT1_DUTY_CYCLE(0.25),
                .CLKOUT2_PHASE     (90.0)
            ) dut (
                .CLKIN1  (clock),
                .CLKIN2  (1'b0),
                .CLKINSEL(1'b1),
                .CLKFBIN (feedback),
                .CLKFBOUT(feedback),
                .RST     (reset),
                .PWRDWN  (powerdown),
                .DCLK    (1'b0),
                .DADDR   (7'b0),
                .DEN     (1'b0),
                .DI      (16'b0),
                .DWE     (1'b0),
                .DO      (),
                .DRDY    (),
                .CLKOUT0 (clocks[0]),
                .CLKOUT1 (clocks[1]),
                .CLKOUT2 (clocks[2]),
                .CLKOUT3 (clocks[3]),
                .CLKOUT4 (clocks[4]),
                .CLKOUT5 (clocks[5]),
                .LOCKED  (locked)
            );
        end
    endgenerate
endmodule
