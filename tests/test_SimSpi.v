/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University 
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps


`include "utils/bus_to_ip.v"
 
`include "gpio/gpio.v"

`include "spi/spi.v"
`include "spi/spi_core.v"
`include "spi/blk_mem_gen_8_to_1_2k.v"

`include "pulse_gen/pulse_gen.v"
`include "pulse_gen/pulse_gen_core.v"
   
`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"

`include "fast_spi_rx/fast_spi_rx.v"
`include "fast_spi_rx/fast_spi_rx_core.v"

`include "utils/cdc_syncfifo.v"
`include "utils/generic_fifo.v"
`include "utils/cdc_pulse_sync.v"
`include "utils/CG_MOD_pos.v"
`include "utils/clock_divider.v"

`include "utils/RAMB16_S1_S9_sim.v"

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
    
    localparam SPI_BASEADDR = 32'h1000; //0x1000
    localparam SPI_HIGHADDR = 32'h2000-1;   //0x300f
    
    localparam FAST_SR_AQ_BASEADDR = 32'h2000;
    localparam FAST_SR_AQ_HIGHADDR = 32'h3000-1;
    
    localparam PULSE_BASEADDR = 32'h3000;
    localparam PULSE_HIGHADDR = PULSE_BASEADDR + 15;
    
    localparam FIFO_BASEADDR = 32'h8000;
    localparam FIFO_HIGHADDR = 32'h9000-1;
    
    localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
    localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;
    
    localparam ABUSWIDTH = 32;
    assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;
    
    // MODULES //
    gpio
    #(
        .BASEADDR(GPIO_BASEADDR),
        .HIGHADDR(GPIO_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .IO_WIDTH(8),
        .IO_DIRECTION(8'hff)
    ) i_gpio
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO()
    );
    
    wire SPI_CLK;
    wire EX_START_PULSE;
    pulse_gen
    #(
        .BASEADDR(PULSE_BASEADDR),
        .HIGHADDR(PULSE_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_pulse_gen
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
    
        .PULSE_CLK(SPI_CLK),
        .EXT_START(1'b0),
        .PULSE(EX_START_PULSE)
    );
    
    clock_divider #(
    .DIVISOR(4) 
    ) i_clock_divisor_spi (
        .CLK(BUS_CLK),
        .RESET(1'b0),
        .CE(),
        .CLOCK(SPI_CLK)
    ); 
    
    wire SCLK, SDI, SDO, SEN, SLD;
    
    spi
    #(
        .BASEADDR(SPI_BASEADDR),
        .HIGHADDR(SPI_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .MEM_BYTES(16) 
    )  i_spi
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        
        .SPI_CLK(SPI_CLK),
        .EXT_START(EX_START_PULSE),
        
        .SCLK(SCLK),
        .SDI(SDI),
        .SDO(SDO),
        .SEN(SEN),
        .SLD(SLD)
    );
    
    assign SDO = SDI;
    
    wire FIFO_READ_SPI_RX;
    wire FIFO_EMPTY_SPI_RX;
    wire [31:0] FIFO_DATA_SPI_RX;
    
    fast_spi_rx
    #(
        .BASEADDR(FAST_SR_AQ_BASEADDR),
        .HIGHADDR(FAST_SR_AQ_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_pixel_sr_fast_rx
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        
        .SCLK(~SPI_CLK),
        .SDI(SDI),
        .SEN(SEN),
        
        .FIFO_READ(FIFO_READ_SPI_RX),
        .FIFO_EMPTY(FIFO_EMPTY_SPI_RX),
        .FIFO_DATA(FIFO_DATA_SPI_RX)

    );
    
    wire FIFO_READ, FIFO_EMPTY;
    wire [31:0] FIFO_DATA;
    assign FIFO_DATA = FIFO_DATA_SPI_RX;
    assign FIFO_EMPTY = FIFO_EMPTY_SPI_RX;
    assign FIFO_READ_SPI_RX = FIFO_READ;
    
    bram_fifo
    #(
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
        $dumpfile("spi.vcd");
        $dumpvars(0);
    end
    
endmodule
