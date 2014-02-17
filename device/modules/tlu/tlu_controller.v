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
`timescale 1 ps / 1ps
`default_nettype none
 
 module tlu_controller
#(
    parameter       BASEADDR = 16'h0000,
    parameter       HIGHADDR = 16'h0000, 
    parameter       DIVISOR = 12
)
(
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [15:0]  BUS_ADD,
    inout wire  [7:0]   BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    
    input wire                  CMD_CLK,
    
    input wire                  FIFO_READ,
    output wire                 FIFO_EMPTY,
    output wire     [31:0]      FIFO_DATA,
    
    output wire                 FIFO_PREEMPT_REQ,
    
    input wire                  RJ45_TRIGGER,
    input wire                  LEMO_TRIGGER,
    input wire                  RJ45_RESET,
    input wire                  LEMO_RESET,
    output wire                 RJ45_ENABLED,
    output wire                 TLU_BUSY,
    output wire                 TLU_CLOCK,
    
    input wire                  EXT_VETO,
    
    input wire                  CMD_READY,
    output wire                 CMD_EXT_START_FLAG,
    input wire                  CMD_EXT_START_ENABLE,
    
    input wire                  FIFO_NEAR_FULL
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


tlu_controller_core 
#(
    .DIVISOR(DIVISOR)
) i_tlu_controller
(
    .BUS_CLK(BUS_CLK),                     
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(IP_ADD),                    
    .BUS_DATA_IN(IP_DATA_IN),                    
    .BUS_RD(IP_RD),                    
    .BUS_WR(IP_WR),                    
    .BUS_DATA_OUT(IP_DATA_OUT),  
    
    .CMD_CLK(CMD_CLK),
    
    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),
    
    .FIFO_PREEMPT_REQ(FIFO_PREEMPT_REQ),
    
    .RJ45_TRIGGER(RJ45_TRIGGER),
    .LEMO_TRIGGER(LEMO_TRIGGER),
    .RJ45_RESET(RJ45_RESET),
    .LEMO_RESET(LEMO_RESET),
    .RJ45_ENABLED(RJ45_ENABLED),
    .TLU_BUSY(TLU_BUSY),
    .TLU_CLOCK(TLU_CLOCK),
    
    .EXT_VETO(EXT_VETO),
    
    .CMD_READY(CMD_READY),
    .CMD_EXT_START_FLAG(CMD_EXT_START_FLAG),
    .CMD_EXT_START_ENABLE(CMD_EXT_START_ENABLE),
    
    .FIFO_NEAR_FULL(FIFO_NEAR_FULL)
    
); 

endmodule
