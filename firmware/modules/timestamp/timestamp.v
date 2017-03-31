/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module timestamp
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    parameter ABUSWIDTH = 16,
    parameter IDENTIFIER = 4'b0001
)(
    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    inout wire [7:0] BUS_DATA,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,
    
    input wire CLK,
    input wire DI,
    output wire [63:0] TIMESTAMP,
    input wire EXT_ENABLE,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA
    
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

timestamp_core 
#(
    .ABUSWIDTH(ABUSWIDTH),
    .IDENTIFIER(IDENTIFIER)
) i_timestamp_core 
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),
      
    .CLK(CLK),
    .DI(DI),
    .TIMESTAMP(TIMESTAMP),
    .EXT_ENABLE(EXT_ENABLE),

    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA)
);

endmodule
