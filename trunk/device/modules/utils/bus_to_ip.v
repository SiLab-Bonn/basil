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
    parameter BASEADDR = 0,
    parameter HIGHADDR = 0,
    parameter ABUSWIDTH = 16
)
(
    input BUS_RD,
    input BUS_WR,
    input [ABUSWIDTH-1:0] BUS_ADD,
    inout [7:0] BUS_DATA,
    
    output IP_RD,
    output IP_WR,
    output [ABUSWIDTH-1:0] IP_ADD,    
    output [7:0] IP_DATA_IN,
    input [7:0] IP_DATA_OUT
);

wire CS;
assign CS = (BUS_ADD >= BASEADDR && BUS_ADD <= HIGHADDR);

assign IP_ADD = CS ? BUS_ADD - BASEADDR : 0;
assign IP_RD = CS ? BUS_RD : 0;
assign IP_WR = CS ? BUS_WR: 0;
assign BUS_DATA = (CS && BUS_WR) ?  8'bzzzz_zzzz : IP_DATA_OUT;
assign IP_DATA_IN =  BUS_DATA;
	 
endmodule
