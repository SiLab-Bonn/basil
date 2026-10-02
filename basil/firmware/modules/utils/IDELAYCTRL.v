// Xilinx UG953 (2026.1): https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/IDELAYCTRL
// Xilinx UG471: https://docs.amd.com/v/u/en-US/ug471_7Series_SelectIO
// Model the IDELAYCTRL primitive.
`ifndef IDELAYCTRL_SIM
`define IDELAYCTRL_SIM

`timescale 1ps / 1ps

module IDELAYCTRL #(
    parameter SIM_DEVICE = "7SERIES"
) (
    output reg  RDY,
    input  wire REFCLK,
    input  wire RST
);

    time previous_rise = 0;
    time reference_period = 0;
    time previous_edge = 0;
    time watchdog_edge = 0;
    reg clock_lost = 1'b1;

    initial begin
        RDY = 1'b0;
    end

    // Measure the reference clock independently of reset's ready output.
    always @(posedge REFCLK) begin
        if (RST == 1'b0) begin
            if ((reference_period != 0) && (($time - previous_rise) > (1.5 * reference_period)))
                reference_period <= 0;
            else if (previous_rise != 0) reference_period <= $time - previous_rise;
            previous_rise <= $time;
        end
    end

    // Delayed timestamp checks detect a missing opposite edge without
    // blocking clock sampling. Old checks cannot invalidate a newer edge.
    always @(posedge REFCLK or negedge REFCLK) begin
        previous_edge = $time;
        if (reference_period != 0) begin
            clock_lost    <= 1'b0;
            watchdog_edge <= #(0.91 * reference_period) $time;
        end
    end

    always @(watchdog_edge) begin
        if ((reference_period != 0) && (watchdog_edge == previous_edge)) clock_lost <= 1'b1;
    end

    always @(RST or clock_lost) begin
        if ((RST == 1'b1) || clock_lost) RDY <= 1'b0;
        else if (RST == 1'b0) RDY <= 1'b1;
    end

endmodule

`endif
