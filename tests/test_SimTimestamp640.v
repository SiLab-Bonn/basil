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

`include "pulse_gen640/pulse_gen640.v"
`include "pulse_gen640/pulse_gen640_core.v"
`include "utils/clock_multiplier.v"
`include "utils/DCM_sim.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"

`include "timestamp640/timestamp640.v"
`include "timestamp640/timestamp640_core.v"

`include "utils/cdc_syncfifo.v"
`include "utils/generic_fifo.v"
`include "utils/cdc_pulse_sync.v"
`include "utils/CG_MOD_pos.v"
`include "utils/clock_divider.v"
`include "utils/3_stage_synchronizer.v"
`include "utils/RAMB16_S1_S9_sim.v"
`include "utils/ddr_des.v"
`include "utils/IDDR_sim.v"
`include "utils/OSERDESE2_sim.v"

module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
    inout wire  [31:0]  BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS
);

// MODULE ADREESSES //
localparam GPIO_BASEADDR = 32'h0000;
localparam GPIO_HIGHADDR = 32'h1000-1;

localparam TIMESTAMP_BASEADDR = 32'h1000; //0x1000
localparam TIMESTAMP_HIGHADDR = 32'h2000-1;   //0x300f


localparam PULSE_BASEADDR = 32'h3000;
localparam PULSE_HIGHADDR = PULSE_BASEADDR + 15;

localparam FIFO_BASEADDR = 32'h8000;
localparam FIFO_HIGHADDR = 32'h9000-1;

localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;

localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

// MODULES //
wire CLK640,CLK320,CLK160,CLK40,CLK320_TO_DCM;

DCM #(
    .CLKFX_MULTIPLY(40),
    .CLKFX_DIVIDE(3)
) i_dcm_1 (
    .CLK0(), .CLK180(), .CLK270(), .CLK2X(), .CLK2X180(), .CLK90(),
    .CLKDV(), .CLKFX(CLK320_TO_DCM), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(),
    .CLKFB(1'b0), .CLKIN(BUS_CLK), .DSSEN(1'b0), .PSCLK(1'b0), .PSEN(1'b0), .PSINCDEC(1'b0), .RST(1'b0)
);

DCM #(
    .CLKFX_MULTIPLY(1),
    .CLKFX_DIVIDE(2),
    .CLKDV_DIVIDE(8)
) i_dcm_2 (
    .CLK0(CLK320), .CLK180(), .CLK270(), .CLK2X(CLK640), .CLK2X180(), .CLK90(),
    .CLKDV(CLK40), .CLKFX(CLK160), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(),
    .CLKFB(1'b0), .CLKIN(CLK320_TO_DCM), .DSSEN(1'b0), .PSCLK(1'b0), .PSEN(1'b0), .PSINCDEC(1'b0), .RST(1'b0)
);

reg [63:0] TIMESTAMP;
wire [63:0] TIMESTAMP_OUT;
gpio #(
    .BASEADDR(GPIO_BASEADDR),
    .HIGHADDR(GPIO_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .IO_WIDTH(64),
    .IO_DIRECTION(64'h0)
) i_gpio (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(TIMESTAMP_OUT)
);

wire PULSE;
pulse_gen640 #(
    .BASEADDR(PULSE_BASEADDR),
    .HIGHADDR(PULSE_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .OUTPUT_SIZE(1) 
) i_pulse_gen (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .PULSE_CLK(CLK40),
    .PULSE_CLK160(CLK160),
    .PULSE_CLK320(CLK320),
    .EXT_START(1'b0),
    .PULSE(PULSE)
);

always @(posedge CLK40)
    TIMESTAMP <= TIMESTAMP + 1;

wire FIFO_READ, FIFO_EMPTY;
wire [31:0] FIFO_DATA;
wire EXT_ENABLE;
assign EXT_ENABLE = 1'b0;
timestamp640 #(
    .BASEADDR(TIMESTAMP_BASEADDR),
    .HIGHADDR(TIMESTAMP_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .IDENTIFIER(4'b0101)
) i_timestamp (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .CLK320(CLK320),
    .CLK160(CLK160),
    .CLK40(CLK40),
    .DI(PULSE),
    .EXT_TIMESTAMP(TIMESTAMP),
    .TIMESTAMP_OUT(TIMESTAMP_OUT),
    .EXT_ENABLE(EXT_ENABLE),

    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA)
);

bram_fifo #(
    .BASEADDR(FIFO_BASEADDR),
    .HIGHADDR(FIFO_HIGHADDR),
    .BASEADDR_DATA(FIFO_BASEADDR_DATA),
    .HIGHADDR_DATA(FIFO_HIGHADDR_DATA),
    .ABUSWIDTH(ABUSWIDTH)
) i_out_fifo (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .FIFO_READ_NEXT_OUT(FIFO_READ),
    .FIFO_EMPTY_IN(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),

    .FIFO_NOT_EMPTY(),
    .FIFO_FULL(),
    .FIFO_NEAR_FULL(),
    .FIFO_READ_ERROR()
);

initial begin
    $dumpfile("timestamp640.vcd");
    $dumpvars(0);
end

endmodule
