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

input wire clka;
input wire clkb;
input wire [0 : 0] wea;
input wire [13 : 0] addra;
input wire [7 : 0] dina;
input wire [0 : 0] web;
input wire [12 : 0] addrb;
input wire [15 : 0] dinb;
output wire [7 : 0] douta;
output wire [15 : 0] doutb;

RAMB16_S1_S2 mem0  (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[7]}),
    .DIB({dinb[15], dinb[7]}),
    .DOA({douta[7]}),
    .DOB({doutb[15], doutb[7]})
);

RAMB16_S1_S2 mem1  (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[6]}),
    .DIB({dinb[14], dinb[6]}),
    .DOA({douta[6]}),
    .DOB({doutb[14], doutb[6]})
);

RAMB16_S1_S2 mem2  (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[5]}),
    .DIB({dinb[13], dinb[5]}),
    .DOA({douta[5]}),
    .DOB({doutb[13], doutb[5]})
);

RAMB16_S1_S2 mem3 (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[4]}),
    .DIB({dinb[12], dinb[4]}),
    .DOA({douta[4]}),
    .DOB({doutb[12], doutb[4]})
);

RAMB16_S1_S2 mem4  (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[3]}),
    .DIB({dinb[11], dinb[3]}),
    .DOA({douta[3]}),
    .DOB({doutb[11], doutb[3]})
);

RAMB16_S1_S2 mem5  (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[2]}),
    .DIB({dinb[10], dinb[2]}),
    .DOA({douta[2]}),
    .DOB({doutb[10], doutb[2]})
);

RAMB16_S1_S2 mem6  (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[1]}),
    .DIB({dinb[9], dinb[1]}),
    .DOA({douta[1]}),
    .DOB({doutb[9], doutb[1]})
);

RAMB16_S1_S2 mem7  (
    .CLKA(clka),
    .CLKB(clkb),
    .ENB(1'b1),
    .SSRB(1'b0),
    .WEA(wea[0]),
    .WEB(web[0]),
    .ENA(1'b1),
    .SSRA(1'b0),
    .ADDRA(addra[13:0]),
    .ADDRB(addrb[12:0]),
    .DIA({dina[0]}),
    .DIB({dinb[8], dinb[0]}),
    .DOA({douta[0]}),
    .DOB({doutb[8], doutb[0]})
);

endmodule

