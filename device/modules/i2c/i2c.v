/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module i2c #(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    parameter ABUSWIDTH = 16,
    parameter MEM_BYTES = 1
)(
    input wire                 BUS_CLK,
    input wire                 BUS_RST,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    inout wire [7:0]           BUS_DATA,
    input wire                 BUS_RD,
    input wire                 BUS_WR,

    input wire I2C_CLK,
    inout wire I2C_SDA,
    inout wire I2C_SCL
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


i2c_core 
#(
    .ABUSWIDTH(ABUSWIDTH),
    .MEM_BYTES(MEM_BYTES)
)
i_i2c_core (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),

    .I2C_CLK(I2C_CLK),
    .I2C_SDA(I2C_SDA),
    .I2C_SCL(I2C_SCL)
);


endmodule
