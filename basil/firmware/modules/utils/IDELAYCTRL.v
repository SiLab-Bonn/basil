/**
 * Behavioral simulation model for the Xilinx 7-series IDELAYCTRL primitive.
 */
`ifndef IDELAYCTRL_SIM
`define IDELAYCTRL_SIM

`timescale 1ps / 1ps
`default_nettype none

module IDELAYCTRL (
    output reg  RDY,
    input  wire REFCLK,
    input  wire RST
);

    integer ready_count;

    initial begin
        RDY         = 1'b0;
        ready_count = 0;
    end

    // The hardware calibrates its delay taps after reset.  Four reference-clock
    // edges provide a small, deterministic calibration interval for simulation.
    always @(posedge REFCLK or posedge RST) begin
        if (RST) begin
            RDY         <= 1'b0;
            ready_count <= 0;
        end else if (ready_count == 3) begin
            RDY <= 1'b1;
        end else begin
            ready_count <= ready_count + 1;
        end
    end

endmodule

`endif
