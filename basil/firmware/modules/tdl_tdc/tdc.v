module tdc #(
	parameter BASEADDR = 16'h0000,
	parameter HIGHADDR = 16'h0000,
	parameter ABUSWIDTH = 16,
	parameter DATA_IDENTIFIER = 4'b0100
) (
	input wire BUS_CLK,
	input wire [ABUSWIDTH-1:0] bus_add,
	inout wire [7:0] bus_data,
	input wire bus_rst,
	input wire bus_wr,
	input wire bus_rd,

	input wire CLK160,
	input wire tdc_in,
	input wire trig_in,

	input wire [15:0] timestamp,
	input wire arm_tdc,
	input wire ext_en,

	input wire fifo_read,
	output wire fifo_empty,
	output wire [31:0] fifo_data

);

localparam VERSION = 0;
wire PLL_FEEDBACK, LOCKED;
wire CLK160PLL, CLK480PLL;

PLLE2_BASE #(
	.BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
	.CLKFBOUT_MULT(6),       // Multiply value for all CLKOUT, (2-64)
	.CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
	.CLKIN1_PERIOD(6.250),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

	.CLKOUT0_DIVIDE(2),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT0_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT1_DIVIDE(6),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT1_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT2_DIVIDE(24),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT2_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT3_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT3_PHASE(90.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT4_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT4_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT4_PHASE(0),      // Phase offset for CLKOUT0 (-360.000-360.000).
	//-65 -> 0?; - 45 -> 39;  -25 -> 100; -5 -> 0;

	.DIVCLK_DIVIDE(1),        // Master division value, (1-56)
		.REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
		.STARTUP_WAIT("FALSE")     // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
	)
	PLLE2_BASE_inst (
		.CLKOUT0(CLK480PLL),
		.CLKOUT1(CLK160PLL),
		.CLKOUT2(),
		.CLKOUT3(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKFBOUT(PLL_FEEDBACK),
		.LOCKED(LOCKED),
		.CLKIN1(CLK160),
		.PWRDWN(0),
		.RST(!RESET_N),
		.CLKFBIN(PLL_FEEDBACK)
	);


	wire inv_trig_in;
	wire inv_sig_in;

	// CLK synchronous enable and arm
	wire en_tdc, arm_flag;
	// configuration register signals
	wire en_arm_mode, en_calib_mode, en_write_trigger_distance, en_write_timestamp, en_no_trig_err;


	wire [31:0] event_count;
	wire [7:0] tdc_miss_cnt, fifo_over_cnt;
	tdc_core i_tdc_core (
		.CLK_FAST(CLK480PLL),
		.CLK(CLK160PLL),
		.CALIB_CLK(BUS_CLK),
		.rst(rst),
		.sig_in(inv_sig_in ? ~tdc_in : tdc_in),
		.trig_in(inv_trig_in ? ~trig_in : trig_in),
		.en(en_tdc),
		.arm_flag(arm_flag),
		.reset(rst),
		.en_write_timestamp(en_write_timestamp),
		.en_arm_mode(en_arm_mode),
		.en_write_trigger_distance(en_write_trigger_distance),
		.en_calib_mode(en_calib_mode),
		.en_no_trig_err(en_no_trig_err),
		.FIFO_READ(fifo_read),


		.FIFO_DATA(fifo_data),
		.FIFO_EMPTY(fifo_empty),
		.tdc_miss_cnt(tdc_miss_cnt),
		.fifo_over_cnt(fifo_over_cnt),
		.event_cnt(event_count)
	);

	module #(.VERSION(VERSION),
	       	.BASEADDR(BASEADDR),
	       	.HIGHADDR(HIGHADDR),
	       	.ABUSWIDTH(ABUSWIDTH)
	) tdc_sw_interface (
		.BUS_CLK(BUS_CLK),
		.CLK_SLOW(CLK160PLL),
		.bus_wr(bus_wr),
		.bus_rd(bus_rd),
		.bus_rst(bus_rst),
		.ext_en(ext_en),
		.ext_arm(arm_tdc),
		.bus_data(bus_data),
		.bus_add(bus_add),
		.event_count(event_count),
		.fifo_lost_data_count(fifo_over_cnt),
		.tdc_miss_count(tdc_miss_cnt),

		.tdc_enabled(en_tdc),
		.tdc_rst(rst),
		.arm_flag(arm_flag),
		.en_write_timestamp(en_write_timestamp),
		.en_arm(en_arm_mode),
		.en_trig_distance_mode(en_write_trigger_distance),
		.en_calib_mode(en_calib_mode),
		.en_no_trig_err(en_no_trig_err),
		.en_inv_trig_in(inv_trig_in),
		.en_inv_sig_in(inv_sig_in),
	);

