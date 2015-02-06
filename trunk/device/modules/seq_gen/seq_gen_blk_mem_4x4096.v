/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module seq_gen_blk_mem (
    clka, clkb, wea, addra, dina, web, addrb, dinb, douta, doutb
);

input clka;
input clkb;
input [0 : 0] wea;
input [10 : 0] addra;
input [7 : 0] dina;
input [0 : 0] web;
input [11 : 0] addrb;
input [3 : 0] dinb;
output [7 : 0] douta;
output [3 : 0] doutb;


RAMB16_S4_S9 mem  (
    .CLKA(clkb),
    .CLKB(clka),
    .ENB(1'b1),
    .WEA(web[0]),
    .WEB(wea[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .SSRB(1'b0),
    .DIPB({1'b0}),
    .ADDRA(addrb[11:0]),
    .ADDRB(addra[10:0]),
    .DIA(dinb[3:0]),
    .DIB(dina[7:0]),
    .DOA(doutb[3:0]),
    .DOB(douta[7:0]),
    .DOPB()
);

endmodule

