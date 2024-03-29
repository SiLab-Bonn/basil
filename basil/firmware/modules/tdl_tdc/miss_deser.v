// Latches if a sampled with all low bits is followed by one with all high
// bits. This is then presented in the next slow clock cycle as a flag.
module miss_deser (
	input wire CLK_FAST,
	input wire CLK_SLOW,
	input wire [dlyline_bits-1:0] sample,

	output reg miss_flag
);
parameter internally_rising = 1;

reg miss_latch
reg [5:0] previous_sample = {6{~internally_rising}};
wire a,b;
assign a = internally_rising;
assign b = ~internally_rising;
always @(posedge CLK_FAST) begin
	if(sample[3:0] == {3{a}} &&
		sample[dlyline_bits-1: dlyline_bits-4] == {3{a}} &&
		previous_sample == {6{b}})
		miss_latch <=1;
	else 
		miss_latch <= miss_latch;

	previous_sample <= {sample[dlyline_bits-1: dlyline_bits-4], sample[3:0]};
end

always @(posedge CLK_SLOW) begin
	miss_flag <= miss_latch;
	miss_latch <= 0;
end
