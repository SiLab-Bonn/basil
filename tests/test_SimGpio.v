/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

`ifdef BASIL_SBUS
    `define SPLIT_BUS
`elsif BASIL_TOPSBUS
    `define SPLIT_BUS
`endif

`include "gpio/gpio_core.v"
`ifndef BASIL_SBUS
    `include "utils/bus_to_ip.v"
    `include "gpio/gpio.v"
`else
    `include "utils/sbus_to_ip.v"
    `include "gpio/gpio_sbus.v"
`endif

module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [15:0]  BUS_ADD,
`ifndef SPLIT_BUS
    inout wire  [7:0]   BUS_DATA,
`else
    input wire  [7:0]   BUS_DATA_IN,
    output wire [7:0]   BUS_DATA_OUT,
`endif
    input wire          BUS_RD,
    input wire          BUS_WR
);

localparam GPIO_BASEADDR = 16'h0000;
localparam GPIO_HIGHADDR = 16'h000f;

localparam GPIO2_BASEADDR = 16'h0010;
localparam GPIO2_HIGHADDR = 16'h001f;

// Connect tb internal bus to external split bus
`ifdef BASIL_TOPSBUS
    wire [7:0] BUS_DATA;
    assign BUS_DATA = BUS_DATA_IN;
    assign BUS_DATA_OUT = BUS_DATA;
`elsif BASIL_SBUS
    wire [7:0] BUS_DATA_OUT_1;
    wire [7:0] BUS_DATA_OUT_2;
    assign BUS_DATA_OUT = BUS_DATA_OUT_1 | BUS_DATA_OUT_2;
`endif

/* verilator lint_off UNOPT */
wire [23:0] IO;

assign IO[15:8] = IO[7:0];
assign IO[23:20] = IO[19:16];
/* verilator lint_on UNOPT */

`ifndef BASIL_SBUS
gpio #(
`else
gpio_sbus #(
`endif
    .BASEADDR(GPIO_BASEADDR),
    .HIGHADDR(GPIO_HIGHADDR),
    .IO_WIDTH(24),
    .IO_DIRECTION(24'h0000ff),
    .IO_TRI(24'hff0000)
) i_gpio (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
`ifndef BASIL_SBUS
    .BUS_DATA(BUS_DATA),
`else
    .BUS_DATA_IN(BUS_DATA_IN),
    .BUS_DATA_OUT(BUS_DATA_OUT_1),
`endif
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(IO)
);

wire [15:0] IO_2;
assign IO_2 = 16'ha5cd;

`ifndef BASIL_SBUS
gpio #(
`else
gpio_sbus #(
`endif
    .BASEADDR(GPIO2_BASEADDR),
    .HIGHADDR(GPIO2_HIGHADDR),
    .IO_WIDTH(16),
    .IO_DIRECTION(16'h0000)
) i_gpio2 (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
`ifndef BASIL_SBUS
    .BUS_DATA(BUS_DATA),
`else
    .BUS_DATA_IN(BUS_DATA_IN),
    .BUS_DATA_OUT(BUS_DATA_OUT_2),
`endif
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(IO_2)
);

`ifndef VERILATOR_SIM
initial begin
    $dumpfile("gpio.vcd");
    $dumpvars(0);
end
`endif

endmodule
