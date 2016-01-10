/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module tdc_s3 #(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    parameter CLKDV = 4,
    parameter DATA_IDENTIFIER = 4'b0100,
    parameter ABUSWIDTH = 16,
    parameter FAST_TDC = 1,
    parameter FAST_TRIGGER = 1
)(
    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    inout wire [7:0] BUS_DATA,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    input wire CLK320,
    input wire CLK160,
    input wire DV_CLK, // clock synchronous to CLK160 division factor can be set by CLKDV parameter
    input wire TDC_IN,
    output wire TDC_OUT,
    input wire TRIG_IN,
    output wire TRIG_OUT,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    input wire ARM_TDC,
    input wire EXT_EN,

    input wire [15:0] TIMESTAMP
);

wire IP_RD, IP_WR;
wire [ABUSWIDTH-1:0] IP_ADD;
wire [7:0] IP_DATA_IN;
wire [7:0] IP_DATA_OUT;

bus_to_ip #(
    .BASEADDR(BASEADDR),
    .HIGHADDR(HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH)
) i_bus_to_ip (
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),

    .IP_RD(IP_RD),
    .IP_WR(IP_WR),
    .IP_ADD(IP_ADD),
    .IP_DATA_IN(IP_DATA_IN),
    .IP_DATA_OUT(IP_DATA_OUT)
);

tdc_s3_core #(
    .DATA_IDENTIFIER(DATA_IDENTIFIER),
    .CLKDV(CLKDV),
    .ABUSWIDTH(ABUSWIDTH),
    .FAST_TDC(FAST_TDC),
    .FAST_TRIGGER(FAST_TRIGGER)
) i_tdc_s3_core (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),

    .CLK320(CLK320),
    .CLK160(CLK160),
    .DV_CLK(DV_CLK),
    .TDC_IN(TDC_IN),
    .TDC_OUT(TDC_OUT),
    .TRIG_IN(TRIG_IN),
    .TRIG_OUT(TRIG_OUT),

    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),

    .ARM_TDC(ARM_TDC),
    .EXT_EN(EXT_EN),

    .TIMESTAMP(TIMESTAMP)
);

endmodule
