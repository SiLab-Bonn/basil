/*
 * Behavioral simulation model for the Xilinx 7-series IBUFDS_GTE2 primitive.
 *
 * The full-rate output follows a valid differential input while CEB is low.
 * ODIV2 toggles on each full-rate rising edge, matching the primitive's
 * optional divide-by-two output closely enough for functional simulation.
 */
`ifndef IBUFDS_GTE2_SIM
`define IBUFDS_GTE2_SIM

`timescale 1 ps / 1 ps
`default_nettype none

module IBUFDS_GTE2 #(
    parameter CLKCM_CFG = "TRUE",
    parameter CLKRCV_TRST = "TRUE",
    parameter CLKSWING_CFG = 2'b11
) (
    output wire O,
    output wire ODIV2,
    input wire CEB,
    input wire I,
    input wire IB
);

    reg divided_clock;
    wire differential_high;
    wire configuration_used;

    assign differential_high = I && !IB;
    assign O = CEB ? 1'b0 : differential_high;
    assign ODIV2 = CEB ? 1'b0 : divided_clock;

    initial divided_clock = 1'b0;

    always @(posedge differential_high or posedge CEB) begin
        if (CEB) divided_clock <= 1'b0;
        else divided_clock <= !divided_clock;
    end

    assign configuration_used = (CLKCM_CFG == "TRUE") ||
                                (CLKRCV_TRST == "TRUE") ||
                                (CLKSWING_CFG == 2'b11);

endmodule

`default_nettype wire
`endif
