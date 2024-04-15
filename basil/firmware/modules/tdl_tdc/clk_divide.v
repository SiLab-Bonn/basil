module clk_divide(
	input wire CLK_IN,
	output wire calib_sig
);
parameter CLK_DIVISOR = 3; // Actually the clock is divided by this factor, times two
localparam index_bits = $clog2(CLK_DIVISOR);

reg [index_bits:0] count_index;

reg pulse = 0;

always @(posedge CLK_IN) begin
	if (count_index == CLK_DIVISOR) begin
		count_index <= 0;
		pulse <= ~pulse;
	end else begin
		count_index <= count_index + 1;
	end
end

assign calib_sig = pulse;

endmodule
