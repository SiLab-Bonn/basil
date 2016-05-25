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

`include "utils/cdc_pulse_sync.v"

module tlu_model ( 
    input wire SYS_CLK, SYS_RST, TLU_CLOCK, TLU_BUSY, ENABLE,
    output wire TLU_TRIGGER, TLU_RESET
);

reg [14:0] TRIG_ID;
reg TRIG;
wire VETO;
integer seed;

initial
    seed = 0;


always@(posedge SYS_CLK) begin
    if(SYS_RST)
        TRIG <= 0;
    else if($random(seed) % 100 == 10 && !VETO && ENABLE)
        TRIG <= 1;
    else
        TRIG <= 0;
end

always@(posedge SYS_CLK) begin
    if(SYS_RST)
        TRIG_ID <= 0;
    else if(TRIG)
        TRIG_ID <= TRIG_ID + 1;
end

localparam WAIT_STATE = 0, TRIG_STATE = 1, READ_ID_STATE = 2;

reg [1:0] state, state_next;
always@(posedge SYS_CLK)
    if(SYS_RST)
        state <= WAIT_STATE;
    else
        state <= state_next;

always@(*) begin
    state_next = state;
    
    case(state)
        WAIT_STATE: 
            if(TRIG)
                state_next = TRIG_STATE;
        TRIG_STATE:
            if(TLU_BUSY)
                state_next = READ_ID_STATE;
        READ_ID_STATE:
            if(!TLU_BUSY)
                state_next = WAIT_STATE;
        default : state_next = WAIT_STATE;
    endcase
end

assign VETO = (state != WAIT_STATE) || (state == WAIT_STATE && TLU_CLOCK == 1'b1);

reg [15:0] TRIG_ID_SR;
initial TRIG_ID_SR = 0;
always@(posedge TLU_CLOCK or posedge TRIG)
    if(TRIG)
        TRIG_ID_SR <= {TRIG_ID, 1'b0};
    else
        TRIG_ID_SR <= {1'b0, TRIG_ID_SR[15:1]};
        
assign TLU_TRIGGER = (state == TRIG_STATE) | (TRIG_ID_SR[0] & TLU_BUSY);

assign TLU_RESET = 0;

endmodule


module tb (
    input wire           BUS_CLK,
    input wire           BUS_RST,
    input wire   [31:0]  BUS_ADD,
    inout wire   [31:0]  BUS_DATA,
    input wire           BUS_RD,
    input wire           BUS_WR,
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
    wire TLU_TRIGGER, TLU_RESET, TLU_BUSY, TLU_CLOCK;
    wire TRIGGER_ENABLE, TRIGGER, TRIGGER_VETO;
    wire [6:0] NOT_CONNECTED;
    wire [7:0] GPIO_IO;
    wire SHORT_TRIGGER;
    reg TRIGGER_FF;
    assign NOT_CONNECTED = GPIO_IO[7:1];
    assign TRIGGER_ENABLE = GPIO_IO[0];
    assign TRIGGER = GPIO_IO[1];
    assign TRIGGER_VETO = GPIO_IO[2];
    always @(posedge BUS_CLK) begin
        TRIGGER_FF <= TRIGGER;
    end
    assign SHORT_TRIGGER = TRIGGER & ~TRIGGER_FF;
    
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
        .IO(GPIO_IO)
    );
    
    assign TLU_CMD_EXT_START_FLAG = 0;
    assign CMD_EXT_START_ENABLE = 1'b1;
    
    wire TLU_FIFO_READ;
    wire TLU_FIFO_EMPTY;
    wire [31:0] TLU_FIFO_DATA;
    wire FIFO_FULL;
    wire ACKNOWLEDGE;
    
    //assign TRIGGER_ENABLE = 1'b1;
    
    tlu_model itlu_model ( 
        .SYS_CLK(BUS_CLK), .SYS_RST(BUS_RST), .ENABLE(TRIGGER_ENABLE), .TLU_CLOCK(TLU_CLOCK), .TLU_BUSY(TLU_BUSY), 
        .TLU_TRIGGER(TLU_TRIGGER), .TLU_RESET(TLU_RESET)
    );
    
    tlu_controller #(
        .BASEADDR(TLU_BASEADDR),
        .HIGHADDR(TLU_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .DIVISOR(16),
        .TLU_TRIGGER_MAX_CLOCK_CYCLES(16)
    ) i_tlu_controller (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        
        .TRIGGER_CLK(BUS_CLK),
        
        .FIFO_READ(TLU_FIFO_READ),
        .FIFO_EMPTY(TLU_FIFO_EMPTY),
        .FIFO_DATA(TLU_FIFO_DATA),
        
        .FIFO_PREEMPT_REQ(),
        
        .TRIGGER({5'b0, SHORT_TRIGGER, TRIGGER, TLU_TRIGGER}),
        .TRIGGER_VETO({6'b0, TRIGGER_VETO, 1'b1}),
        
        .TLU_TRIGGER(TLU_TRIGGER),
        .TLU_RESET(TLU_RESET),
        .TLU_BUSY(TLU_BUSY),
        .TLU_CLOCK(TLU_CLOCK),
        
        .EXT_TRIGGER_ENABLE(TRIGGER_ENABLE),
        .TRIGGER_ACKNOWLEDGE(ACKNOWLEDGE),
        .TRIGGER_ACCEPTED_FLAG(ACKNOWLEDGE),

        .TIMESTAMP()
    );
    
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
