`default_nettype wire
/*******************************************************************************
*                                                                              *
*       Wrapper of the OPEN-SiTCP library for BBT                              *
*                                                                              *
*       FPGA family : Xilinx Kintex7                                           *
*                                                                              *
*       Version     : v 2.0   2010/03/31                                       *
*                     v 3.0  2010/04/21 Change polarity of system reset        *
*                     v 3.1  2010/05/10 Add GMII_1000M                         *
*                     v 5.0  2012/02/15 modify for SiTCP_XC6S_32K_BBT_V50      *
*                     v 6.0  2012/11/21 Activate TCP client mode               *
*                     v 7.0  2012/11/26 By ver up of SiTCP core to V2.4        *
*                     v 7.1  2013/10/01 New function: variable RX-IFG in GMII  *
*                     v 8.0  2013/10/10 Release V7.1                           *
*                     v 9.0  2016/02/08 Add MAC address port                   *
*                     v 10.0 2016/08/26 RX bug fixed                           *
*                                                                              *
*                Copyright (c) 2010 Bee Beans Technologies Co.,Ltd.            *
*                All rights reserved                                           *
*                                                                              *
*******************************************************************************/

module WRAP_SiTCP_GMII_XC7K_32K(
	CLK					,	// in	: System Clock >129MHz
	RST					,	// in	: System reset
// Configuration parameters
	FORCE_DEFAULTn		,	// in	: Load default parameters
	EXT_IP_ADDR			,	// in	: IP address[31:0]
	EXT_TCP_PORT		,	// in	: TCP port #[15:0]
	EXT_RBCP_PORT		,	// in	: RBCP port #[15:0]
	PHY_ADDR			,	// in	: PHY-device MIF address[4:0]
	MY_MAC_ADDR			,
// EEPROM
	EEPROM_CS			,	// out	: Chip select
	EEPROM_SK			,	// out	: Serial data clock
	EEPROM_DI			,	// out	: Serial write data
	EEPROM_DO			,	// in	: Serial read data
	// user data, intialial values are stored in the EEPROM, 0xFFFF_FC3C-3F
	USR_REG_X3C			,	// out	: Stored at 0xFFFF_FF3C
	USR_REG_X3D			,	// out	: Stored at 0xFFFF_FF3D
	USR_REG_X3E			,	// out	: Stored at 0xFFFF_FF3E
	USR_REG_X3F			,	// out	: Stored at 0xFFFF_FF3F
// MII interface
	GMII_RSTn			,	// out	: PHY reset
	GMII_1000M			,	// in	: GMII mode (0:MII, 1:GMII)
	// TX
	GMII_TX_CLK			,	// in	: Tx clock
	GMII_TX_EN			,	// out	: Tx enable
	GMII_TXD			,	// out	: Tx data[7:0]
	GMII_TX_ER			,	// out	: TX error
	// RX
	GMII_RX_CLK			,	// in	: Rx clock
	GMII_RX_DV			,	// in	: Rx data valid
	GMII_RXD			,	// in	: Rx data[7:0]
	GMII_RX_ER			,	// in	: Rx error
	GMII_CRS			,	// in	: Carrier sense
	GMII_COL			,	// in	: Collision detected
	// Management IF
	GMII_MDC			,	// out	: Clock for MDIO
	GMII_MDIO_IN		,	// in	: Data
	GMII_MDIO_OUT		,	// out	: Data
	GMII_MDIO_OE		,	// out	: MDIO output enable
// User I/F
	SiTCP_RST			,	// out	: Reset for SiTCP and related circuits
	// TCP connection control
	TCP_OPEN_REQ		,	// in	: Reserved input, shoud be 0
	TCP_OPEN_ACK		,	// out	: Acknowledge for open (=Socket busy)
	TCP_ERROR			,	// out	: TCP error, its active period is equal to MSL
	TCP_CLOSE_REQ		,	// out	: Connection close request
	TCP_CLOSE_ACK		,	// in	: Acknowledge for closing
	// FIFO I/F
	TCP_RX_WC			,	// in	: Rx FIFO write count[15:0] (Unused bits should be set 1)
	TCP_RX_WR			,	// out	: Write enable
	TCP_RX_DATA			,	// out	: Write data[7:0]
	TCP_TX_FULL			,	// out	: Almost full flag
	TCP_TX_WR			,	// in	: Write enable
	TCP_TX_DATA			,	// in	: Write data[7:0]
	// RBCP
	RBCP_ACT			,	// out	: RBCP active
	RBCP_ADDR			,	// out	: Address[31:0]
	RBCP_WD				,	// out	: Data[7:0]
	RBCP_WE				,	// out	: Write enable
	RBCP_RE				,	// out	: Read enable
	RBCP_ACK			,	// in	: Access acknowledge
	RBCP_RD					// in	: Read data[7:0]
);

	parameter	[7:0]	TIM_PERIOD = 8'd143;	// = System clock frequency(MHz)

//-------- Input/Output -------------
	input			CLK				;
	input			RST				;

	input			FORCE_DEFAULTn	;
	input	[31:0]	EXT_IP_ADDR		;
	input	[15:0]	EXT_TCP_PORT	;
	input	[15:0]	EXT_RBCP_PORT	;
	input	[4:0]	PHY_ADDR		;
	output	[47:0]	MY_MAC_ADDR		;

	output			EEPROM_CS		;
	output			EEPROM_SK		;
	output			EEPROM_DI		;
	input			EEPROM_DO		;
	output	[7:0]	USR_REG_X3C		;
	output	[7:0]	USR_REG_X3D		;
	output	[7:0]	USR_REG_X3E		;
	output	[7:0]	USR_REG_X3F		;

	output			GMII_RSTn		;
	input			GMII_1000M		;
	input			GMII_TX_CLK		;
	output			GMII_TX_EN		;
	output	[7:0]	GMII_TXD		;
	output			GMII_TX_ER		;
	input			GMII_RX_CLK		;
	input			GMII_RX_DV		;
	input	[7:0]	GMII_RXD		;
	input			GMII_RX_ER		;
	input			GMII_CRS		;
	input			GMII_COL		;
	output			GMII_MDC		;
	input			GMII_MDIO_IN	;
	output			GMII_MDIO_OUT	;
	output			GMII_MDIO_OE	;

	output			SiTCP_RST		;
	input			TCP_OPEN_REQ	;
	output			TCP_OPEN_ACK	;
	output			TCP_ERROR		;
	output			TCP_CLOSE_REQ	;
	input			TCP_CLOSE_ACK	;
	input	[15:0]	TCP_RX_WC		;
	output			TCP_RX_WR		;
	output	[7:0]	TCP_RX_DATA		;
	output			TCP_TX_FULL		;
	input			TCP_TX_WR		;
	input	[7:0]	TCP_TX_DATA		;
	output			RBCP_ACT		;
	output	[31:0]	RBCP_ADDR		;
	output	[7:0]	RBCP_WD			;
	output			RBCP_WE			;
	output			RBCP_RE			;
	input			RBCP_ACK		;
	input	[7:0]	RBCP_RD			;

//------------------------------------------------------------------------------
//	Timer
//------------------------------------------------------------------------------
	wire			TIM_1US				;
	wire			TIM_1MS				;
	wire			TIM_1S				;
	wire			TIM_1MIN			;

	TIMER #(TIM_PERIOD - 8'd2)		TIMER(
	// System
		.CLK					(CLK					),	// in	: System clock
		.RST					(RST					),	// in	: System reset
	// Intrrupts
		.TIM_1US				(TIM_1US				),	// out	: 1 us interval
		.TIM_1MS				(TIM_1MS				),	// out	: 1 ms interval
		.TIM_1S					(TIM_1S					),	// out	: 1 s interval
		.TIM_1M					(TIM_1MIN				)	// out	: 1 min interval
	);

//------------------------------------------------------------------------------
//	SiTCP library
//------------------------------------------------------------------------------


	wire	[31:0]	DEFAULT_IP_ADDR		;
	wire	[31:0]	MY_IP_ADDR			;

	wire	[15:0]	DEFAULT_TCP_PORT	;
	wire	[15:0]	MY_TCP_PORT			;

	wire	[15:0]	DEFAULT_RBCP_PORT	;
	wire	[15:0]	MY_RBCP_PORT		;

	assign	MY_TCP_PORT[15:0]	= (~FORCE_DEFAULTn | (EXT_TCP_PORT[15:0]==16'd0)	? DEFAULT_TCP_PORT[15:0]	: EXT_TCP_PORT[15:0]	);
	assign	MY_RBCP_PORT[15:0]	= (~FORCE_DEFAULTn | (EXT_RBCP_PORT[15:0]==16'd0)	? DEFAULT_RBCP_PORT[15:0]	: EXT_RBCP_PORT[15:0]	);
	assign	MY_IP_ADDR[31:0]	= (~FORCE_DEFAULTn | (EXT_IP_ADDR[31:0]==32'd0) 	? DEFAULT_IP_ADDR[31:0]		: EXT_IP_ADDR[31:0]		);

    wire    [47:0]  TCP_SERVER_MAC      ;
    wire    [31:0]  TCP_SERVER_ADDR     ;
    wire    [15:0]  TCP_SERVER_PORT     ;

	wire	[31:0]	RBCP_ADDR			;
	wire	[7:0]	RBCP_WD				;
	wire	[7:0]	RBCP_RD				;

	wire			TCP_OPEN_ERROR		;
	wire			TCP_TX_OW_ERROR	;

	assign	TCP_ERROR	= TCP_OPEN_ERROR | TCP_TX_OW_ERROR;

//------------------------------------------------------------------------------
//	SiTCP library
//------------------------------------------------------------------------------
	SiTCP_XC7K_32K_BBT_V100	SiTCP(
		.CLK					(CLK					),	// in	: System clock
		.RST					(RST					),	// in	: System reset
		.TIM_1US				(TIM_1US				),	// in	: 1 us interval
		.TIM_1MS				(TIM_1MS				),	// in	: 1 ms interval
		.TIM_1S					(TIM_1S					),	// in	: 1 s interval
		.TIM_1M					(TIM_1MIN				),	// in	: 1 min interval
	// Configuration parameters
		.FORCE_DEFAULTn			(FORCE_DEFAULTn			),	// in	: Load default values
		.MODE_GMII				(1'b1					),	// in	: PHY I/F mode (0:MII, 1:GMII)
        .MIN_RX_IPG             (4'd4                   ),   // in   : Min. IPG byte[3:0] range of 3 to 15
		.IP_ADDR_IN				(MY_IP_ADDR[31:0]		),	// in	: My IP address[31:0]
		.IP_ADDR_DEFAULT		(DEFAULT_IP_ADDR[31:0]	),	// out	: Default value for my IP address[31:0]
		.MY_MAC_ADDR			(MY_MAC_ADDR		),	// out	: My MAC address[47:0]
		.TCP_MAIN_PORT_IN		(MY_TCP_PORT[15:0]		),	// in	: My TCP main-port #[15:0]
		.TCP_MAIN_PORT_DEFAULT	(DEFAULT_TCP_PORT[15:0]	),	// out	: Default value for my TCP main-port #[15:0]
		.TCP_SUB_PORT_IN		(0						),	// in	: My TCP sub-port #[15:0]
		.TCP_SUB_PORT_DEFAULT   (),	// out	: Default value for my TCP sub-port #[15:0]
        .TCP_SERVER_MAC_IN      (TCP_SERVER_MAC[47:0]   ),   // in   : Client mode, Server MAC address[47:0]
        .TCP_SERVER_MAC_DEFAULT (TCP_SERVER_MAC[47:0]   ),   // out  : Default value for the server's MAC address
        .TCP_SERVER_ADDR_IN     (TCP_SERVER_ADDR[31:0]  ),   // in   : Client mode, Server IP address[31:0]
        .TCP_SERVER_ADDR_DEFAULT(TCP_SERVER_ADDR[31:0]  ),   // out  : Default value for the server's IP address
	    .TCP_SERVER_PORT_IN     (TCP_SERVER_PORT[15:0]  ),	// in	: Client mode, Server wating port#[15:0]
	    .TCP_SERVER_PORT_DEFAULT(TCP_SERVER_PORT[15:0]  ),// out	: Default value for the server port #[15:0]	RBCP_PORT_IN		,	// in	: My UDP RBCP-port #[15:0]
		.RBCP_PORT_IN			(MY_RBCP_PORT[15:0]		),	// in	: My UDP RBCP-port #[15:0]
		.RBCP_PORT_DEFAULT		(DEFAULT_RBCP_PORT[15:0]),	// out	: Default value for my UDP RBCP-port #[15:0]
		.PHY_ADDR				(PHY_ADDR[4:0]			),	// in	: PHY-device MIF address[4:0]
	// EEPROM
		.EEPROM_CS				(EEPROM_CS				),	// out	: Chip select
		.EEPROM_SK				(EEPROM_SK				),	// out	: Serial data clock
		.EEPROM_DI				(EEPROM_DI				),	// out	: Serial write data
		.EEPROM_DO				(EEPROM_DO				),	// in	: Serial read data
		// user data, intialial values are stored in the EEPROM, 0xFFFF_FC3C-3F
		.USR_REG_X3C			(USR_REG_X3C[7:0]		),	// out	: Stored at 0xFFFF_FF3C
		.USR_REG_X3D			(USR_REG_X3D[7:0]		),	// out	: Stored at 0xFFFF_FF3D
		.USR_REG_X3E			(USR_REG_X3E[7:0]		),	// out	: Stored at 0xFFFF_FF3E
		.USR_REG_X3F			(USR_REG_X3F[7:0]		),	// out	: Stored at 0xFFFF_FF3F
	// MII interface
		.GMII_1000M				(GMII_1000M				),	// in	: GMII mode (0:MII, 1:GMII)
		.GMII_RSTn				(GMII_RSTn				),	// in	: PHY reset
		// TX
		.GMII_TX_CLK			(GMII_TX_CLK			),	// in	: Tx clock(2.5 or 25MHz)
		.GMII_TX_EN				(GMII_TX_EN				),	// out	: Tx enable
		.GMII_TXD				(GMII_TXD[7:0]			),	// out	: Tx data[7:0]
		.GMII_TX_ER				(GMII_TX_ER				),	// out	: TX error
		// RX
		.GMII_RX_CLK			(GMII_RX_CLK			),	// in	: Rx clock(2.5 or 25MHz)
		.GMII_RX_DV				(GMII_RX_DV				),	// in	: Rx data valid
		.GMII_RXD				(GMII_RXD[7:0]			),	// in	: Rx data[7:0]
		.GMII_RX_ER				(GMII_RX_ER				),	// in	: Rx error
		.GMII_CRS				(GMII_CRS				),	// in	: Carrier sense
		.GMII_COL				(GMII_COL				),	// in	: Collision detected
		// Management IF
		.GMII_MDC				(GMII_MDC				),	// out	: Clock for MDIO
		.GMII_MDIO_IN			(GMII_MDIO_IN			),	// in	: Data
		.GMII_MDIO_OUT			(GMII_MDIO_OUT			),	// out	: Data
		.GMII_MDIO_OE			(GMII_MDIO_OE			),	// out	: MDIO output enable
	// User I/F
		.SiTCP_RST				(SiTCP_RST				),	// out	: Reset for SiTCP and related circuits
		// TCP connection control
		.OPEN_REQ				(TCP_OPEN_REQ			),	// in	: Request to connect connection
		.MAIN_OPEN_ACK			(TCP_OPEN_ACK			),	// out	: Acknowledge for open (=Socket busy)
		.SUB_OPEN_ACK			(),	// out	: Acknowledge for the alternative port
		.TCP_OPEN_ERROR		(TCP_OPEN_ERROR		),	// out	: TCP client mode / TCP connection error ---- V2.4 -----
		.TCP_TX_OW_ERROR     (TCP_TX_OW_ERROR		),   // out  : TCP TX buffer, over write error ---- V2.4 -----
		.CLOSE_REQ				(TCP_CLOSE_REQ			),	// out	: Connection close
		.CLOSE_ACK				(TCP_CLOSE_ACK			),	// in	: Acknowledge for close
		// FIFO I/F
		.RX_FILL				(TCP_RX_WC[15:0]		),	// in	: Fill level[15:0]
		.RX_WR					(TCP_RX_WR				),	// out	: Write enable
		.RX_DATA				(TCP_RX_DATA[7:0]		),	// out	: Write data[7:0]
		.TX_FULL				(TCP_TX_FULL			),	// out	: Almost full flag
		.TX_FILL				(),	// out	: Fill level[15:0]
		.TX_WR					(TCP_TX_WR				),	// in	: Write enable
		.TX_DATA				(TCP_TX_DATA[7:0]		),	// in	: Write data[7:0]
		// RBCP
		.LOC_ACT				(RBCP_ACT				),	// out	: RBCP active
		.LOC_ADDR				(RBCP_ADDR[31:0]		),	// out	: Address[31:0]
		.LOC_WD					(RBCP_WD[7:0]			),	// out	: Data[7:0]
		.LOC_WE					(RBCP_WE				),	// out	: Write enable
		.LOC_RE					(RBCP_RE				),	// out	: Read enable
		.LOC_ACK				(RBCP_ACK				),	// in	: Access acknowledge
		.LOC_RD					(RBCP_RD[7:0]			)	// in	: Read data[7:0]
	);

//------------------------------------------------------------------------------
endmodule
