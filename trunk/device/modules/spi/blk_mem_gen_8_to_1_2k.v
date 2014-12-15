
module blk_mem_gen_8_to_1_2k (
  CLKA, CLKB, DOUTA, DOUTB, WEA, WEB, ADDRA, ADDRB, DINA, DINB
);
  input CLKA;
  input CLKB;
  output [7 : 0] DOUTA;
  output [0 : 0] DOUTB;
  input [0 : 0] WEA;
  input [0 : 0] WEB;
  input [10 : 0] ADDRA;
  input [13 : 0] ADDRB;
  input [7 : 0] DINA;
  input [0 : 0] DINB;
  
  RAMB16_S1_S9 #(
    .WRITE_MODE_A ( "WRITE_FIRST" ),
    .WRITE_MODE_B ( "WRITE_FIRST" ),
    .SIM_COLLISION_CHECK ( "NONE" ))
 dpram  (
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

