/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module RAMB16_S1_S9 (
    CLKA, CLKB, ENB, WEA, WEB, ENA, SSRA, SSRB, DIPB, ADDRA, ADDRB, DIA, DIB, DOA, DOB, DOPB
);
input wire CLKA;
input wire CLKB;
output reg [7 : 0] DOB;
output reg [0 : 0] DOA;
input wire [0 : 0] WEA;
input wire [0 : 0] WEB;
input wire [10 : 0] ADDRB;
input wire [13 : 0] ADDRA;
input wire [7 : 0] DIB;
input wire [0 : 0] DIA;

input wire ENB;
input wire ENA;
input wire SSRA;
input wire SSRB;
input wire DIPB;
output wire DOPB;

parameter WIDTHA      = 1;
parameter SIZEA       = 16384;
parameter ADDRWIDTHA  = 14;
parameter WIDTHB      = 8;
parameter SIZEB       = 2048;
parameter ADDRWIDTHB  = 11;

`define max(a,b) {(a) > (b) ? (a) : (b)}
`define min(a,b) {(a) < (b) ? (a) : (b)}

`include "../includes/log2func.v"

localparam maxSIZE   = `max(SIZEA, SIZEB);
localparam maxWIDTH  = `max(WIDTHA, WIDTHB);
localparam minWIDTH  = `min(WIDTHA, WIDTHB);
localparam RATIO     = maxWIDTH / minWIDTH;
localparam log2RATIO = `CLOG2(RATIO);

reg     [minWIDTH-1:0]  RAM [0:maxSIZE-1];

always @(posedge CLKA)
  if (WEA)
    RAM[ADDRA] <= DIA;
  else
    DOA <= RAM[ADDRA];

genvar i;
generate for (i = 0; i < RATIO; i = i+1)
begin: portA
  localparam [log2RATIO-1:0] lsbaddr = i;
  always @(posedge CLKB)
      if (WEB)
        RAM[{ADDRB, lsbaddr}] <= DIB[(i+1)*minWIDTH-1:i*minWIDTH];
      else
        DOB[(i+1)*minWIDTH-1:i*minWIDTH] <= RAM[{ADDRB, lsbaddr}];
end
endgenerate

endmodule
