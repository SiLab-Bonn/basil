/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */


`timescale 1ns / 1ps


/*
HOW TO USE

Program registers in the following way:
    1. Define the ADDR of the device you want to talk with via i2c by writing the ADDR to 
        BASEADDR + 1
    2. Define the Data you want to send to the device via i2c by writing the Data to
        BASEADDR + 2
    3. Reset the i2c clock via i2c_rst_clk flag to
        BASEADDR + 4	
    4. Start sending to device via start flag to	
        BASEADDR + 3

The module will send then the 7bit addr value to the device. After receiving the ack bit the data is transmitted. If something
goes wrong the error flag will show you that!
*/


module i2c #(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    parameter ABUSWIDTH = 32
)(
    input                 BUS_CLK,
    input                 BUS_RST,
    input [ABUSWIDTH-1:0] BUS_ADD,
    inout [7:0]           BUS_DATA,
    input                 BUS_RD,
    input                 BUS_WR,

    inout i2c_sda,
    inout i2c_scl,
    output busy,
    output error
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


i2c_core i2c_dut (
     .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),

    .i2c_sda(i2c_sda),
    .i2c_scl(i2c_scl),
    .busy(busy),
    .error(error)
);


endmodule
