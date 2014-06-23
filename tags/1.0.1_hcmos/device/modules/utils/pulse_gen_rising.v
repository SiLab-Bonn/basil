
module pulse_gen_rising (input clk_in, input in, output out);

reg ff;
always@(posedge clk_in)
    ff <= in;

assign out = !ff && in;

endmodule
