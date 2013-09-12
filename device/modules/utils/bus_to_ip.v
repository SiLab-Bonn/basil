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
 
 
module bus_to_ip
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000
)
(
    input BUS_RD,
    input BUS_WR,
    input [15:0] BUS_ADD,
    inout [7:0] BUS_DATA,
    
    output IP_RD,
    output IP_WR,
    output [15:0] IP_ADD,    
    output [7:0] IP_DATA_IN,
    input [7:0] IP_DATA_OUT
);

wire CS;
assign CS = (BUS_ADD >= BASEADDR && BUS_ADD <= HIGHADDR);

assign IP_ADD = CS ? BUS_ADD - BASEADDR : 0;
assign IP_RD = CS ? BUS_RD : 0;
assign IP_WR = CS ? BUS_WR: 0;
assign BUS_DATA = (CS && BUS_RD) ? IP_DATA_OUT : 8'bzzzz_zzzz;
assign IP_DATA_IN =  BUS_DATA;

endmodule
