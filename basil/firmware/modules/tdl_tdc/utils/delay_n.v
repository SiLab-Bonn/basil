module delay_n (
	input wire CLK,
	input wire [width-1:0] signal,

	output wire [width-1:0] delayed_signal
);

parameter n = 3;
parameter width = 8;

integer i;
reg [width-1:0] delay_taps [n-1:0];
always @(posedge CLK) begin
	delay_taps[0] <= signal;
	for(i=1; i<n; i = i+1) begin
		delay_taps[i] <= delay_taps[i-1];
	end
end

assign delayed_signal = delay_taps[n-1];

endmodule
