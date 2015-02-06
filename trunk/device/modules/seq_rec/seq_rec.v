/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module seq_rec
#(
    parameter BASEADDR = 0,
    parameter HIGHADDR = 0,
    parameter ABUSWIDTH = 16,
    
    parameter MEM_BYTES = 8*1024,
    parameter IN_BITS = 8
)(
    input wire                   BUS_CLK,
    input wire                   BUS_RST,
    input wire  [ABUSWIDTH-1:0]  BUS_ADD,
    inout wire  [7:0]            BUS_DATA,
    input wire                   BUS_RD,
    input wire                   BUS_WR,

    input wire                SEQ_CLK,
    input wire [IN_BITS-1:0]  SEQ_IN,
    input wire                SEQ_EXT_START
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

seq_rec_core
#(
    .MEM_BYTES(MEM_BYTES),
    .IN_BITS(IN_BITS),
    .ABUSWIDTH(ABUSWIDTH)
) i_scope_core (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),
    .SEQ_CLK(SEQ_CLK),
    .SEQ_IN(SEQ_IN),
    .SEQ_EXT_START(SEQ_EXT_START)
);

endmodule