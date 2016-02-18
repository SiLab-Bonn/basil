/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module tlu_controller
#(
    parameter       BASEADDR = 16'h0000,
    parameter       HIGHADDR = 16'h0000, 
    parameter       ABUSWIDTH = 16,
    parameter       DIVISOR = 8,
    parameter       TLU_TRIGGER_MAX_CLOCK_CYCLES = 17
)
(
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire  [ABUSWIDTH-1:0] BUS_ADD,
    inout wire      [7:0]       BUS_DATA,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    
    input wire                  TRIGGER_CLK, // clock of the TLU FSM, usually connect clock of command sequencer here
    
    input wire                  FIFO_READ,
    output wire                 FIFO_EMPTY,
    output wire     [31:0]      FIFO_DATA,
    
    output wire                 FIFO_PREEMPT_REQ,
    
    input wire      [7:0]       TRIGGER,
    input wire      [7:0]       TRIGGER_VETO,
    
    input wire                  EXT_TRIGGER_ENABLE,
    input wire                  TRIGGER_ACKNOWLEDGE,
    output wire                 TRIGGER_ACCEPTED_FLAG,
    
    input wire                  TLU_TRIGGER,
    input wire                  TLU_RESET,
    output wire                 TLU_BUSY,
    output wire                 TLU_CLOCK,
    
    output wire     [31:0]      TIMESTAMP
);

wire IP_RD, IP_WR;
wire [ABUSWIDTH-1:0] IP_ADD;
wire [7:0] IP_DATA_IN;
wire [7:0] IP_DATA_OUT;

bus_to_ip #(
    .BASEADDR(BASEADDR),
    .HIGHADDR(HIGHADDR) ,
    .ABUSWIDTH(ABUSWIDTH)
) i_bus_to_ip (
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


tlu_controller_core #(
    .DIVISOR(DIVISOR),
    .ABUSWIDTH(ABUSWIDTH),
    .TLU_TRIGGER_MAX_CLOCK_CYCLES(TLU_TRIGGER_MAX_CLOCK_CYCLES)
) i_tlu_controller_core (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),

    .TRIGGER_CLK(TRIGGER_CLK),

    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),

    .FIFO_PREEMPT_REQ(FIFO_PREEMPT_REQ),

    .TRIGGER(TRIGGER),
    .TRIGGER_VETO(TRIGGER_VETO),

    .EXT_TRIGGER_ENABLE(EXT_TRIGGER_ENABLE),
    .TRIGGER_ACKNOWLEDGE(TRIGGER_ACKNOWLEDGE),
    .TRIGGER_ACCEPTED_FLAG(TRIGGER_ACCEPTED_FLAG),
    
    .TLU_TRIGGER(TLU_TRIGGER),
    .TLU_RESET(TLU_RESET),
    .TLU_BUSY(TLU_BUSY),
    .TLU_CLOCK(TLU_CLOCK),

    .TIMESTAMP(TIMESTAMP)
);

endmodule
