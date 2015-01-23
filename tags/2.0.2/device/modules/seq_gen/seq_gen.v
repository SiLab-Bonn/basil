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
 
module seq_gen
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000,
    parameter ABUSWIDTH = 16,

    parameter MEM_BYTES = 16384,
    parameter OUT_BITS = 16
)(
    input           BUS_CLK,
    input           BUS_RST,
    input   [ABUSWIDTH-1:0]  BUS_ADD,
    inout   [7:0]   BUS_DATA,
    input           BUS_RD,
    input           BUS_WR,

    input SEQ_EXT_START,
    input SEQ_CLK,
    output [OUT_BITS-1:0] SEQ_OUT
);

wire IP_RD, IP_WR;
wire [ABUSWIDTH-1:0] IP_ADD;
wire [7:0] IP_DATA_IN;
wire [7:0] IP_DATA_OUT;

bus_to_ip #( .BASEADDR(BASEADDR), .HIGHADDR(HIGHADDR), .ABUSWIDTH(ABUSWIDTH)) i_bus_to_ip
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

seq_gen_core 
#(
    .ABUSWIDTH(ABUSWIDTH),
    .MEM_BYTES(MEM_BYTES),
    .OUT_BITS(OUT_BITS)
) i_seq_gen_core 
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),  

    .SEQ_EXT_START(SEQ_EXT_START),
    .SEQ_CLK(SEQ_CLK),
    .SEQ_OUT(SEQ_OUT)
); 

endmodule  