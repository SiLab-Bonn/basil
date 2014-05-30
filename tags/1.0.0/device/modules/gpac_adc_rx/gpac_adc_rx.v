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
 
module gpac_adc_rx
#(
    parameter   BASEADDR = 16'h0000,
    parameter   HIGHADDR = 16'h0000, 
    parameter [1:0] ADC_ID = 0,
    parameter [0:0] HEADER_ID = 0
)
(
    input ADC_CLK,
    input ADC_DCO,
    input ADC_FCO,
    input ADC_IN,

    input ADC_SYNC,
    input ADC_TRIGGER,

    input FIFO_READ,
    output FIFO_EMPTY,
    output [31:0] FIFO_DATA,

    input           BUS_CLK,
    input           BUS_RST,
    input   [15:0]  BUS_ADD,
    inout   [7:0]   BUS_DATA,
    input           BUS_RD,
    input           BUS_WR,

    output LOST_ERROR
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

gpac_adc_rx_core 
#(
    .ADC_ID(ADC_ID),
    .HEADER_ID(HEADER_ID)
) i_gpac_adc_rx_core 
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),  

    .ADC_CLK(ADC_CLK),
    .ADC_DCO(ADC_DCO),
    .ADC_FCO(ADC_FCO),
    .ADC_IN(ADC_IN),

    .ADC_SYNC(ADC_SYNC),
    .ADC_TRIGGER(ADC_TRIGGER),

    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),
    .LOST_ERROR(LOST_ERROR)
); 


endmodule
