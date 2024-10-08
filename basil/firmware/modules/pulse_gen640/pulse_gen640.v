/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module pulse_gen640
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    parameter ABUSWIDTH = 16,
    parameter CLKDV = 4,
    parameter OUTPUT_SIZE =2 
)(
    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    inout wire [7:0] BUS_DATA,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    input wire  PULSE_CLK,
    input wire PULSE_CLK160,
    input wire  PULSE_CLK320,
    input wire  EXT_START,
    output wire [OUTPUT_SIZE-1:0] PULSE,
    output wire DEBUG
); 

wire IP_RD, IP_WR;
wire [ABUSWIDTH-1:0] IP_ADD;
wire [7:0] IP_DATA_IN;
wire [7:0] IP_DATA_OUT;

bus_to_ip #( .BASEADDR(BASEADDR), .HIGHADDR(HIGHADDR), .ABUSWIDTH(ABUSWIDTH) ) i_bus_to_ip
(
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

pulse_gen640_core #(
    .ABUSWIDTH(ABUSWIDTH),
    .CLKDV(CLKDV),
    .OUTPUT_SIZE(OUTPUT_SIZE)
) i_pulse_gen640_core (

    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),
    
    .PULSE_CLK(PULSE_CLK),
    .PULSE_CLK160(PULSE_CLK160),
    .PULSE_CLK320(PULSE_CLK320),
    .EXT_START(EXT_START),
    .PULSE(PULSE),
    .DEBUG(DEBUG)
);

endmodule
