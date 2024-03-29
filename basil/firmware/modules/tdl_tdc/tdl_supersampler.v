module tdl_and_detector (
	input wire CLK_FAST,
	input wire CLK_SLOW,
	input wire sig_in,

	output wire [fine_time_bits-1:0] fine_time,
	output wire [dlyline_bits-1:0] sample,
	output wire [1:0] hit_status,
);

parameter clk_ratio = 3; // This parameter doesn't yet fully work. See sample_deser.v
parameter fine_time_bits = 2; // Don't change
localparam dlyline_bits = 96; // Don't change


localparam internally_rising = 1'b1;
localparam detect_rising = 1'b1;

wire [dlyline_bits-1:0] tdl_sample;
// Tapped delay line sampled using the fast clock
carry_sampler_spartan6 #(.bits(dlyline_bits), .resolution(resolution)) tdl_sampler (
	.d(detect_rising == internally_rising ? tdl_input : ~tdl_input),
	.q(tdl_sample),
	.CLK(CLK_FAST));

wire [dlyline_bits-1:0] hit_sample;
sample_deser tdl_deser #(.clk_ratio(clk_ratio), .fine_time_bits(fine_time_bits)) (
	.CLK_FAST(CLK_FAST),
	.CLK_SLOW(CLK_SLOW),
	.sample_in(tdl_sample),

	.hit_status(hit_status),
	.medium_fine_time(fine_time),
	.selected_sample(hit_sample)
);
// The output sample must be presented as if it was a rising edge for the
// encoder to make sense of it, irregardless of the detect_rising bit. 
assign sample = internally_rising ? hit_sample : ~hit_sample;

