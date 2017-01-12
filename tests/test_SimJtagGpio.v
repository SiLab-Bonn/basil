/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
`timescale 1ps / 1ps

`include "utils/bus_to_ip.v"
`include "gpio/gpio.v"

module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [15:0]  BUS_ADD,
    inout wire  [7:0]   BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR
);   

    localparam GPIO_BASEADDR = 16'h0000;
    localparam GPIO_HIGHADDR = 16'h000f;
    
    localparam GPIO_BASEADDR_DEV1 = 16'h1000;
    localparam GPIO_HIGHADDR_DEV1 = 16'h100f;
    
    localparam GPIO_BASEADDR_DEV2 = 16'h2000;
    localparam GPIO_HIGHADDR_DEV2 = 16'h200f;
    
    wire [7:0] IO;
    gpio 
    #( 
        .BASEADDR(GPIO_BASEADDR), 
        .HIGHADDR(GPIO_HIGHADDR),
        .IO_WIDTH(8),
        .IO_DIRECTION(8'b0000_1111)
    ) i_gpio
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO(IO)
    );
    
    wire RESETB, TCK, TMS, TDI, TDO;
    assign RESETB = IO[0];
    assign TCK = IO[1];
    assign TMS = IO[2];
    assign TDI = IO[3];
    assign IO[4] = TDO;
    assign IO[7:5] = 0;
    
    wire td_int;
    wire [31:0] debug_reg1, debug_reg2;
    
    jtag_tap i_jtag_tap1(.jtag_tms_i(TMS), .jtag_tck_i(TCK), .jtag_trstn_i(1'b1), .jtag_tdi_i(TDI), .jtag_tdo_o(td_int), .debug_reg(debug_reg2));
    jtag_tap i_jtag_tap2(.jtag_tms_i(TMS), .jtag_tck_i(TCK), .jtag_trstn_i(1'b1), .jtag_tdi_i(td_int), .jtag_tdo_o(TDO), .debug_reg(debug_reg1));
    
    wire D1_F1;
    wire [5:0] D1_F2;
    wire [3:0] D1_F3;
    wire [20:0] D1_F4;
    assign {D1_F4, D1_F3, D1_F2, D1_F1} = debug_reg1;
    
    wire D2_F1;
    wire [5:0] D2_F2;
    wire [3:0] D2_F3;
    wire [20:0] D2_F4;
    assign {D2_F4, D2_F3, D2_F2, D2_F1} = debug_reg2;
    
    gpio 
    #( 
        .BASEADDR(GPIO_BASEADDR_DEV1), 
        .HIGHADDR(GPIO_HIGHADDR_DEV1),
        .IO_WIDTH(32),
        .IO_DIRECTION(32'h00000000)
    ) i_gpio_dev2
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO(debug_reg2)
    );
    
    gpio 
    #( 
        .BASEADDR(GPIO_BASEADDR_DEV2), 
        .HIGHADDR(GPIO_HIGHADDR_DEV2),
        .IO_WIDTH(32),
        .IO_DIRECTION(32'h00000000)
    ) i_gpio_dev1
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO(debug_reg1)
    );
    
    initial begin
        $dumpfile("jtag_gpio.vcd");
        $dumpvars(0);
    end 
    
endmodule
