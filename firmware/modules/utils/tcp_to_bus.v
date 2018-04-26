/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps
`default_nettype none

module tcp_to_bus (
    input wire BUS_RST,
    input wire BUS_CLK,

    // SiTCP TCP RX
    output reg [15:0] TCP_RX_WC, // Rx FIFO write count[15:0] (Unused bits should be set 1)
    input wire        TCP_RX_WR, // Write enable
    input wire [7:0]  TCP_RX_DATA, // Write data[7:0]
    //input wire TCP_TX_FULL, // Almost full flag
    //output wire TCP_TX_WR, // Write enable
    //output reg TCP_TX_DATA, // Write data[7:0]

    // BUS
    output wire          BUS_WR,
    //output wire          BUS_RD,
    output reg  [31:0]   BUS_ADD,
    output wire [7:0]    BUS_DATA
);


always@(posedge BUS_CLK)
    if(BUS_RST) begin
        TCP_RX_WC <= 0;
    end else if(TCP_RX_WR) begin
        TCP_RX_WC <= TCP_RX_WC + 1;
    end else begin
        TCP_RX_WC <= 0;
    end

reg INVALID;
reg [15:0] LENGTH;
reg [15:0] byte_cnt;
always@(posedge BUS_CLK)
    if(BUS_RST) begin
        byte_cnt <= 0;
    end else if(INVALID && !TCP_RX_WR) begin
        byte_cnt <= 0;
    end else if((byte_cnt >= 5) && ((byte_cnt - 5) == LENGTH)) begin
        byte_cnt <= 0;
    end else if(TCP_RX_WR) begin
        byte_cnt <= byte_cnt + 1;
    end else begin
        byte_cnt <= byte_cnt;
    end

// invalid signal will prevent from writing to BUS
// invalid signal will be reset when TCP write request is de-asserted
always@(posedge BUS_CLK)
    if (BUS_RST)
        INVALID <= 1'b0;
    if (!TCP_RX_WR)
        INVALID <= 1'b0;
    // check for correct length, substract header size 6
    // check for correct max. address
    else if (({TCP_RX_DATA, LENGTH[7:0]} > 65529 && byte_cnt == 1) || ((LENGTH + {TCP_RX_DATA, BUS_ADD[23:0]} > 33'h1_0000_0000) && byte_cnt == 5))
        INVALID <= 1'b1;
    else
        INVALID <= INVALID;

always@(posedge BUS_CLK)
    if(BUS_RST) begin
        LENGTH <= 0;
    end else if(TCP_RX_WR && byte_cnt == 0) begin
        LENGTH[7:0] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && byte_cnt == 1) begin
        LENGTH[15:8] <= TCP_RX_DATA;
    end else begin
        LENGTH <= LENGTH;
    end

assign BUS_WR = (TCP_RX_WR && byte_cnt > 5 && !INVALID) ? 1'b1 : 1'b0;

  always@(posedge BUS_CLK)
    if(BUS_RST) begin
        BUS_ADD <= 0;
    end else if(TCP_RX_WR && byte_cnt == 2) begin
        BUS_ADD[7:0] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && byte_cnt == 3) begin
        BUS_ADD[15:8] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && byte_cnt == 4) begin
        BUS_ADD[23:16] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && byte_cnt == 5) begin
        BUS_ADD[31:24] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && byte_cnt > 5) begin
        BUS_ADD <= BUS_ADD + 1;
    end else begin
        BUS_ADD <= BUS_ADD;
    end

assign BUS_DATA = (BUS_WR) ? TCP_RX_DATA : 8'bz;

endmodule
