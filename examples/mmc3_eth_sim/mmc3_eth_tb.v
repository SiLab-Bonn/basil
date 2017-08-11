`timescale 1ns / 1ps
/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University
 * ------------------------------------------------------------
 */

`include "src/mmc3_eth_core.v"
`include "utils/reset_gen.v"
`include "gpio/gpio.v"
`include "utils/fifo_32_to_8.v"
`include "utils/generic_fifo.v"
`include "utils/clock_multiplier.v"
`include "utils/clock_divider.v"
`include "utils/rbcp_to_bus.v"
`include "utils/bus_to_ip.v"


module mmc3_etc_tb (
    input wire FCLK_IN, // 48MHz
    output wire [7:0] LED
);

localparam RESET_DELAY = 5000;
reg RESET_N;


localparam CLOCKPERIOD_CLKIN1 = 10*1000;
reg CLKIN1;
initial CLKIN1 = 1'b0;
always #(CLOCKPERIOD_CLKIN1 / 2) CLKIN1 = !CLKIN1;


// ----- Clock (mimics a PLL) -----
localparam PLL_MUL            = 10;
localparam PLL_DIV_BUS_CLK    = 7;
localparam PLL_DIV_CLK250     = 4;
localparam PLL_DIV_CLK125TX   = 8;
localparam PLL_DIV_CLK125TX90 = 8;
localparam PLL_DIV_CLK125RX   = 8;
localparam PLL_LOCK_DELAY     = 1000*1000;

wire BUS_CLK, PLL_VCO, CLK250, CLK125TX, CLK125TX90, CLK125RX;
reg LOCKED;

clock_multiplier #( .MULTIPLIER(PLL_MUL)  ) i_clock_multiplier( .CLK(CLKIN1),                       .CLOCK(PLL_VCO)  );
clock_divider #(.DIVISOR(PLL_DIV_BUS_CLK) ) i_clock_divisor_1(  .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(BUS_CLK)  );
clock_divider #(.DIVISOR(PLL_DIV_CLK250)  ) i_clock_divisor_2(  .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(CLK250)   );
clock_divider #(.DIVISOR(PLL_DIV_CLK125TX)) i_clock_divisor_3(  .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(CLK125TX) );
clock_divider #(.DIVISOR(PLL_DIV_CLK125RX)) i_clock_divisor_4(  .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(CLK125RX) );

initial begin
    LOCKED = 1'b0;
    #(PLL_LOCK_DELAY) LOCKED = 1'b1;
end
// ----- ----- ----- ----- -----


initial begin
    RESET_N = 1'b0;
    #(RESET_DELAY) RESET_N = 1'b1;
end

//assign RST = !RESET_N | !LOCKED;


wire BUS_RST;

// ------- RESRT/CLOCK  ------- //
reset_gen ireset_gen(.CLK(BUS_CLK), .RST(BUS_RST));



// SiTCP
wire SiTCP_RST;
wire RBCP_ACT, RBCP_WE, RBCP_RE;
wire RBCP_ACK;
wire [7:0] RBCP_WD, RBCP_RD;
wire [31:0] RBCP_ADDR;

wire TCP_CLOSE_REQ;
wire TCP_OPEN_ACK;
wire TCP_RX_WR;
wire TCP_TX_WR;
wire [7:0] TCP_RX_DATA;
wire [7:0] TCP_TX_DATA;
wire TCP_TX_FULL;
wire [10:0] TCP_RX_WC_11B;

mmc3_eth_core i_mmc3_eth_core(
    .RESET_N(RESET_N),

    // clocks from PLL
    .BUS_CLK(BUS_CLK), .CLK125TX(CLK125TX), .CLK125TX90(CLK125TX90), .CLK125RX(CLK125RX),
    .PLL_LOCKED(LOCKED),

    // User I/F
    .SiTCP_RST(SiTCP_RST)           ,    // out : Reset for SiTCP and related circuits
    // TCP connection control
    .TCP_OPEN_REQ()                 ,    // in  : Reserved input, shoud be 0
    .TCP_OPEN_ACK(TCP_OPEN_ACK)     ,    // out : Acknowledge for open (=Socket busy)
    .TCP_ERROR()                    ,    // out : TCP error, its active period is equal to MSL
    .TCP_CLOSE_REQ(TCP_CLOSE_REQ)   ,    // out : Connection close request
    .TCP_CLOSE_ACK(TCP_CLOSE_REQ)   ,    // in  : Acknowledge for closing
    // FIFO I/F
    .TCP_RX_WC_11B(TCP_RX_WC_11B)   ,    // in  : Rx FIFO write count[15:0] (Unused bits should be set 1)
    .TCP_RX_WR(TCP_RX_WR)           ,    // out : Write enable
    .TCP_RX_DATA(TCP_RX_DATA)       ,    // out : Write data[7:0]
    .TCP_TX_FULL(TCP_TX_FULL)       ,    // out : Almost full flag
    .TCP_TX_WR(TCP_TX_WR)           ,    // in  : Write enable
    .TCP_TX_DATA(TCP_TX_DATA)       ,    // in  : Write data[7:0]
    // RBCP
    .RBCP_ACT(RBCP_ACT)             ,    // out : RBCP active
    .RBCP_ADDR(RBCP_ADDR)           ,    // out : Address[31:0]
    .RBCP_WD(RBCP_WD)               ,    // out : Data[7:0]
    .RBCP_WE(RBCP_WE)               ,    // out : Write enable
    .RBCP_RE(RBCP_RE)               ,    // out : Read enable
    .RBCP_ACK(RBCP_ACK)             ,    // in  : Access acknowledge
    .RBCP_RD(RBCP_RD)               ,    // in  : Read data[7:0]

    .LED(LED)
    );


endmodule
