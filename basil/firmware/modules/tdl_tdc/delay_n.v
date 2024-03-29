module delay_n (
	input wire CLK,
	input wire [width-1:0] signal,

	output reg [width-1:0] delayed_signal
);

parameter n;
parameter width;

integer i;
reg [width-1:0] delay_taps [n-1:0]
always @(posedge CLK) begin
	delay_taps[0] <= signal;
	for(i=1; i<n; i = i+1) begin
		delay_taps[i] <= delay_taps[i-1];
	end
end

assign delayed_signal = delay_taps[n-1]

