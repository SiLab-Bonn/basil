/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Physics Institute, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ns / 1ps

module bdaq53_eth_core(
        input wire RESET_N,

        // clocks from PLL clock buffers
        input wire BUS_CLK,
        input wire PLL_LOCKED,

        input wire          BUS_RST,
        input wire  [31:0]  BUS_ADD,
        inout wire  [7:0]   BUS_DATA,
        input wire          BUS_RD,
        input wire          BUS_WR,

        input wire          FIFO_READY,
        output reg          FIFO_VALID,
        output reg [31:0]   FIFO_DATA,

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

    reg [31:0] FIFO_DATA_REG = 0;
    
    always @(posedge BUS_CLK)
        if(EN) begin
            if(FIFO_READY) begin
                FIFO_DATA <= FIFO_DATA_REG;
                FIFO_DATA_REG <= FIFO_DATA_REG + 1;
                FIFO_VALID <= 1;
            end
        end
        else begin
            FIFO_DATA_REG <= 0;
            FIFO_VALID <= 0;
        end

endmodule
