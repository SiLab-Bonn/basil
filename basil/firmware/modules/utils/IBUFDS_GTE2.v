// Xilinx UG953: https://docs.amd.com/r/2025.2-English/ug953-vivado-7series-libraries/IBUFDS_GTE2
// Model the IBUFDS_GTE2 primitive.
`ifndef IBUFDS_GTE2_SIM
`define IBUFDS_GTE2_SIM

`timescale 1 ps / 1 ps

module IBUFDS_GTE2 #(
    parameter       CLKCM_CFG    = "TRUE",
    parameter       CLKRCV_TRST  = "TRUE",
    parameter [1:0] CLKSWING_CFG = 2'b11
) (
    output wire O,
    output wire ODIV2,
    input  wire CEB,
    input  wire I,
    input  wire IB
);

    reg clock_output = 1'b0;
    reg divided_clock = 1'b0;
    reg divide_phase = 1'b0;

    // The functional receiver follows I; IB and the electrical attributes
    // do not affect UNISIM's digital outputs. Enable is sampled on I events.
    assign O     = clock_output;
    assign ODIV2 = divided_clock;

    always @(I) clock_output <= I & ~CEB;

    always @(posedge I) begin
        divided_clock <= divide_phase;
        if (divide_phase) divide_phase <= 1'b0;
        else if (CEB == 1'b0) divide_phase <= 1'b1;
    end

endmodule

`endif
