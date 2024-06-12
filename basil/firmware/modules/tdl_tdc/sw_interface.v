`include "tdl_tdc/utils/graycode_2stage_cdc.v"

module tdc_sw_interface #(
	parameter VERSION = 8'b00000000,
	parameter BASEADDR = 16'h0,
	parameter HIGHADDR = 16'h100,
	parameter ABUSWIDTH = 16
)(
	input wire BUS_CLK,
	input wire CLK,
	input wire bus_wr,
	input wire bus_rd,
	input wire bus_rst,
	input wire ext_en,
	input wire ext_arm,
	inout wire [7:0] bus_data,
	input wire [ABUSWIDTH-1:0] bus_add,
	input wire [31:0] event_count,
	input wire [7:0] fifo_lost_data_cnt,
	input wire [7:0] tdc_miss_cnt,

	output wire tdc_enabled,
	output wire tdc_rst,
	output wire bus_clk_rst,
	output wire arm_flag,
	output wire en_write_timestamp,
	output wire en_arm,
	output wire en_trig_distance_mode,
	output wire en_calib_mode,
	output wire en_inv_trig_in,
	output wire en_inv_sig_in,
	output wire en_no_trig_err
);


wire ip_rd, ip_wr;
wire [ABUSWIDTH-1:0] ip_add;
wire [7:0] ip_data_in;
reg [7:0] ip_data_out;

bus_to_ip #(
	.BASEADDR(BASEADDR),
	.HIGHADDR(HIGHADDR),
	.ABUSWIDTH(ABUSWIDTH)
) i_bus_to_ip (
	.BUS_RD(bus_rd),
	.BUS_WR(bus_wr),
	.BUS_ADD(bus_add),
	.BUS_DATA(bus_data),

	.IP_RD(ip_rd),
	.IP_WR(ip_wr),
	.IP_ADD(ip_add),
	.IP_DATA_IN(ip_data_in),
	.IP_DATA_OUT(ip_data_out)
);

// Reset logic
wire soft_rst;
assign soft_rst = (ip_add == 0 && ip_wr);

reg [1:0] soft_rst_ff, bus_rst_ff;
always @(posedge BUS_CLK) begin
	soft_rst_ff[0] <= soft_rst;
	soft_rst_ff[1] <= soft_rst_ff[0];
	bus_rst_ff[0] <= bus_rst;
	bus_rst_ff[1] <= bus_rst;
end

wire soft_rst_flag, bus_rst_flag;
assign soft_rst_flag = ~soft_rst_ff[1] & soft_rst_ff[0]; 
assign bus_rst_flag = bus_rst_ff[1] & ~bus_rst_ff[0]; // trailing edge

assign bus_clk_rst = bus_rst_flag | soft_rst_flag;
wire tdc_rst_short;

flag_domain_crossing rst_flag_domain_crossing (
	.CLK_A(BUS_CLK),
	.CLK_B(CLK),
	.FLAG_IN_CLK_A(bus_clk_rst),
	.FLAG_OUT_CLK_B(tdc_rst_short)
);

reg[2:0] tdc_rst_counter;
always @(posedge CLK) begin
	if (tdc_rst_short)
		tdc_rst_counter <= 3'b001;
	else if (tdc_rst_counter != 0)
		tdc_rst_counter <= tdc_rst_counter - 1;
end
assign tdc_rst = |tdc_rst_counter;


// Status registers
reg [7:0] status_regs[2:0];

wire CONF_EN; // ENABLE BUS_ADD==1 BIT==0
assign CONF_EN = status_regs[1][0];
wire CONF_EN_EXT; // ENABLE EXTERN BUS_ADD==1 BIT==1
assign CONF_EN_EXT = status_regs[1][1];
wire CONF_EN_ARM_TDC; // BUS_ADD==1 BIT==2
assign CONF_EN_ARM_TDC = status_regs[1][2];
wire CONF_EN_WRITE_TS; // BUS_ADD==1 BIT==3
assign CONF_EN_WRITE_TS = status_regs[1][3];
wire CONF_EN_TRIG_DIST; // BUS_ADD==1 BIT==4
assign CONF_EN_TRIG_DIST = status_regs[1][4];
wire CONF_EN_NO_WRITE_TRIG_ERR; // BUS_ADD==1 BIT==5
assign CONF_EN_NO_WRITE_TRIG_ERR = status_regs[1][5];
wire CONF_EN_INVERT_TDC; // BUS_ADD==1 BIT==6
assign CONF_EN_INVERT_TDC = status_regs[1][6];
wire CONF_EN_INVERT_TRIGGER; // BUS_ADD==1 BIT==7
assign CONF_EN_INVERT_TRIGGER = status_regs[1][7];
wire CONF_EN_CALIB_MODE; // BUS_ADD=8 BIT=0
assign CONF_EN_CALIB_MODE = status_regs[2][0];
reg [31:0] event_cnt_buf; // BUS_ADD==2
reg [23:0] event_cnt_buf_read; // BUS_ADD==3 - 5
reg [7:0] lost_data_cnt_bus_clk; // BUS_ADD==6
reg [7:0] tdl_miss_cnt_bus_clk; // BUS_ADD==7

// Writing to status registers
always @(posedge BUS_CLK) begin
	if (bus_rst) begin
		status_regs[1] <= 8'h08;
		status_regs[2] <= 8'b0;
	end
	else if (ip_wr && ip_add == 1)
		status_regs[1] <= ip_data_in;
	else if (ip_wr && ip_add == 8)
		status_regs[2] <= ip_data_in;
end

// Reading of status registers
wire [7:0] tdc_miss_cnt_bus_clk;
wire [7:0] fifo_lost_data_cnt_bus_clk;
always @(posedge BUS_CLK) begin
	if (ip_rd) begin
		if (ip_add == 0)
			ip_data_out <= VERSION;
		else if (ip_add == 1)
			ip_data_out <= status_regs[1];
		else if (ip_add == 2)
			ip_data_out <= event_cnt_buf[7:0];
		else if (ip_add == 3)
			ip_data_out <= event_cnt_buf_read[7:0];
		else if (ip_add == 4)
			ip_data_out <= event_cnt_buf_read[15:8];
		else if (ip_add == 5)
			ip_data_out <= event_cnt_buf_read[23:16];
		else if (ip_add == 6)
			ip_data_out <= fifo_lost_data_cnt_bus_clk;
		else if (ip_add == 7)
			ip_data_out <= tdc_miss_cnt_bus_clk;
		else
			ip_data_out <= 0;
	end
end

// Clock domain crossing from the bus clock to the main tdc clock
three_stage_synchronizer conf_en_three_stage_synchronizer_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN | (CONF_EN_EXT & ext_en)),
	.OUT(tdc_enabled)
);

three_stage_synchronizer conf_en_arm_conf_en_synchronizer_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN_ARM_TDC),
	.OUT(en_arm)
);

three_stage_synchronizer conf_en_write_ts_synchronizer_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN_WRITE_TS),
	.OUT(en_write_timestamp)
);

three_stage_synchronizer conf_en_trig_dist_synchronizer_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN_TRIG_DIST),
	.OUT(en_trig_distance_mode)
);

three_stage_synchronizer conf_en_no_write_trig_err_synchronizer_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN_NO_WRITE_TRIG_ERR),
	.OUT(en_no_trig_err)
);

three_stage_synchronizer conf_en_invert_tdc_synchronizer_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN_INVERT_TDC),
	.OUT(en_inv_sig_in)
);

three_stage_synchronizer conf_en_invert_trigger_synchronizer_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN_INVERT_TRIGGER),
	.OUT(en_inv_trig_in)
);

three_stage_synchronizer conf_en_clib_mode_dv_clk (
	.CLK(CLK),
	.IN(CONF_EN_CALIB_MODE),
	.OUT(en_calib_mode)
);

// Gray code cdc from the main tdc clock to the bus clock
wire [31:0] event_cnt;
graycode_2stage_cdc #(.DATA_WIDTH(32)) event_count_cdc (
	.IN_CLK(CLK),
	.OUT_CLK(BUS_CLK),
	.data(event_count),
	.data_out_clk(event_cnt)
);

// This is a strange additional buffer from the original tdc_s3 (L:420). 
always @(posedge BUS_CLK) begin
	event_cnt_buf <= event_cnt;
	if (ip_add == 2 && ip_rd)
		event_cnt_buf_read[23:0] <= event_cnt_buf[31:8];
end

graycode_2stage_cdc #(.DATA_WIDTH(8)) data_lost_cdc (
	.IN_CLK(CLK),
	.OUT_CLK(BUS_CLK),
	.data(fifo_lost_data_cnt),
	.data_out_clk(fifo_lost_data_cnt_bus_clk)
);

graycode_2stage_cdc #(.DATA_WIDTH(8)) tdc_misses_cdc (
	.IN_CLK(CLK),
	.OUT_CLK(BUS_CLK),
	.data(tdc_miss_cnt),
	.data_out_clk(tdc_miss_cnt_bus_clk)
);

wire ext_arm_clk;
three_stage_synchronizer three_stage_arm_tdc_synchronizer_clk (
	.CLK(CLK),
	.IN(ext_arm),
	.OUT(ext_arm_clk)
);

reg ext_arm_clk_ff;
always @(posedge CLK) begin
	ext_arm_clk_ff <= ext_arm_clk;
end

assign arm_flag = ~ext_arm_clk_ff & ext_arm_clk;


endmodule
