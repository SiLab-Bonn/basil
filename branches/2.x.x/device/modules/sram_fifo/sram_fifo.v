/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University 
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $: 
 *  $Date::                      $:
 */
 
module sram_fifo
#(
    parameter   BASEADDR = 16'h0000,
    parameter   HIGHADDR = 16'h0000,    
    parameter   DEPTH = 21'h10_0000,
    parameter   FIFO_ALMOST_FULL_THRESHOLD = 95, // in percent
    parameter   FIFO_ALMOST_EMPTY_THRESHOLD = 5 // in percent
) (
//    input                   BUS_CLK270,
    
    input                   BUS_CLK,
    input                   BUS_RST,
    input  [15:0]           BUS_ADD,
    inout  [7:0]            BUS_DATA,
    input                   BUS_RD,
    input                   BUS_WR,
    
    output  [19:0]          SRAM_A,
    inout  [15:0]           SRAM_IO,
    output                  SRAM_BHE_B,
    output                  SRAM_BLE_B,
    output                  SRAM_CE1_B,
    output                  SRAM_OE_B,
    output                  SRAM_WE_B,
    
    input                   USB_READ,
    output  [7:0]           USB_DATA,
    
    output                  FIFO_READ_NEXT_OUT,
    input                   FIFO_EMPTY_IN,
    input  [31:0]           FIFO_DATA,
    
    output                  FIFO_NOT_EMPTY,
    output                  FIFO_FULL,
    output                  FIFO_NEAR_FULL,
    output                  FIFO_READ_ERROR
);

wire IP_RD, IP_WR;
wire [15:0] IP_ADD;
wire [7:0] IP_DATA_IN;
wire [7:0] IP_DATA_OUT;

bus_to_ip #( .BASEADDR(BASEADDR), .HIGHADDR(HIGHADDR) ) i_bus_to_ip
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


sram_fifo_core 
#(
    .DEPTH(DEPTH),
    .FIFO_ALMOST_FULL_THRESHOLD(FIFO_ALMOST_FULL_THRESHOLD),
    .FIFO_ALMOST_EMPTY_THRESHOLD(FIFO_ALMOST_EMPTY_THRESHOLD)
) i_sram_fifo 
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),  
 
//    .BUS_CLK270(BUS_CLK270),
    
    .SRAM_A(SRAM_A),
    .SRAM_IO(SRAM_IO),
    .SRAM_BHE_B(SRAM_BHE_B),
    .SRAM_BLE_B(SRAM_BLE_B),
    .SRAM_CE1_B(SRAM_CE1_B),
    .SRAM_OE_B(SRAM_OE_B),
    .SRAM_WE_B(SRAM_WE_B),
        
     .USB_READ(USB_READ),
     .USB_DATA(USB_DATA),
        
     .FIFO_READ_NEXT_OUT(FIFO_READ_NEXT_OUT),
     .FIFO_EMPTY_IN(FIFO_EMPTY_IN),
     .FIFO_DATA(FIFO_DATA),
    
     .FIFO_NOT_EMPTY(FIFO_NOT_EMPTY),
     .FIFO_FULL(FIFO_FULL),
     .FIFO_NEAR_FULL(FIFO_NEAR_FULL),
     .FIFO_READ_ERROR(FIFO_READ_ERROR)        
 );

endmodule
