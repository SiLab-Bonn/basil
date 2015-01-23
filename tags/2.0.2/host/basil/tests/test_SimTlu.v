/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
`timescale 1ps / 1ps


`include "gpio/gpio.v"

`include "tlu/tlu_controller_core.v"
`include "tlu/tlu_controller_fsm.v"
`include "tlu/tlu_controller.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"

`include "utils/bus_to_ip.v"

`include "utils/cdc_syncfifo.v"
`include "utils/flag_domain_crossing.v"
`include "utils/generic_fifo.v"
`include "utils/3_stage_synchronizer.v"

module tb (
    input           BUS_CLK,
    input           BUS_RST,
    input   [31:0]  BUS_ADD,
    inout   [31:0]  BUS_DATA,
    input           BUS_RD,
    input           BUS_WR,
    output wire     BUS_BYTE_ACCESS
);   

    localparam GPIO_BASEADDR = 16'h0000;
    localparam GPIO_HIGHADDR = 16'h000f;
    
    localparam TLU_BASEADDR = 16'h8200;
    localparam TLU_HIGHADDR = 16'h8300-1;

    localparam FIFO_BASEADDR = 32'h8100;
    localparam FIFO_HIGHADDR = 32'h8200-1;
 
    localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
    localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;
 
    localparam ABUSWIDTH = 32;
    assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;
    
    wire TLU_CMD_EXT_START_FLAG, CMD_EXT_START_ENABLE;
    
    gpio 
    #( 
        .BASEADDR(GPIO_BASEADDR), 
        .HIGHADDR(GPIO_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .IO_WIDTH(8),
        .IO_DIRECTION(8'hff)
    ) i_gpio
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO()
    );
    
    assign TLU_CMD_EXT_START_FLAG = 0;
    assign CMD_EXT_START_ENABLE = 0;
    
    wire TLU_FIFO_READ;
    wire TLU_FIFO_EMPTY;
    wire [31:0] TLU_FIFO_DATA;
    wire FIFO_FULL;
    
    wire RJ45_TRIGGER, LEMO_TRIGGER, RJ45_RESET, LEMO_RESET, RJ45_ENABLED, TLU_BUSY, TLU_CLOCK;
    
    tlu_controller #(
        .BASEADDR(TLU_BASEADDR),
        .HIGHADDR(TLU_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .DIVISOR(8)
    ) i_tlu_controller (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        
        .CMD_CLK(BUS_CLK),
        
        .FIFO_READ(TLU_FIFO_READ),
        .FIFO_EMPTY(TLU_FIFO_EMPTY),
        .FIFO_DATA(TLU_FIFO_DATA),
        
        .FIFO_PREEMPT_REQ(),
        
        .RJ45_TRIGGER(RJ45_TRIGGER),
        .LEMO_TRIGGER(LEMO_TRIGGER),
        .RJ45_RESET(RJ45_RESET),
        .LEMO_RESET(LEMO_RESET),
        .RJ45_ENABLED(RJ45_ENABLED),
        .TLU_BUSY(TLU_BUSY),
        .TLU_CLOCK(TLU_CLOCK),
        
        .EXT_VETO(FIFO_FULL),
        
        .CMD_READY(1'b1),
        .CMD_EXT_START_FLAG(TLU_CMD_EXT_START_FLAG),
        .CMD_EXT_START_ENABLE(CMD_EXT_START_ENABLE),
        
        .TIMESTAMP()
    );
    
    assign RJ45_TRIGGER = 1'b0;
    assign LEMO_TRIGGER = 1'b0;
    assign RJ45_RESET = 1'b0;
    assign LEMO_RESET = 1'b0;
    assign RJ45_ENABLED = 1'b0;
    

    wire FIFO_READ, FIFO_EMPTY;
    wire [31:0] FIFO_DATA;
    assign FIFO_DATA = TLU_FIFO_DATA;
    assign FIFO_EMPTY = TLU_FIFO_EMPTY;
    assign TLU_FIFO_READ = FIFO_READ;
    
    bram_fifo 
    #(
        .BASEADDR(FIFO_BASEADDR),
        .HIGHADDR(FIFO_HIGHADDR),
        .BASEADDR_DATA(FIFO_BASEADDR_DATA),
        .HIGHADDR_DATA(FIFO_HIGHADDR_DATA),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_out_fifo (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

        .FIFO_READ_NEXT_OUT(FIFO_READ),
        .FIFO_EMPTY_IN(FIFO_EMPTY),
        .FIFO_DATA(FIFO_DATA),

        .FIFO_NOT_EMPTY(),
        .FIFO_FULL(FIFO_FULL),
        .FIFO_NEAR_FULL(),
        .FIFO_READ_ERROR()
    );


    initial begin
        $dumpfile("tlu.vcd");
        $dumpvars(0);
    end 
    
endmodule
