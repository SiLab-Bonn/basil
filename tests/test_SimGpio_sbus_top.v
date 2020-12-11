/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

`include "utils/bus_to_ip.v"
`include "gpio/gpio_core.v"
`include "gpio/gpio.v"

module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [15:0]  BUS_ADD,
    input wire  [7:0]   BUS_DATA_IN,
    output wire [7:0]   BUS_DATA_OUT,
    input wire          BUS_RD,
    input wire          BUS_WR
);

localparam GPIO_BASEADDR = 16'h0000;
localparam GPIO_HIGHADDR = 16'h000f;

localparam GPIO2_BASEADDR = 16'h0010;
localparam GPIO2_HIGHADDR = 16'h001f;

// Connect tb internal bus to external split bus
wire [7:0] BUS_DATA;
assign BUS_DATA = BUS_DATA_IN;
assign BUS_DATA_OUT = BUS_DATA;

// FIXME: hack for Verilator optimization error
/* verilator lint_off UNOPT */
wire [23:0] IO;

assign IO[15:8] = IO[7:0];
assign IO[23:20] = IO[19:16];
/* verilator lint_on UNOPT */

gpio #(
    .BASEADDR(GPIO_BASEADDR),
    .HIGHADDR(GPIO_HIGHADDR),
    .IO_WIDTH(24),
    .IO_DIRECTION(24'h0000ff),
    .IO_TRI(24'hff0000)
) i_gpio (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(IO)
);

wire [15:0] IO_2;
assign IO_2 = 16'ha5cd;

gpio #(
    .BASEADDR(GPIO2_BASEADDR),
    .HIGHADDR(GPIO2_HIGHADDR),
    .IO_WIDTH(16),
    .IO_DIRECTION(16'h0000)
) i_gpio2 (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(IO_2)
);

initial begin
    $dumpfile("gpio_sbus2.vcd");
    $dumpvars(0);
end

endmodule
