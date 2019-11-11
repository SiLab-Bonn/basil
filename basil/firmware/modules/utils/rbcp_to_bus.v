/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module rbcp_to_bus (
    input wire           BUS_RST,
    input wire           BUS_CLK,

    input wire           RBCP_ACT,
    input wire  [31:0]   RBCP_ADDR,
    input wire  [7:0]    RBCP_WD,
    input wire           RBCP_WE,
    input wire           RBCP_RE,
    output reg           RBCP_ACK,
    output reg  [7:0]    RBCP_RD,

    output wire          BUS_WR,
    output wire          BUS_RD,
    output wire [31:0]   BUS_ADD,
    inout wire  [7:0]    BUS_DATA

    // TODO
    //input wire BUS_ACK_REQ
    //input wire BUS_ACK
);

reg RBCP_TO_BUS_RD, RBCP_TO_BUS_RD_BUF;
reg RBCP_TO_BUS_WR;

always @(posedge BUS_CLK) begin
    if(BUS_RST)
        RBCP_ACK <= 0;
    else begin
        if (RBCP_ACK == 1)
            RBCP_ACK <= 0;
        else
            RBCP_ACK <= (RBCP_TO_BUS_RD_BUF | RBCP_TO_BUS_WR);
    end
end

always@(posedge BUS_CLK) begin
    if(RBCP_RE & RBCP_ACT) begin
        RBCP_TO_BUS_RD <= 1'b1;
    end else begin
        RBCP_TO_BUS_RD <= 1'b0;
    end
end

always@(posedge BUS_CLK) begin
    RBCP_TO_BUS_RD_BUF <= RBCP_TO_BUS_RD;
end

always@(posedge BUS_CLK) begin
    if(RBCP_WE & RBCP_ACT) begin
        RBCP_TO_BUS_WR <= 1'b1;
    end else begin
        RBCP_TO_BUS_WR <= 1'b0;
    end
end

always@(posedge BUS_CLK) begin
    RBCP_RD <= BUS_DATA;
end

reg [31:0] RBCP_ADDR_BUF;
always@(posedge BUS_CLK) begin
    RBCP_ADDR_BUF <= RBCP_ADDR;
end

reg [7:0] RBCP_WD_BUF;
always@(posedge BUS_CLK) begin
    RBCP_WD_BUF <= RBCP_WD;
end


// BUS
assign BUS_WR = RBCP_TO_BUS_WR;
assign BUS_RD = RBCP_TO_BUS_RD & ~BUS_WR;
assign BUS_ADD = RBCP_ADDR_BUF;
assign BUS_DATA = (BUS_WR) ? RBCP_WD_BUF : 8'bz;


endmodule
