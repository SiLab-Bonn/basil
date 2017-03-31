/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University 
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps


`include "utils/bus_to_ip.v"
 
`include "gpio/gpio.v"

`include "pulse_gen/pulse_gen.v"
`include "pulse_gen/pulse_gen_core.v"
   
`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"

`include "timestamp/timestamp.v"
`include "timestamp/timestamp_core.v"

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
    
    localparam TIMESTAMP_BASEADDR = 32'h1000; //0x1000
    localparam TIMESTAMP_HIGHADDR = 32'h2000-1;   //0x300f
    
    
    localparam PULSE_BASEADDR = 32'h3000;
    localparam PULSE_HIGHADDR = PULSE_BASEADDR + 15;
    
    localparam FIFO_BASEADDR = 32'h8000;
    localparam FIFO_HIGHADDR = 32'h9000-1;
    
    localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
    localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;
    
    localparam ABUSWIDTH = 32;
    assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;
    
    // MODULES //

    wire [63:0] TIMESTAMP;
    gpio
    #(
        .BASEADDR(GPIO_BASEADDR),
        .HIGHADDR(GPIO_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .IO_WIDTH(64),
        .IO_DIRECTION(64'h0)
    ) i_gpio
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO(TIMESTAMP)
    );
    
    wire SPI_CLK;
    wire PULSE;
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
        .PULSE(PULSE)
    );
    
    clock_divider #(
    .DIVISOR(4) 
    ) i_clock_divisor_spi (
        .CLK(BUS_CLK),
        .RESET(1'b0),
        .CE(),
        .CLOCK(SPI_CLK)
    ); 
    

    wire FIFO_READ, FIFO_EMPTY;
    wire [31:0] FIFO_DATA;
    timestamp
    #(
        .BASEADDR(TIMESTAMP_BASEADDR),
        .HIGHADDR(TIMESTAMP_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .IDENTIFIER(4'b0101) 
    )  i_timestamp
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        
        .CLK(SPI_CLK),
        .DI(PULSE),
        .TIMESTAMP(TIMESTAMP),
        
        .FIFO_READ(FIFO_READ),
        .FIFO_EMPTY(FIFO_EMPTY),
        .FIFO_DATA(FIFO_DATA)
    );



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
        $dumpfile("timestamp.vcd");
        $dumpvars(0);
    end
    
endmodule
