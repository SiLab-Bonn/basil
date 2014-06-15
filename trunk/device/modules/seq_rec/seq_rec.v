/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University 
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev:: 34                    $:
 *  $Author:: themperek          $: 
 *  $Date:: 2013-09-12 12:07:54 #$:
 */
 
module scope
#(
    parameter BASEADDR = 0,
    parameter HIGHADDR = 0,
    parameter ABUSWIDTH = 16,
    
    parameter MEM_BYTES = 8*1024,
    parameter IN_BITS = 8
)(
    input           BUS_CLK,
    input           BUS_RST,
    input   [ABUSWIDTH-1:0]  BUS_ADD,
    inout   [7:0]   BUS_DATA,
    input           BUS_RD,
    input           BUS_WR,

    input                SEQ_CLK,
    input [IN_BITS-1:0]  SEQ_IN,
    input TRIGGER
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

scope_core 
#(
    .MEM_BYTES(MEM_BYTES),
    .IN_BITS(IN_BITS),
    .ABUSWIDTH(ABUSWIDTH)
) i_scope_core 
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),  

    .SEQ_CLK(SEQ_CLK),
    .SEQ_IN(SEQ_IN),
    .TRIGGER(TRIGGER)
); 

endmodule  