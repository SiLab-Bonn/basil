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
 
module fast_spi_rx
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    
    parameter IDENTYFIER = 4'b0001
)(
    input BUS_CLK,
    input [15:0] BUS_ADD,
    inout [7:0] BUS_DATA,
    input BUS_RST,
    input BUS_WR,
    input BUS_RD,
    
    input SCLK,
    input SDI,
    input SEN,

    input FIFO_READ,
    output FIFO_EMPTY,
    output [31:0] FIFO_DATA
    
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
    
    fast_spi_rx_core 
    #(
        .IDENTYFIER(IDENTYFIER)
    ) i_fast_spi_rx_core 
    (
        .BUS_CLK(BUS_CLK),                     
        .BUS_RST(BUS_RST),                  
        .BUS_ADD(IP_ADD),                    
        .BUS_DATA_IN(IP_DATA_IN),                    
        .BUS_RD(IP_RD),                    
        .BUS_WR(IP_WR),                    
        .BUS_DATA_OUT(IP_DATA_OUT),
          
        .SCLK(SCLK),
        .SDI(SDI),
        .SEN(SEN),
    
        .FIFO_READ(FIFO_READ),
        .FIFO_EMPTY(FIFO_EMPTY),
        .FIFO_DATA(FIFO_DATA)
    );

endmodule
