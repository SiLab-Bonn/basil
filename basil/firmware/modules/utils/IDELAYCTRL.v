// Xilinx UG953 (2026.1): https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/IDELAYCTRL
// Xilinx UG471: https://docs.amd.com/v/u/en-US/ug471_7Series_SelectIO
// Model the IDELAYCTRL primitive.
`ifndef IDELAYCTRL_SIM
`define IDELAYCTRL_SIM

`timescale 1ps / 1ps
`default_nettype none

module IDELAYCTRL #(
    parameter SIM_DEVICE = "7SERIES"
) (
    output reg  RDY,
    input  wire REFCLK,
    input  wire RST
);

    integer ready_count;

    initial begin
        RDY         = 1'b0;
        ready_count = 0;
    end

    // Model calibration with four clock edges; hardware timing differs.
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
