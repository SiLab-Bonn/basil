/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
`timescale 1ps / 1ps

`include "utils/bus_to_ip.v"

`include "seq_gen/seq_gen.v"
`include "seq_gen/seq_gen_core.v"

`include "m26_rx/m26_rx.v"
`include "m26_rx/m26_rx_core.v"
`include "m26_rx/m26_rx_ch.v"

`include "utils/cdc_syncfifo.v"
`include "utils/generic_fifo.v"
`include "utils/cdc_pulse_sync.v"
`include "utils/cdc_reset_sync.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"
`include "utils/IDDR_sim.v"

module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
    inout wire  [31:0]  BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS
);   

    localparam SEQ_GEN_BASEADDR = 32'h1000;
    localparam SEQ_GEN_HIGHADDR = 32'h3000-1; 
    
    localparam M26_RX_BASEADDR = 32'h3000;
    localparam M26_RX_HIGHADDR = 32'h5000 - 1;

    localparam FIFO_BASEADDR = 32'h8000;
    localparam FIFO_HIGHADDR = 32'h9000 - 1;
 
    localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
    localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;
 
    localparam ABUSWIDTH = 32;
    assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

    wire [7:0] SEQ_OUT;
    seq_gen 
    #( 
        .BASEADDR(SEQ_GEN_BASEADDR), 
        .HIGHADDR(SEQ_GEN_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .MEM_BYTES(8*1024), 
        .OUT_BITS(8) 
    ) i_seq_gen
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
    
        .SEQ_EXT_START(1'b0),
        .SEQ_CLK(BUS_CLK),
        .SEQ_OUT(SEQ_OUT)
    );
    
    wire FIFO_READ_RX;
    wire FIFO_EMPTY_RX;
    wire [31:0] FIFO_DATA_RX;
    
    //safe clock domain crossing synchronization
    reg [31:0] TIMESTAMP, timestamp_gray;
    always@(posedge BUS_CLK)
        TIMESTAMP <= 32'haa55bb44;

    always@(posedge BUS_CLK) 
        timestamp_gray <=  (TIMESTAMP>>1) ^ TIMESTAMP;

    reg [31:0] timestamp_cdc0, timestamp_cdc1, timestamp_m26;
    always@(posedge BUS_CLK) begin
        timestamp_cdc0 <= timestamp_gray;
        timestamp_cdc1 <= timestamp_cdc0;
    end

    integer gbi;
    always@(*) begin
        timestamp_m26[31] = timestamp_cdc1[31];
        for(gbi  =30; gbi >= 0; gbi = gbi -1) begin
            timestamp_m26[gbi] = timestamp_cdc1[gbi] ^ timestamp_m26[gbi+1];
        end
    end     
        
    m26_rx 
    #(
        .BASEADDR(M26_RX_BASEADDR), 
        .HIGHADDR(M26_RX_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_m26_rx
    (
        .CLK_RX(BUS_CLK),
        .MKD_RX(SEQ_OUT[0]),
        .DATA_RX(SEQ_OUT[2:1]),

        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR), 

        .FIFO_READ(FIFO_READ_RX),
        .FIFO_EMPTY(FIFO_EMPTY_RX),
        .FIFO_DATA(FIFO_DATA_RX),
        
        .TIMESTAMP(timestamp_m26),
        
        .LOST_ERROR()
    ); 
    
    wire FIFO_READ, FIFO_EMPTY;
    wire [31:0] FIFO_DATA;
    assign FIFO_DATA = FIFO_DATA_RX;
    assign FIFO_EMPTY = FIFO_EMPTY_RX;
    assign FIFO_READ_RX = FIFO_READ;
    
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
        .FIFO_FULL(),
        .FIFO_NEAR_FULL(),
        .FIFO_READ_ERROR()
    );
    
    initial begin
        $dumpfile("m26.vcd");
        $dumpvars(0);
    end 
    
endmodule
