module graycode_2stage_cdc #(DATA_WIDTH = 8) (
	input wire IN_CLK,
	input wire OUT_CLK,
	input wire [DATA_WIDTH-1:0] data,
	output wire [DATA_WIDTH-1:0] data_out_clk
);

reg [DATA_WIDTH-1:0] gray;
always @(posedge IN_CLK)
    gray <=  (data>>1) ^ data;

reg [DATA_WIDTH-1:0] gray_cdc0, gray_cdc1, data_bus_clk;
always @(posedge OUT_CLK) begin
    gray_cdc0 <= gray;
    gray_cdc1 <= gray_cdc0;
end

integer i;
always @(*) begin
    data_bus_clk[DATA_WIDTH-1] = gray_cdc1[DATA_WIDTH-1];
    for(i = DATA_WIDTH-2; i >= 0; i = i - 1) begin
        data_bus_clk[i] = gray_cdc1[i] ^ data_bus_clk[i + 1];
    end
end

assign data_out_clk = data_bus_clk;

endmodule
