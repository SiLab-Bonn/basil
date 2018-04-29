/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ns / 1ps

module mmc3_eth_core(
    input wire RESET_N,

    // clocks from PLL clock buffers
    input wire BUS_CLK, CLK125TX, CLK125TX90, CLK125RX,
    input wire PLL_LOCKED,

    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
    inout wire  [31:0]  BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS,

    input wire          fifo_empty,
    input wire          fifo_full,
    input wire          FIFO_NEXT,
    output wire         FIFO_WRITE,
    output wire [31:0]  FIFO_DATA,

    output wire [7:0]   GPIO
);


/* -------  MODULE ADREESSES  ------- */
    localparam GPIO_BASEADDR = 32'h1000;
    localparam GPIO_HIGHADDR = 32'h101f;


/* -------  USER MODULES  ------- */
    gpio #(
        .BASEADDR(GPIO_BASEADDR),
        .HIGHADDR(GPIO_HIGHADDR),
        .ABUSWIDTH(32),
        .IO_WIDTH(8),
        .IO_DIRECTION(8'hff)
    ) i_gpio_rx (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO(GPIO)
    );
    wire EN;
    assign EN = GPIO[0];

    reg [31:0] datasource;
    reg fifo_write;
    assign FIFO_WRITE = !fifo_full & EN;
    reg [31:0] fifo_data_out;
    assign FIFO_DATA = fifo_data_out;


    always@ (posedge BUS_CLK)
        if(!EN)
            fifo_data_out <= 0;
        else if(FIFO_WRITE)
            fifo_data_out <= fifo_data_out + 1;

endmodule
