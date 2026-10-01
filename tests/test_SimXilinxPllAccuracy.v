`timescale 1ps / 1ps

module test_SimXilinxPllAccuracy #(
    parameter UseBase = 0
);
    reg clock = 1'b0;
    reg reset = 1'b1;
    reg powerdown = 1'b0;
    wire [5:0] clocks;
    wire feedback;
    wire locked;
    time last_rise[5:0];
    time periods[5:0];
    time high_times[5:0];
    integer index;
    genvar output_index;

    always #5000 clock = !clock;
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
        for (output_index = 0; output_index < 6; output_index = output_index + 1) begin : g_measure
            initial begin
                last_rise[output_index]  = 0;
                periods[output_index]    = 0;
                high_times[output_index] = 0;
            end
            always @(posedge clocks[output_index]) begin
                periods[output_index]   = $time - last_rise[output_index];
                last_rise[output_index] = $time;
            end
            always @(negedge clocks[output_index])
                high_times[output_index] = $time - last_rise[output_index];
        end
    endgenerate

    initial begin
        #200000 reset = 1'b0;
        #20000000;
        if (locked !== 1'b1) begin
            $display("FAIL: PLL did not lock");
            $finish;
        end
        for (index = 0; index < 6; index = index + 1) begin
            if (periods[index] != (index + 1) * 2000) begin
                $display("FAIL: output %d period %0t", index, periods[index]);
                $finish;
            end
            $display("TRACE output %d period=%0t high=%0t", index, periods[index],
                     high_times[index]);
        end
        $display("TRACE phase %0t", (last_rise[2] + 6000 - last_rise[0]) % 2000);
        if ((last_rise[2] + 6000 - last_rise[0]) % 2000 != 1500) begin
            $display("FAIL: non-default phase");
            $finish;
        end
        if (high_times[1] != 1000) begin
            $display("FAIL: non-default duty cycle");
            $finish;
        end
        powerdown = 1'b1;
        #200000;
        if (locked !== 1'b0) begin
            $display("FAIL: powerdown did not unlock");
            $finish;
        end
        $display("PASS: PLL metrics");
        $finish;
    end
endmodule
