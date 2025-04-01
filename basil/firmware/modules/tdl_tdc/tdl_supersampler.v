`include "tdl_tdc/delayline/carrysampler_spartan6_20ps.v"
`include "tdl_tdc/delayline/sample_deser.v"

module tdl_and_detector #(
	parameter clk_ratio = 3, // This parameter doesn't yet fully work. See sample_deser.v
	parameter fine_time_bits = 2, // Don't change
	localparam dlyline_bits = 96, // Don't change
	localparam resolution = 2,
	localparam internally_rising = 1'b1,
	localparam detect_rising = 1'b1
)(
	input wire CLK_FAST,
	input wire CLK_SLOW,
	input wire sig_in,

	output wire [fine_time_bits-1:0] fine_time,
	output wire [dlyline_bits-1:0] sample,
	output wire [1:0] hit_status
);


wire [dlyline_bits-1:0] tdl_sample;
// Tapped delay line sampled using the fast clock
carry_sampler_spartan6 #(.bits(dlyline_bits), .resolution(resolution)) tdl_sampler (
	.d(detect_rising == internally_rising ? sig_in : ~sig_in),
	.q(tdl_sample),
	.CLK(CLK_FAST));

wire [dlyline_bits-1:0] hit_sample;
sample_deser #(
	.clk_ratio(clk_ratio),
	.fine_time_bits(fine_time_bits),
	.dlyline_bits(dlyline_bits),
	.internally_rising(internally_rising)
) tdl_deser (
	.CLK_FAST(CLK_FAST),
	.CLK_SLOW(CLK_SLOW),
	.sample_in(tdl_sample),

	.hit_status(hit_status),
	.fine_time(fine_time),
	.selected_sample(hit_sample)
);
// The output sample must be presented as if it was a rising edge for the
// encoder to make sense of it, irregardless of the detect_rising bit. 
assign sample = internally_rising ? hit_sample : ~hit_sample;

endmodule
