`default_nettype wire
/*******************************************************************************
*                                                                              *
* System      : SiTCP GMII library                                             *
* Block       : ----                                                           *
* Module      : LIB_SiTCP_GMII                                                 *
* Version     : v 2.0  2009/12/11                                              *
*               v 3.0  2010/04/21 Change polarity of system reset              *
*				v 5.0  2012/02/15 10BASE-T can not use when exceed 83MHz       *
*               v 6.0  2012/11/20 Activate a TCP clinet mode                   *
*				v 7.0  2012/11/26 By ver up of SiTCP core to V2.4              *
*				v 7.1  2013/10/01 New function: variable RX-IFG in GMII        *
*				v 8.0  2013/10/03 Release V7.1                                 *
*				v 9.0  2016/02/08 Add MAC address port                         *
*               v 10.0 2016/08/26 RX bug fixed                                 *
*                                                                              *
* Description : Top Module                                                     *
*                                                                              *
*                Copyright (c) 2010 Bee Beans Technologies Co.,Ltd.            *
*                All rights reserved                                           *
*                                                                              *
*******************************************************************************/

module SiTCP_XC7K_32K_BBT_V100(
	CLK					,	// in	: System Clock 25MHz
	RST					,	// in	: System reset
	TIM_1US				,	// in	: 1 us interval
	TIM_1MS				,	// in	: 1 ms interval
	TIM_1S				,	// in	: 1 s interval
	TIM_1M				,	// in	: 1 min interval
// Configuration parameters
	FORCE_DEFAULTn		,	// in	: Load default values
	MODE_GMII			,	// in	: PHY I/F mode (0:MII, 1:GMII)
	IP_ADDR_IN			,	// in	: My IP address[31:0]
	IP_ADDR_DEFAULT		,	// out	: Default value for my IP address[31:0]
	MY_MAC_ADDR			,	// out	: My MAC address[47:0]	
	TCP_MAIN_PORT_IN	,	// in	: My TCP main-port #[15:0]
	TCP_MAIN_PORT_DEFAULT,	// out	: Default value for my TCP main-port #[15:0]
	TCP_SUB_PORT_IN		,	// in	: My TCP sub-port #[15:0]
	TCP_SUB_PORT_DEFAULT,	// out	: Default value for my TCP sub-port #[15:0]
    TCP_SERVER_MAC_IN  ,   // in   : Client mode, Server MAC address[47:0]
    TCP_SERVER_MAC_DEFAULT,   // in   : Default value for the server's MAC address
    TCP_SERVER_ADDR_IN  ,   // in   : Client mode, Server IP address[31:0]
    TCP_SERVER_ADDR_DEFAULT,   // in   : Default value for the server's IP address
	TCP_SERVER_PORT_IN	,	// in	: Client mode, Server wating port#[15:0]
	TCP_SERVER_PORT_DEFAULT,// out	: Default value for the server port #[15:0]
	RBCP_PORT_IN		,	// in	: My UDP RBCP-port #[15:0]
	RBCP_PORT_DEFAULT	,	// out	: Default value for my UDP RBCP-port #[15:0]
	PHY_ADDR			,	// in	: PHY-device MIF address[4:0]
    MIN_RX_IPG          ,   // in   : Min. IPG byte[3:0]
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
	GMII_1000M			,	// in	: GMII mode (0:MII, 1:GMII)
	GMII_RSTn			,	// in	: PHY reset
	// TX
	GMII_TX_CLK			,	// in	: Tx clock(2.5 or 25MHz)
	GMII_TX_EN			,	// out	: Tx enable
	GMII_TXD			,	// out	: Tx data[3:0]
	GMII_TX_ER			,	// out	: TX error
	// RX
	GMII_RX_CLK			,	// in	: Rx clock(2.5 or 25MHz)
	GMII_RX_DV			,	// in	: Rx data valid
	GMII_RXD			,	// in	: Rx data[3:0]
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
	OPEN_REQ			,	// in	: Request to connect connection
	MAIN_OPEN_ACK		,	// out	: Acknowledge for open (=Socket busy)
	SUB_OPEN_ACK		,	// out	: Acknowledge for the alternative port
	TCP_OPEN_ERROR		,	// out	: TCP client mode / TCP connection error ---- V2.4 -----
    TCP_TX_OW_ERROR     ,   // out  : TCP TX buffer, over write error ---- V2.4 -----
	CLOSE_REQ			,	// out	: Connection close
	CLOSE_ACK			,	// in	: Acknowledge for close
	// FIFO I/F
	RX_FILL				,	// in	: Fill level[15:0]
	RX_WR				,	// out	: Write enable
	RX_DATA				,	// out	: Write data[7:0]
	TX_FULL				,	// out	: Almost full flag
	TX_FILL				,	// out	: Fill level[15:0]
	TX_WR				,	// in	: Write enable
	TX_DATA				,	// in	: Write data[7:0]
	// RBCP
	LOC_ACT				,	// out	: RBCP active
	LOC_ADDR			,	// out	: Address[31:0]
	LOC_WD				,	// out	: Data[7:0]
	LOC_WE				,	// out	: Write enable
	LOC_RE				,	// out	: Read enable
	LOC_ACK				,	// in	: Access acknowledge
	LOC_RD					// in	: Read data[7:0]
);

//-------- Input/Output -------------
	input			CLK				;
	input			RST			;
	input			TIM_1US			;
	input			TIM_1MS			;
	input			TIM_1S			;
	input			TIM_1M			;
	input			FORCE_DEFAULTn	;
	input			MODE_GMII		;
	input	[31:0]	IP_ADDR_IN				;
	output	[31:0]	IP_ADDR_DEFAULT			;
	output	[47:0]	MY_MAC_ADDR				;	
	input	[15:0]	TCP_MAIN_PORT_IN		;
	output	[15:0]	TCP_MAIN_PORT_DEFAULT	;
	input	[15:0]	TCP_SUB_PORT_IN			;
	output	[15:0]	TCP_SUB_PORT_DEFAULT	;
	input	[4:0]	PHY_ADDR				;
	input	[15:0]	RBCP_PORT_IN			;
	output	[15:0]	RBCP_PORT_DEFAULT		;

    input   [3:0]   MIN_RX_IPG      ;

    input   [47:0]  TCP_SERVER_MAC_IN       ;
    output  [47:0]  TCP_SERVER_MAC_DEFAULT  ;
    input   [31:0]  TCP_SERVER_ADDR_IN      ;
    output  [31:0]  TCP_SERVER_ADDR_DEFAULT ;
	input   [15:0]  TCP_SERVER_PORT_IN	    ;
	output  [15:0]  TCP_SERVER_PORT_DEFAULT ;

	output			EEPROM_CS		;
	output			EEPROM_SK		;
	output			EEPROM_DI		;
	input			EEPROM_DO		;
	output	[7:0]	USR_REG_X3C		;
	output	[7:0]	USR_REG_X3D		;
	output	[7:0]	USR_REG_X3E		;
	output	[7:0]	USR_REG_X3F		;

	input			GMII_1000M		;
	output			GMII_RSTn		;
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
	input			OPEN_REQ		;
	output			MAIN_OPEN_ACK	;
	output			SUB_OPEN_ACK	;
	output			TCP_OPEN_ERROR		;
	output			TCP_TX_OW_ERROR	;
	output			CLOSE_REQ		;
	input			CLOSE_ACK		;
	input	[15:0]	RX_FILL			;
	output			RX_WR			;
	output	[7:0]	RX_DATA			;
	output			TX_FULL		;
	output	[15:0]	TX_FILL			;
	input			TX_WR			;
	input	[7:0]	TX_DATA			;
	output			LOC_ACT			;
	output	[31:0]	LOC_ADDR		;
	output	[7:0]	LOC_WD			;
	output			LOC_WE			;
	output			LOC_RE			;
	input			LOC_ACK			;
	input	[7:0]	LOC_RD			;
//--------------------------------------------------------------------------------
endmodule
