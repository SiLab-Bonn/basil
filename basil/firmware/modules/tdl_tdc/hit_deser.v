// Latches the sample with the first transition and presents it on the next
// slow clock in the hit_sample register alongside a hit_flag.
module hit_deser(
	input wire CLK_FAST,
	input wire CLK_SLOW,
	input wire sample,

	output reg [encodebits-1:0] hit_sample,
	output reg [fine_time_bits-1:0] fine_time,
	output reg hit_flag
)

parameter encodebits = 7;
parameter fine_time_bits = 2;
parameter internally_rising = 1;
localparam dlyline_bits = 96;

reg [dlyline_bits-1:0] sample_latch;
reg sample_latched = 0;
reg [fine_time_bits-1:0] fine_time_count;
reg fine_time_count_reset;
wire a,b;
assign a = internally_rising;
assign b = ~internally_rising;
wire transition;
assign transition = (sample[0] == a) && (sample[dlyline_bits-1] == b)
always @(posedge CLK_FAST) begin
	if(fine_time_count == clk_ratio - 1) begin
		fine_time_count <= 0;
		if(transition) begin
			sample_latched <= 1;
			sample_latch <= sample;
			time_latch <= 0;
		end
		else begin
			sample_latched <= 0;
	end
	else begin
		fine_time_count <= fine_time_count +1;
		if(!sample_latched) begin
			if(transition) begin
				sample_latch <= sample;
				sample_latched <= 1;
				time_latch <= fine_time_count + 1;
			end
		end
	end
end

always @(posedge CLK_SLOW) begin
	if(sample_latched) begin
		hit_sample  <= sample_latch;
		fine_time <= time_latch
		hit_flag <= 1;
	end
	else begin
		hit_sample <= 0;
		fine_time <= 0;
		hit_flag <= 0;
	end
end
