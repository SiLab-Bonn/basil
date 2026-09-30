`ifndef TDL_AND_DETECTOR
`define TDL_AND_DETECTOR

`include "tdl_tdc/delayline/carrysampler_spartan6_20ps.v"
`include "tdl_tdc/delayline/sample_deser.v"

module tdl_and_detector #(
    // Keep the existing public parameter names.
    // verilog_lint: waive parameter-name-style
    parameter clk_ratio = 3,  // This parameter doesn't yet fully work. See sample_deser.v
    // Keep the existing public parameter names.
    // verilog_lint: waive parameter-name-style
    parameter fine_time_bits = 2,  // Don't change
    localparam DLYLINE_BITS = 96,  // Don't change
    localparam RESOLUTION = 2,
    localparam INTERNALLY_RISING = 1'b1,
    localparam DETECT_RISING = 1'b1
) (
    input wire CLK_FAST,
    input wire CLK_SLOW,
    input wire sig_in,

    output wire [fine_time_bits-1:0] fine_time,
    output wire [  DLYLINE_BITS-1:0] sample,
    output wire [               1:0] hit_status
);


    wire [DLYLINE_BITS-1:0] tdl_sample;
    // Tapped delay line sampled using the fast clock
    carry_sampler_spartan6 #(
        .bits      (DLYLINE_BITS),
        .resolution(RESOLUTION)
    ) tdl_sampler (
        .d  (DETECT_RISING == INTERNALLY_RISING ? sig_in : ~sig_in),
        .q  (tdl_sample),
        .CLK(CLK_FAST)
    );

    wire [DLYLINE_BITS-1:0] hit_sample;
    sample_deser #(
        .clk_ratio        (clk_ratio),
        .fine_time_bits   (fine_time_bits),
        .dlyline_bits     (DLYLINE_BITS),
        .internally_rising(INTERNALLY_RISING)
    ) tdl_deser (
        .CLK_FAST (CLK_FAST),
        .CLK_SLOW (CLK_SLOW),
        .sample_in(tdl_sample),

        .hit_status     (hit_status),
        .fine_time      (fine_time),
        .selected_sample(hit_sample)
    );
    // The output sample must be presented as if it was a rising edge for the
    // encoder to make sense of it, irregardless of the DETECT_RISING bit.
    assign sample = INTERNALLY_RISING ? hit_sample : ~hit_sample;

endmodule

`endif
