//-------------------------------------------------------------------------
//    Copyright (c) SILAB, Physics Institute of the University of Bonn
//
//    SVN revision information:    
//    $Author::            $:  Author of last commit
//    $Rev::               $:  Revision of last commit
//    $Date::              $:  Date of last commit
//  
//--------------------------------------------------------------------------------------

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
    input IP_DATA
);

wire CS;
assign CS = BUS_ADD >= BASEADDR && BUS_ADD <= HIGHADDR;

assign IP_ADD = CS ? BUS_ADD - BASEADDR : 0;
assign IP_RD = CS ? BUS_RD : 0;
assign IP_WR = CS ? BUS_WR: 0;
assign BUS_DATA = (CS && BUS_RD) ? IP_DATA : 8'bzzzz_zzzz;

endmodule
