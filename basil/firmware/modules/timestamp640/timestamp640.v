/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module timestamp640
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    parameter ABUSWIDTH = 16,
    parameter IDENTIFIER = 4'b0001,
    parameter CLKDV = 4
)(
    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    inout wire [7:0] BUS_DATA,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,
    
    input wire CLK320,
    input wire CLK160,
    input wire CLK40,
    input wire DI,
    input wire [63:0] EXT_TIMESTAMP,
    output wire [63:0] TIMESTAMP_OUT,
    input wire EXT_ENABLE,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,
    
    input wire FIFO_READ_TRAILING,
    output wire FIFO_EMPTY_TRAILING,
    output wire [31:0] FIFO_DATA_TRAILING
 
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

timestamp640_core 
#(
    .ABUSWIDTH(ABUSWIDTH),
    .IDENTIFIER(IDENTIFIER),
    .CLKDV(4)
) i_timestamp640_core 
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),
      
    .CLK320(CLK320),
    .CLK160(CLK160),
    .CLK40(CLK40),
    .DI(DI),
    .TIMESTAMP_OUT(TIMESTAMP_OUT),
    .EXT_TIMESTAMP(EXT_TIMESTAMP),
    .EXT_ENABLE(EXT_ENABLE),

    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),
    
    .FIFO_READ_TRAILING(FIFO_READ_TRAILING),
    .FIFO_EMPTY_TRAILING(FIFO_EMPTY_TRAILING),
    .FIFO_DATA_TRAILING(FIFO_DATA_TRAILING)
);

endmodule
