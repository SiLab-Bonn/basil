/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module blk_mem_gen_8_to_1_2k (
    CLKA, CLKB, DOUTA, DOUTB, WEA, WEB, ADDRA, ADDRB, DINA, DINB
);

input wire CLKA;
input wire CLKB;
output wire [7 : 0] DOUTA;
output wire [0 : 0] DOUTB;
input wire [0 : 0] WEA;
input wire [0 : 0] WEB;
input wire [10 : 0] ADDRA;
input wire [13 : 0] ADDRB;
input wire [7 : 0] DINA;
input wire [0 : 0] DINB;

RAMB16_S1_S9 dpram (
    .CLKA(CLKB),
    .CLKB(CLKA),
    .ENB(1'b1),
    .WEA(WEB),
    .WEB(WEA),
    .ENA(1'b1),
    .SSRA(1'b0),
    .SSRB(1'b0),
    .DIPB(1'b0),
    .ADDRA(ADDRB),
    .ADDRB(ADDRA),
    .DIA(DINB),
    .DIB(DINA),
    .DOA(DOUTB),
    .DOB(DOUTA),
    .DOPB()
);

endmodule
