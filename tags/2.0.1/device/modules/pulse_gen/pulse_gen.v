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

module pulse_gen
#(
    parameter BASEADDR = 16'h0000,
    parameter HIGHADDR = 16'h0000
)(
    input          BUS_CLK,
    input          BUS_RST,
    input   [15:0] BUS_ADD,
    inout   [7:0]  BUS_DATA,
    input          BUS_RD,
    input          BUS_WR,
    
    input  PULSE_CLK,
    input  EXT_START,
    output PULSE
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
    
    pulse_gen_core i_pulse_gen_core
    (
        .BUS_CLK(BUS_CLK),                     
        .BUS_RST(BUS_RST),                  
        .BUS_ADD(IP_ADD),                    
        .BUS_DATA_IN(IP_DATA_IN),                    
        .BUS_RD(IP_RD),                    
        .BUS_WR(IP_WR),                    
        .BUS_DATA_OUT(IP_DATA_OUT),
        
        .PULSE_CLK(PULSE_CLK),
        .EXT_START(EXT_START),
        .PULSE(PULSE)
    );

endmodule
