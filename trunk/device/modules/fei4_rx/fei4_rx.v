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
`timescale 1ps/1ps
`default_nettype none


module fei4_rx
#(
    parameter   BASEADDR = 16'h0000,
    parameter   HIGHADDR = 16'h0000, 
    parameter   DSIZE = 10,
    parameter   DATA_IDENTIFIER = 0
)
(
    input wire RX_CLK,
    input wire RX_CLK90,
    input wire DATA_CLK,
    input wire RX_CLK_LOCKED,
    input wire RX_DATA,
    output wire RX_READY,
    output wire RX_8B10B_DECODER_ERR,
    output wire RX_FIFO_OVERFLOW_ERR,
     
    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,
    
    output wire RX_FIFO_FULL,

    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [15:0]  BUS_ADD,
    inout wire  [7:0]   BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR
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


fei4_rx_core
#(
    .DSIZE(DSIZE),
    .DATA_IDENTIFIER(DATA_IDENTIFIER)
) i_fei4_rx_core 
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),  
    
    .RX_CLK(RX_CLK),
    .RX_CLK90(RX_CLK90),
    .DATA_CLK(DATA_CLK),
    .RX_CLK_LOCKED(RX_CLK_LOCKED),
    .RX_DATA(RX_DATA),
    .RX_READY(RX_READY),
    .RX_8B10B_DECODER_ERR(RX_8B10B_DECODER_ERR),
    .RX_FIFO_OVERFLOW_ERR(RX_FIFO_OVERFLOW_ERR),
     
    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),
    
    .RX_FIFO_FULL(RX_FIFO_FULL)
); 

endmodule
