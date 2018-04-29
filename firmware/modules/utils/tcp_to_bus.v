/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps
`default_nettype none

module tcp_to_bus (
    input wire           BUS_RST,
    input wire           BUS_CLK,

    // SiTCP TCP RX
    output reg  [15:0]   TCP_RX_WC, // Rx FIFO write count[15:0] (Unused bits should be set 1)
    input wire           TCP_RX_WR, // Write enable
    input wire  [7:0]    TCP_RX_DATA, // Write data[7:0]
    //input wire           TCP_TX_FULL, // Almost full flag
    //output wire          TCP_TX_WR, // Write enable
    //output reg           TCP_TX_DATA, // Write data[7:0]

    // SiTCP RBCP (UDP)
    input wire           RBCP_ACT,
    input wire  [31:0]   RBCP_ADDR,
    input wire  [7:0]    RBCP_WD,
    input wire           RBCP_WE,
    input wire           RBCP_RE,
    output reg           RBCP_ACK,
    output wire [7:0]    RBCP_RD,

    // BUS
    output wire          BUS_WR,
    output wire          BUS_RD,
    output wire [31:0]   BUS_ADD,
    inout wire  [7:0]    BUS_DATA,

    output reg           INVALID
);


// TCP

wire TCP_RESET;
reg [15:0] LENGTH;
reg [15:0] BYTE_CNT;
reg [31:0] TCP_TO_BUS_ADD;
reg [15:0] RX_DATA_255_CNT;
wire TCP_TO_BUS_WR;

always@(posedge BUS_CLK)
    if(BUS_RST) begin
        TCP_RX_WC <= 0;
    end else if(TCP_RX_WR) begin
        TCP_RX_WC <= TCP_RX_WC + 1;
    end else begin
        TCP_RX_WC <= 0;
    end

always@(posedge BUS_CLK)
    if(BUS_RST) begin
        BYTE_CNT <= 0;
    end else if(INVALID || TCP_RESET) begin
        BYTE_CNT <= 0;
    end else if((BYTE_CNT >= 5) && ((BYTE_CNT - 5) == LENGTH)) begin
        BYTE_CNT <= 0;
    end else if(TCP_RX_WR) begin
        BYTE_CNT <= BYTE_CNT + 1;
    end else begin
        BYTE_CNT <= BYTE_CNT;
    end

// invalid signal will prevent from writing to BUS
// invalid signal will be reset when TCP write request is de-asserted
always@(posedge BUS_CLK)
    if (BUS_RST)
        INVALID <= 1'b0;
    else if (TCP_RESET)
        INVALID <= 1'b0;
    // check for correct length, substract header size 6
    // check for correct max. address
    else if (({TCP_RX_DATA, LENGTH[7:0]} > 65529 && BYTE_CNT == 1) || ((LENGTH + {TCP_RX_DATA, TCP_TO_BUS_ADD[23:0]} > 33'h1_0000_0000) && BYTE_CNT == 5))
        INVALID <= 1'b1;
    else
        INVALID <= INVALID;

always@(posedge BUS_CLK)
    if(BUS_RST) begin
        RX_DATA_255_CNT <= 0;
    end else if(TCP_RX_WR && ~&TCP_RX_DATA) begin // TCP data is not 255
        RX_DATA_255_CNT <= 0;
    end else if(TCP_RX_WR && &TCP_RX_DATA && ~&RX_DATA_255_CNT) begin // TCP data is 255
        RX_DATA_255_CNT <= RX_DATA_255_CNT + 1;
    end else begin
        RX_DATA_255_CNT <= RX_DATA_255_CNT;
    end

assign TCP_RESET = (&TCP_RX_DATA && RX_DATA_255_CNT == 16'hff_fe && TCP_RX_WR) || ((&TCP_RX_DATA && &RX_DATA_255_CNT && TCP_RX_WR));

always@(posedge BUS_CLK)
    if(BUS_RST) begin
        LENGTH <= 0;
    end else if(TCP_RX_WR && BYTE_CNT == 0) begin
        LENGTH[7:0] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && BYTE_CNT == 1) begin
        LENGTH[15:8] <= TCP_RX_DATA;
    end else begin
        LENGTH <= LENGTH;
    end

assign TCP_TO_BUS_WR = (TCP_RX_WR && BYTE_CNT > 5 && !INVALID) ? 1'b1 : 1'b0;

always@(posedge BUS_CLK)
    if(BUS_RST) begin
        TCP_TO_BUS_ADD <= 0;
    end else if(TCP_RX_WR && BYTE_CNT == 2) begin
        TCP_TO_BUS_ADD[7:0] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && BYTE_CNT == 3) begin
        TCP_TO_BUS_ADD[15:8] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && BYTE_CNT == 4) begin
        TCP_TO_BUS_ADD[23:16] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && BYTE_CNT == 5) begin
        TCP_TO_BUS_ADD[31:24] <= TCP_RX_DATA;
    end else if(TCP_RX_WR && BYTE_CNT > 5) begin
        TCP_TO_BUS_ADD <= TCP_TO_BUS_ADD + 1;
    end else begin
        TCP_TO_BUS_ADD <= TCP_TO_BUS_ADD;
    end


// RBCP
wire RBCP_TO_BUS_WR;

always@(posedge BUS_CLK) begin
    if(BUS_RST)
        RBCP_ACK <= 0;
    else begin
        if (RBCP_ACK == 1)
            RBCP_ACK <= 0;
        else
            RBCP_ACK <= (RBCP_WE | RBCP_RE) & ~TCP_TO_BUS_WR;
    end
end

assign RBCP_TO_BUS_WR = RBCP_WE & RBCP_ACT;
assign RBCP_RD[7:0] = BUS_WR ? 8'bz : BUS_DATA;


// BUS
assign BUS_WR = TCP_TO_BUS_WR | RBCP_TO_BUS_WR;
assign BUS_RD = RBCP_RE & RBCP_ACT & ~BUS_WR;
assign BUS_ADD = (TCP_TO_BUS_WR) ? TCP_TO_BUS_ADD : RBCP_ADDR;
assign BUS_DATA = (BUS_WR) ? ((TCP_TO_BUS_WR) ? TCP_RX_DATA : RBCP_WD) : 8'bz;

endmodule
