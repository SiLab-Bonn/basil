/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef RAMB16_S1_S2_SIM
`define RAMB16_S1_S2_SIM

`timescale 1ps / 1ps
`default_nettype none


module RAMB16_S1_S2 (
    CLKA,
    CLKB,
    ENB,
    WEA,
    WEB,
    ENA,
    SSRA,
    SSRB,
    DIPB,
    ADDRA,
    ADDRB,
    DIA,
    DIB,
    DOA,
    DOB,
    DOPB
);
    input wire CLKA;
    input wire CLKB;
    output reg [1 : 0] DOB;
    output reg [0 : 0] DOA;
    input wire [0 : 0] WEA;
    input wire [0 : 0] WEB;
    input wire [12 : 0] ADDRB;
    input wire [13 : 0] ADDRA;
    input wire [1 : 0] DIB;
    input wire [0 : 0] DIA;

    input wire ENB;
    input wire ENA;
    input wire SSRA;
    input wire SSRB;
    input wire DIPB;
    output wire DOPB;

    assign DOPB = 1'b0;

    parameter WIDTHA = 1;
    parameter SIZEA = 16384;
    parameter ADDRWIDTHA = 14;
    parameter WIDTHB = 2;
    parameter SIZEB = SIZEA / 2;
    parameter ADDRWIDTHB = 13;

    `define MAX(a, b) (a) > (b) ? (a) : (b)
    `define MIN(a, b) (a) < (b) ? (a) : (b)

    `include "../includes/log2func.v"

    localparam MAXSIZE = `MAX(SIZEA, SIZEB);
    localparam MAXWIDTH = `MAX(WIDTHA, WIDTHB);
    localparam MINWIDTH = `MIN(WIDTHA, WIDTHB);
    localparam RATIO = MAXWIDTH / MINWIDTH;
    localparam LOG2RATIO = `CLOG2(RATIO);

    reg [MINWIDTH-1:0] RAM[0:MAXSIZE-1];

    always @(posedge CLKA)
        if (WEA) RAM[ADDRA] <= DIA;
        else DOA <= RAM[ADDRA];

    genvar i;
    generate
        // Keep the existing hierarchical instance paths.
        // verilog_lint: waive generate-label-prefix
        for (i = 0; i < RATIO; i = i + 1) begin : portA
            localparam [LOG2RATIO-1:0] LSBADDR = i;
            always @(posedge CLKB)
                if (WEB) RAM[{ADDRB, LSBADDR}] <= DIB[(i+1)*MINWIDTH-1:i*MINWIDTH];
                else DOB[(i+1)*MINWIDTH-1:i*MINWIDTH] <= RAM[{ADDRB, LSBADDR}];
        end
    endgenerate

endmodule

`endif
