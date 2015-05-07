/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module cmd_seq
#(
    parameter BASEADDR = 32'h0000,
    parameter HIGHADDR = 32'h0000,
    parameter ABUSWIDTH = 16,
    parameter CMD_MEM_SIZE = 2048
) (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [ABUSWIDTH-1:0]  BUS_ADD,
    inout wire  [7:0]   BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    
    output wire         CMD_CLK_OUT_A,
    output wire         CMD_CLK_OUT_B,
    output wire         CMD_CLK_OUT_C,
    output wire         CMD_CLK_OUT_D,
    output wire         CMD_CLK_OUT_E,
    output wire         CMD_CLK_OUT_F,
    output wire         CMD_CLK_OUT_G,
    output wire         CMD_CLK_OUT_H,
    input wire          CMD_CLK_IN,
    input wire          CMD_EXT_START_FLAG,
    output wire         CMD_EXT_START_ENABLE,
    output wire         CMD_DATA_A,
    output wire         CMD_DATA_B,
    output wire         CMD_DATA_C,
    output wire         CMD_DATA_D,
    output wire         CMD_DATA_E,
    output wire         CMD_DATA_F,
    output wire         CMD_DATA_G,
    output wire         CMD_DATA_H,
    output wire         CMD_READY,
    output wire         CMD_START_FLAG
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


cmd_seq_core
#(
    .CMD_MEM_SIZE(CMD_MEM_SIZE),
    .ABUSWIDTH(ABUSWIDTH)
) i_cmd_seq_core
(
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),
    
    .CMD_CLK_OUT_A(CMD_CLK_OUT_A),
    .CMD_CLK_OUT_B(CMD_CLK_OUT_B),
    .CMD_CLK_OUT_C(CMD_CLK_OUT_C),
    .CMD_CLK_OUT_D(CMD_CLK_OUT_D),
    .CMD_CLK_OUT_E(CMD_CLK_OUT_E),
    .CMD_CLK_OUT_F(CMD_CLK_OUT_F),
    .CMD_CLK_OUT_G(CMD_CLK_OUT_G),
    .CMD_CLK_OUT_H(CMD_CLK_OUT_H),
    .CMD_CLK_IN(CMD_CLK_IN),
    .CMD_EXT_START_FLAG(CMD_EXT_START_FLAG),
    .CMD_EXT_START_ENABLE(CMD_EXT_START_ENABLE),
    .CMD_DATA_A(CMD_DATA_A),
    .CMD_DATA_B(CMD_DATA_B),
    .CMD_DATA_C(CMD_DATA_C),
    .CMD_DATA_D(CMD_DATA_D),
    .CMD_DATA_E(CMD_DATA_E),
    .CMD_DATA_F(CMD_DATA_F),
    .CMD_DATA_G(CMD_DATA_G),
    .CMD_DATA_H(CMD_DATA_H),
    .CMD_READY(CMD_READY),
    .CMD_START_FLAG(CMD_START_FLAG)
);

endmodule
