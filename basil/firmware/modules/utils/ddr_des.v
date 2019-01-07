/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module ddr_des 
#(
    parameter CLKDV = 4
)(
    input wire CLK2X, 
    input wire CLK, 
    input wire WCLK,
    input wire IN,
    output reg [CLKDV*4-1:0] OUT,
    output wire [1:0] OUT_FAST
);

wire [1:0] DDRQ;
IDDR IDDR_inst (
   .Q1(DDRQ[1]), // 1-bit output for positive edge of clock 
   .Q2(DDRQ[0]), // 1-bit output for negative edge of clock
   .C(CLK2X), // 1-bit clock input
   .CE(1'b1), // 1-bit clock enable input
   .D(IN), // 1-bit DDR data input
   .R(1'b0), // 1-bit reset
   .S(1'b0) // 1-bit set
);

assign OUT_FAST = DDRQ;

reg [1:0] DDRQ_DLY;

always@(posedge CLK2X)
    DDRQ_DLY[1:0] <= DDRQ[1:0];

reg [3:0] DDRQ_DATA;
always@(posedge CLK2X)
    DDRQ_DATA[3:0] <= {DDRQ_DLY[1:0], DDRQ[1:0]};

 reg [3:0] DDRQ_DATA_BUF;
always@(posedge CLK2X)
    DDRQ_DATA_BUF[3:0] <= DDRQ_DATA[3:0];

reg [3:0] DATA_IN;
always@(posedge CLK)
    DATA_IN[3:0] <= DDRQ_DATA_BUF[3:0];

reg [CLKDV*4-1:0] DATA_IN_SR;
always@(posedge CLK)
    DATA_IN_SR <= {DATA_IN_SR[CLKDV*4-5:0],DATA_IN[3:0]};

always@(posedge WCLK)
    OUT <= DATA_IN_SR;

endmodule
