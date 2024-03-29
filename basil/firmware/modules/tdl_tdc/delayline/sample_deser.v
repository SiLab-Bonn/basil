module sample_deser(
	input wire CLK_FAST,
	input wire CLK_SLOW,
	input wire [dlyline_bits-1:0] sample_in,

	output reg [1:0 ] hit_status,
	output reg [fine_time_bits-1:0] fine_time,
	output reg [dlyline_bits-1:0] selected_sample
);
// We will use a 2 bit flag to store hit and miss information of the group of
// samples. This needs to be in sync with the tdc controller.
localparam IDLE = 0;
localparam HIT = 1;
localparam MISSED = 2;


parameter dlyline_bits = 96;
parameter internally_rising = 1'b1;
parameter fine_time_bits = 2;
parameter clk_ratio = 3; // This parameter almost works, only the mux address generation below needs to be set manually

// shift register of delay line samples on the fast clock
integer i;
reg [dlyline_bits-1:0] samples [clk_ratio-1:0];
always @(posedge CLK_FAST) begin
	samples[0] <= sample_in;
	for(i=1; i <clk_ratio; i = i +1) begin
		samples[i] <= samples[i-1];
	end
end

// transferring shift register contents to slow clock
reg [dlyline_bits-1:0] samples_slow [clk_ratio-1:0];
always @(posedge CLK_SLOW) begin
	for(i=0; i<clk_ratio; i = i +1) begin
		samples_slow[i] <= samples[i];
	end
end


wire a,b;
assign a = internally_rising;
assign b = ~internally_rising;

// First check if an input signal transition was within any of the delay
// line samples by comparing their respective first and last bits.
wire [clk_ratio-1:0] hit_flags;
genvar k;
generate 
	for(k=0; k<clk_ratio; k = k+1) begin
			assign hit_flags[k] = ((samples_slow[k][0] ==a) || (samples_slow[k][1]  == a)) &&
			       	((samples_slow[k][dlyline_bits -2] == b ) || (samples_slow[k][dlyline_bits -1] == b) );
	end
endgenerate

// we also check if there were any transitions in-between samples, which would
// indicate that the tdl is too short for the sampling.
wire [2:0] miss_flags;
generate
	for(k=0; k<clk_ratio-1; k = k+1) begin
		if(internally_rising) begin
			assign miss_flags[k] = (&samples_slow[k] == 1 && |samples_slow[k+1] == 0);
		end else begin
			assign miss_flags[k] = (|samples_slow[k] == 0 && &samples_slow[k+1] == 1);
		end
	end
endgenerate

// Multiplexer to select the sample of the delay line with an input signal transition, ie. a hit. 
reg [1:0] mux_address;
always @(hit_flags) begin
	// This is the code that needs to be changed depending on clk_ratio
	//	 if(hit_flags[3]) begin
	//		mux_address <= 3;
	//	end
	if(hit_flags[2]) begin
		mux_address <= 2;
	end
	else if(hit_flags[1]) begin
		mux_address <= 1;
	end
	else if(hit_flags[0])  begin
		mux_address <= 0;
	end
	else begin
		// In this case we don't have a hit.
		mux_address <= 1;
	end
end

//always @ (mux_address) begin
//end

always @ (posedge CLK_SLOW) begin
	// Here we actually multiplex the delay line samples for further processing
	selected_sample <= samples_slow[mux_address];
	// The multiplexer address also carries the information about on which clock
	// cycle of the fast clock the signal transition occurred. 
	fine_time <= clk_ratio-1 - mux_address;
	if (|miss_flags)
		hit_status <= MISSED;
	else if (|hit_flags) begin
		if (clk_ratio - 1 - mux_address == 0 && fine_time == 2)
			hit_status <= IDLE;
		else
			hit_status <= HIT;
	end else 
		hit_status <= IDLE;
end

reg [1:0] fine_time_previous;
always @(posedge CLK_SLOW) begin
	fine_time_previous <= fine_time;
end

endmodule
