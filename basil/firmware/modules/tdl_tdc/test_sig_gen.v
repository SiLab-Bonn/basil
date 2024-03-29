module clk_divide(
	input wire CLK_IN,
	output reg calib_sig
);
parameter CLK_DIVISOR = 3; // Actually the clock is divided by this factor times two
localparam index_bits = $clog2(CLK_DIVISOR);

reg count_index;

always @(posedge CLK_IN) begin
	if (count_index == CLK_DIVISOR)
		count_index <= 0;
		calib_sig = ~calib_sig;
	else
		count_index <= count_index + 1;
end

