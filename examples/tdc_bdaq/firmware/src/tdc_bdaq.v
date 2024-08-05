// /**
// * ------------------------------------------------------------
// * Copyright (c) All rights reserved
// * SiLab, Physics Institute, University of Bonn
// * ------------------------------------------------------------

`include "utils/fifo_32_to_8.v"
`include "utils/rgmii_io.v"
`include "utils/rbcp_to_bus.v"
`include "utils/bus_to_ip.v"
`include "rrp_arbiter/rrp_arbiter.v"
`include "gpio/gpio_core.v"
`include "gpio/gpio.v"
`include "tdl_tdc/tdl_tdc.v"

// tdl_tdc dependencies
`include "utils/3_stage_synchronizer.v"
`include "utils/flag_domain_crossing.v"
`include "utils/generic_fifo.v"
`include "utils/cdc_syncfifo.v"
`include "utils/clock_divider.v"


// Seq_gen
`include "seq_gen/seq_gen.v"
`include "seq_gen/seq_gen_core.v"

// Seq_gen dependencies

`include "utils/cdc_pulse_sync.v"
`include "utils/ramb_8_to_n.v"

// For Si570
`include "i2c/i2c.v"
`include "i2c/i2c_core.v"

module tdc_bdaq(
	input wire sig_in,
	input wire trig_in,
	input wire RESET_N,
	input wire clkin,
	input wire Si511_P,
	input wire Si511_N,
	input wire Si570_P,
	input wire Si570_N,

	output wire [3:0] rgmii_txd,
	output wire rgmii_tx_ctl,
	output wire rgmii_txc,
	input wire [3:0] rgmii_rxd,
	input wire rgmii_rx_ctl,
	input wire rgmii_rxc,
	output wire mdio_phy_mdc,
	inout wire mdio_phy_mdio,
	output wire phy_rst_n,

	inout wire I2C_SDA,
	output wire I2C_SCL,

	output wire [7:0] LED,
	output wire trig_out,
	output wire sig_out,
	output wire MGT_REF_SEL
);
assign MGT_REF_SEL = 1;

wire CLK_156M250_in;
wire CLK_156M250;
IBUFDS_GTE2 IBUFDS_GTE2_inst_156 (
   .O(CLK_156M250_in),  // Buffer output
   .ODIV2(),
   .CEB(1'b0), 
   .I(Si511_P),  // Diff_p buffer input (connect directly to top-level port)
   .IB(Si511_N) // Diff_n buffer input (connect directly to top-level port)
);

BUFG BUFG_inst (
	.O(CLK_156M250),
	.I(CLK_156M250_in)
);

wire CLK_160_in;
wire CLK_160;
IBUFDS_GTE2 IBUFDS_GTE2_inst_160 (
   .O(CLK_160_in),  // Buffer output
   .ODIV2(),
   .CEB(1'b0), 
   .I(Si570_P),  // Diff_p buffer input (connect directly to top-level port)
   .IB(Si570_N) // Diff_n buffer input (connect directly to top-level port)
);

 BUFG BUFG_inst_2 (
 	.O(CLK_160),
 	.I(CLK_160_in)
 );

wire RST;
wire BUS_CLK_PLL, CLK125PLLTX, CLK125PLLTX90;
wire PLL_FEEDBACK, LOCKED;

PLLE2_BASE #(
	.BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
	.CLKFBOUT_MULT(10),       // Multiply value for all CLKOUT, (2-64)
	.CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
	.CLKIN1_PERIOD(10.000),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

	.CLKOUT0_DIVIDE(7),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT0_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT1_DIVIDE(4),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT1_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT2_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT2_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT3_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT3_PHASE(90.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT4_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT4_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT4_PHASE(-5.625),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.DIVCLK_DIVIDE(1),        // Master division value, (1-56)
	.REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
	.STARTUP_WAIT("FALSE")     // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
)
PLLE2_BASE_BUS (
	.CLKOUT0(BUS_CLK_PLL),
	.CLKOUT1(),
	.CLKOUT2(CLK125PLLTX),
	.CLKOUT3(CLK125PLLTX90),
	.CLKOUT4(),
	.CLKOUT5(),
	.CLKFBOUT(PLL_FEEDBACK),
	.LOCKED(LOCKED),
	.CLKIN1(clkin),
	.PWRDWN(0),
	.RST(!RESET_N),
	.CLKFBIN(PLL_FEEDBACK)
);

// wire CLK160, CLK40;
// wire PLL2_FEEDBACK, LOCKED160;
// PLLE2_BASE #(
// 	.BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
// 	.CLKFBOUT_MULT(16),       // Multiply value for all CLKOUT, (2-64)
// 	.CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
// 	.CLKIN1_PERIOD(10.000),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
// 
// 	.CLKOUT0_DIVIDE(10),     // Divide amount for CLKOUT0 (1-128)
// 	.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
// 	.CLKOUT0_PHASE(90.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
// 
// 	.CLKOUT1_DIVIDE(10),     // Divide amount for CLKOUT0 (1-128)
// 	.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
// 	.CLKOUT1_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
// 
// 	.CLKOUT2_DIVIDE(40),     // Divide amount for CLKOUT0 (1-128)
// 	.CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
// 	.CLKOUT2_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
// 
// 	.CLKOUT3_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
// 	.CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
// 	.CLKOUT3_PHASE(90.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
// 
// 	.CLKOUT4_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
// 	.CLKOUT4_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
// 	.CLKOUT4_PHASE(-5.625),      // Phase offset for CLKOUT0 (-360.000-360.000).
// 
// 	.DIVCLK_DIVIDE(1),        // Master division value, (1-56)
// 	.REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
// 	.STARTUP_WAIT("FALSE")     // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
// )
// PLLE2_BASE_160 (
// 	.CLKOUT0(CLK160),
// 	.CLKOUT1(),
// 	.CLKOUT2(CLK40),
// 	.CLKOUT3(),
// 	.CLKOUT4(),
// 	.CLKOUT5(),
// 	.CLKFBOUT(PLL2_FEEDBACK),
// 	.LOCKED(LOCKED160),
// 	.CLKIN1(clkin),
// 	.PWRDWN(0),
// 	.RST(!RESET_N),
// 	.CLKFBIN(PLL2_FEEDBACK)
// );

wire PLL3_FEEDBACK, LOCKED480;
wire CLK160PLL, CLK480PLL;

PLLE2_BASE #(
	.BANDWIDTH("HIGH"),  // OPTIMIZED, HIGH, LOW
	.CLKFBOUT_MULT(6),       // Multiply value for all CLKOUT, (2-64)
	.CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
	.CLKIN1_PERIOD(6.250),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

	.CLKOUT0_DIVIDE(6),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT0_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT1_DIVIDE(2),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT1_PHASE(0.000),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT2_DIVIDE(24),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT2_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT3_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT3_PHASE(90.0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.CLKOUT4_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
	.CLKOUT4_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
	.CLKOUT4_PHASE(0),      // Phase offset for CLKOUT0 (-360.000-360.000).

	.DIVCLK_DIVIDE(1),        // Master division value, (1-56)
	.REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
	.STARTUP_WAIT("FALSE")     // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
)
PLLE2_BASE_480 (
	.CLKOUT0(CLK160PLL),
	.CLKOUT1(CLK480PLL),
	.CLKOUT2(),
	.CLKOUT3(),
	.CLKOUT4(),
	.CLKOUT5(),
	.CLKFBOUT(PLL3_FEEDBACK),
	.LOCKED(LOCKED480),
	.CLKIN1(CLK_160),
	.PWRDWN(0),
	.RST(!RESET_N),
	.CLKFBIN(PLL3_FEEDBACK)
);



wire BUS_CLK;
BUFG BUFG_inst_BUS_CKL    (.O(BUS_CLK),     .I(BUS_CLK_PLL)   );

wire CLK125TX, CLK125TX90, CLK125RX;
BUFG BUFG_inst_CLK125TX   ( .O(CLK125TX),   .I(CLK125PLLTX)   );
BUFG BUFG_inst_CLK125TX90 ( .O(CLK125TX90), .I(CLK125PLLTX90) );
BUFG BUFG_inst_CLK125RX   ( .O(CLK125RX),   .I(rgmii_rxc)     );

assign RST = !RESET_N | !LOCKED;
wire I2C_CLK;

clock_divider #(
    .DIVISOR(1600)
) i_clock_divisor_i2c (
    .CLK(BUS_CLK),
    .RESET(1'b0),
    .CE(),
    .CLOCK(I2C_CLK)
);


localparam I2C_MEM_BYTES = 32;

localparam I2C_BASEADDR = 32'h6000;
localparam I2C_HIGHADDR = 32'h6100-1;

i2c #(
    .BASEADDR(I2C_BASEADDR),
    .HIGHADDR(I2C_HIGHADDR),
    .ABUSWIDTH(32),
    .MEM_BYTES(I2C_MEM_BYTES)
)  i_i2c (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .I2C_CLK(I2C_CLK),
    .I2C_SDA(I2C_SDA),
    .I2C_SCL(I2C_SCL)
);



wire   gmii_tx_en;
wire  [7:0] gmii_txd;
wire   gmii_tx_er;
wire   gmii_crs;
wire   gmii_col;
wire   gmii_rx_dv;
wire  [7:0] gmii_rxd;
wire   gmii_rx_er;
wire   mdio_gem_i;
wire   mdio_gem_o;
wire   mdio_gem_t;
wire   link_status;
wire  [1:0] clock_speed;
wire   duplex_status;

rgmii_io rgmii
(
	.rgmii_txd(rgmii_txd),
	.rgmii_tx_ctl(rgmii_tx_ctl),
	.rgmii_txc(rgmii_txc),

	.rgmii_rxd(rgmii_rxd),
	.rgmii_rx_ctl(rgmii_rx_ctl),

	.gmii_txd_int(gmii_txd),      // Internal gmii_txd signal.
	.gmii_tx_en_int(gmii_tx_en),
	.gmii_tx_er_int(gmii_tx_er),
	.gmii_col_int(gmii_col),
	.gmii_crs_int(gmii_crs),
	.gmii_rxd_reg(gmii_rxd),   // RGMII double data rate data valid.
	.gmii_rx_dv_reg(gmii_rx_dv), // gmii_rx_dv_ibuf registered in IOBs.
	.gmii_rx_er_reg(gmii_rx_er), // gmii_rx_er_ibuf registered in IOBs.

	.eth_link_status(link_status),
	.eth_clock_speed(clock_speed),
	.eth_duplex_status(duplex_status),

	// Following are generated by DCMs
	.tx_rgmii_clk_int(CLK125TX),     // Internal RGMII transmitter clock.
	.tx_rgmii_clk90_int(CLK125TX90),   // Internal RGMII transmitter clock w/ 90 deg phase
	.rx_rgmii_clk_int(CLK125RX),     // Internal RGMII receiver clock

	.reset(!phy_rst_n)
);


// Instantiate tri-state buffer for MDIO
IOBUF i_iobuf_mdio(
	.O(mdio_gem_i),
	.IO(mdio_phy_mdio),
	.I(mdio_gem_o),
	.T(mdio_gem_t)
);

wire TCP_CLOSE_REQ;
wire TCP_OPEN_ACK;
wire RBCP_ACT, RBCP_WE, RBCP_RE;
wire [7:0] RBCP_WD, RBCP_RD;
wire [31:0] RBCP_ADDR;
wire TCP_RX_WR;
wire TCP_TX_WR;
wire [7:0] TCP_RX_DATA;
wire [7:0] TCP_TX_DATA;
wire TCP_TX_FULL;
wire RBCP_ACK;
wire SiTCP_RST;
reg [10:0] TCP_RX_WC_11B;


WRAP_SiTCP_GMII_XC7K_32K sitcp(
	.CLK(BUS_CLK)               ,    // in    : System Clock >129MHz
	.RST(RST)                   ,    // in    : System reset

	.FORCE_DEFAULTn(1'b0)       ,    // in    : Load default parameters
	.EXT_IP_ADDR(32'hc0a80a10)  ,    // in    : IP address[31:0] //192.168.10.16
	.EXT_TCP_PORT(16'd24)       ,    // in    : TCP port #[15:0]
	.EXT_RBCP_PORT(16'd4660)    ,    // in    : RBCP port #[15:0]
	.PHY_ADDR(5'd3)             ,    // in    : PHY-device MIF address[4:0]

	.EEPROM_CS()                ,    // out    : Chip select
	.EEPROM_SK()                ,    // out    : Serial data clock
	.EEPROM_DI()                ,    // out    : Serial write data
	.EEPROM_DO(1'b0)            ,    // in    : Serial read data

	.USR_REG_X3C()              ,    // out    : Stored at 0xFFFF_FF3C
	.USR_REG_X3D()              ,    // out    : Stored at 0xFFFF_FF3D
	.USR_REG_X3E()              ,    // out    : Stored at 0xFFFF_FF3E
	.USR_REG_X3F()              ,    // out    : Stored at 0xFFFF_FF3F

	.GMII_RSTn(phy_rst_n)       ,    // out    : PHY reset
	.GMII_1000M(1'b1)           ,    // in    : GMII mode (0:MII, 1:GMII)

	.GMII_TX_CLK(CLK125TX)      ,    // in    : Tx clock
	.GMII_TX_EN(gmii_tx_en)     ,    // out    : Tx enable
	.GMII_TXD(gmii_txd)         ,    // out    : Tx data[7:0]
	.GMII_TX_ER(gmii_tx_er)     ,    // out    : TX error
	.GMII_RX_CLK(CLK125RX)      ,    // in    : Rx clock
	.GMII_RX_DV(gmii_rx_dv)     ,    // in    : Rx data valid
	.GMII_RXD(gmii_rxd)         ,    // in    : Rx data[7:0]
	.GMII_RX_ER(gmii_rx_er)     ,    // in    : Rx error
	.GMII_CRS(gmii_crs)         ,    // in    : Carrier sense
	.GMII_COL(gmii_col)         ,    // in    : Collision detected
	.GMII_MDC(mdio_phy_mdc)     ,    // out    : Clock for MDIO
	.GMII_MDIO_IN(mdio_gem_i)   ,    // in    : Data
	.GMII_MDIO_OUT(mdio_gem_o)  ,    // out    : Data
	.GMII_MDIO_OE(mdio_gem_t)   ,    // out    : MDIO output enable
	.SiTCP_RST(SiTCP_RST)       ,    // out    : Reset for SiTCP and related circuits
	.TCP_OPEN_REQ(1'b0)         ,    // in    : Reserved input, shoud be 0
	.TCP_OPEN_ACK(TCP_OPEN_ACK) ,    // out    : Acknowledge for open (=Socket busy)
	.TCP_ERROR()                ,    // out    : TCP error, its active period is equal to MSL
	.TCP_CLOSE_REQ(TCP_CLOSE_REQ)    ,    // out    : Connection close request
	.TCP_CLOSE_ACK(TCP_CLOSE_REQ)    ,    // in    : Acknowledge for closing
	.TCP_RX_WC({5'b1,TCP_RX_WC_11B}) ,    // in    : Rx FIFO write count[15:0] (Unused bits should be set 1)
	.TCP_RX_WR(TCP_RX_WR)            ,    // out    : Write enable
	.TCP_RX_DATA(TCP_RX_DATA)   ,    // out    : Write data[7:0]
	.TCP_TX_FULL(TCP_TX_FULL)   ,    // out    : Almost full flag
	.TCP_TX_WR(TCP_TX_WR)       ,    // in    : Write enable
	.TCP_TX_DATA(TCP_TX_DATA)   ,    // in    : Write data[7:0]
	.RBCP_ACT(RBCP_ACT)         ,    // out    : RBCP active
	.RBCP_ADDR(RBCP_ADDR)       ,    // out    : Address[31:0]
	.RBCP_WD(RBCP_WD)           ,    // out    : Data[7:0]
	.RBCP_WE(RBCP_WE)           ,    // out    : Write enable
	.RBCP_RE(RBCP_RE)           ,    // out    : Read enable
	.RBCP_ACK(RBCP_ACK)         ,    // in    : Access acknowledge
	.RBCP_RD(RBCP_RD)                // in    : Read data[7:0]
);


wire [31:0] BUS_ADD;
wire [7:0] BUS_DATA;
wire BUS_WR, BUS_RD, BUS_RST;
assign BUS_RST = SiTCP_RST;

rbcp_to_bus irbcp_to_bus(
	.BUS_RST(BUS_RST),
	.BUS_CLK(BUS_CLK),

        .RBCP_ACT(RBCP_ACT),
        .RBCP_ADDR(RBCP_ADDR),
        .RBCP_WD(RBCP_WD),
        .RBCP_WE(RBCP_WE),
        .RBCP_RE(RBCP_RE),
        .RBCP_ACK(RBCP_ACK),
        .RBCP_RD(RBCP_RD),

        .BUS_WR(BUS_WR),
        .BUS_RD(BUS_RD),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA)
    );

localparam GPIO_BASEADDR = 32'h1000;
localparam GPIO_HIGHADDR = 32'h101f;
wire [7:0] GPIO;
gpio #(
	.BASEADDR(GPIO_BASEADDR),
	.HIGHADDR(GPIO_HIGHADDR),
	.ABUSWIDTH(32),
	.IO_WIDTH(8),
	.IO_DIRECTION(8'hff)
) i_gpio_rx (
	.BUS_CLK(BUS_CLK),
	.BUS_RST(BUS_RST),
	.BUS_ADD(BUS_ADD),
	.BUS_DATA(BUS_DATA[7:0]),
	.BUS_RD(BUS_RD),
	.BUS_WR(BUS_WR),
	.IO(GPIO)
);


localparam SEQ_BASEADDR = 32'h1120;
localparam SEQ_HIGHADDR = 32'h5160 - 1;

wire [7:0] SEQ_OUT;
seq_gen #(
    .BASEADDR(SEQ_BASEADDR),
    .HIGHADDR(SEQ_HIGHADDR),
    .ABUSWIDTH(32),
    .MEM_BYTES(16384),
    .OUT_BITS(8)
) i_seq_gen (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .SEQ_EXT_START(1'b0),
    .SEQ_CLK(CLK_156M250),
    .SEQ_OUT(SEQ_OUT)
);

reg trig_out_buf, sig_out_buf;
assign trig_out = trig_out_buf;
assign sig_out = sig_out_buf;

always @(posedge CLK_156M250) begin
	trig_out_buf <= SEQ_OUT[0];
	sig_out_buf <= SEQ_OUT[1];
end


wire EN, ARM;
assign EN = GPIO[0];
assign ARM = GPIO[1];

localparam TDC_BASEADDR = 32'h1020;
localparam TDC_HIGHADDR = 32'h111f;
wire [31:0] tdc_fifo_data;
tdl_tdc #(
	.BASEADDR(TDC_BASEADDR),
	.HIGHADDR(TDC_HIGHADDR),
	.ABUSWIDTH(32),
	.DATA_IDENTIFIER(4'b0100)
) i_tdc (
	.BUS_CLK(BUS_CLK),
	.bus_add(BUS_ADD),
	.bus_data(BUS_DATA),
	.bus_rst(BUS_RST),
	.bus_wr(BUS_WR),
	.bus_rd(BUS_RD),

	.CLK480(CLK480PLL),
	.CLK160(CLK160PLL),
	.CALIB_CLK(CLK125RX),
	.tdc_in(sig_in),//(sig_out_buf),//(sig_in),
	.trig_in(trig_in),//(trig_out_buf),//(trig_in),

	.timestamp(42),
	.ext_en(EN),
	.arm_tdc(ARM),
	.fifo_read(tdc_fifo_read),

	.fifo_empty(tdc_fifo_empty),
	.fifo_data(tdc_fifo_data)
);

wire tdc_fifo_read, tdc_fifo_empty;
wire ARB_WRITE_OUT;
wire [31:0] ARB_DATA_OUT;
wire TCP_FIFO_FULL, TCP_FIFO_EMPTY;
reg FIFO_NEXT;

rrp_arbiter #(
	.WIDTH(1)
) i_rrp_arbiter (
	.RST(BUS_RST),
	.CLK(BUS_CLK),
	.WRITE_REQ(!tdc_fifo_empty),
	.HOLD_REQ(1'b0),  // wait for writing for given stream (priority)
	.DATA_IN(tdc_fifo_data),  // incoming data for arbitration
	.READ_GRANT(tdc_fifo_read),  // indicate to stream that data has been accepted
	.READY_OUT(~TCP_FIFO_FULL && FIFO_NEXT),  // indicates ready for outgoing stream (input)
	.WRITE_OUT(ARB_WRITE_OUT),  // indicates will of write to outgoing stream
	.DATA_OUT(ARB_DATA_OUT)  // outgoing data stream
);

assign TCP_TX_WR = !TCP_TX_FULL & !TCP_FIFO_EMPTY;

fifo_32_to_8 #(
	.DEPTH(128*1024)
) i_data_fifo (
	.RST(BUS_RST),
	.CLK(BUS_CLK),

	.WRITE(ARB_WRITE_OUT && FIFO_NEXT),
	.READ(TCP_TX_WR),
	.DATA_IN(ARB_DATA_OUT),
	.FULL(TCP_FIFO_FULL),
	.EMPTY(TCP_FIFO_EMPTY),
	.DATA_OUT(TCP_TX_DATA)
);

reg ETH_START_SENDING, ETH_START_SENDING_temp, ETH_START_SENDING_LOCK;


/* -------  Main FSM  ------- */
always @(posedge BUS_CLK) begin
	// wait for start condition
	ETH_START_SENDING <= EN;    //TCP_OPEN_ACK;

	if (ETH_START_SENDING && !ETH_START_SENDING_temp)
		ETH_START_SENDING_LOCK <= 1;
	ETH_START_SENDING_temp <= ETH_START_SENDING;

	// RX FIFO word counter
	if (TCP_RX_WR) 
		TCP_RX_WC_11B <= TCP_RX_WC_11B + 1;
	else 
		TCP_RX_WC_11B <= 11'd0;


	// FIFO handshake
	if (ETH_START_SENDING_LOCK)
		FIFO_NEXT <= 1'b1;
	else
		FIFO_NEXT <= 1'b0;

	// stop, if connection is closed by host
	if (TCP_CLOSE_REQ || !EN) 
		ETH_START_SENDING_LOCK <= 0;
end

assign LED = ~{ TCP_OPEN_ACK, TCP_CLOSE_REQ, TCP_RX_WR, TCP_TX_WR,
	TCP_FIFO_FULL, TCP_FIFO_EMPTY, sig_out, trig_out};


endmodule
