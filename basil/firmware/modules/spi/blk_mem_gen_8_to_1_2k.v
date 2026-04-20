/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 *
 * Asymmetric true dual-port BRAM: 2048 x 8-bit (Port A) / 16384 x 1-bit (Port B).
 * Total capacity: 16,384 bits — inferred as RAMB18 on Xilinx 7-series and later.
 *
 * Replaces the legacy RAMB16_S1_S9 primitive which is no longer supported in
 * Vivado 2025.x and causes functional issues in synthesis.
 *
 * Port mapping (unchanged from original module interface):
 *   Port A: 8-bit wide, 2048 deep  — ADDRA[10:0], DINA[7:0],  DOUTA[7:0], WEA
 *   Port B: 1-bit wide, 16384 deep — ADDRB[13:0], DINB[0],    DOUTB[0],   WEB
 *
 * Bit addressing: ADDRB[13:3] selects the 8-bit word; ADDRB[2:0] selects the
 * bit within that word (0 = LSB, 7 = MSB), matching the RAMB16_S1_S9 convention.
 *
 * Read behaviour: read-first (output reflects the value before any write in the
 * same cycle), consistent with the RAMB16_S1_S9 default configuration.
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module blk_mem_gen_8_to_1_2k (
    CLKA, CLKB, DOUTA, DOUTB, WEA, WEB, ADDRA, ADDRB, DINA, DINB
);

input  wire         CLKA;
input  wire         CLKB;
output reg  [7 : 0] DOUTA;
output reg  [0 : 0] DOUTB;
input  wire [0 : 0] WEA;
input  wire [0 : 0] WEB;
input  wire [10 : 0] ADDRA;
input  wire [13 : 0] ADDRB;
input  wire [7 : 0] DINA;
input  wire [0 : 0] DINB;

// 2048 words x 8 bits = 16,384 bits — Vivado infers this as a single RAMB18.
(* ram_style = "block" *)
reg [7:0] ram [0:2047];

// -----------------------------------------------------------------------
// Port A: 8-bit synchronous read/write
// -----------------------------------------------------------------------
always @(posedge CLKA) begin
    DOUTA <= ram[ADDRA];          // read-first: capture old value
    if (WEA)
        ram[ADDRA] <= DINA;
end

// -----------------------------------------------------------------------
// Port B: 1-bit synchronous read/write
// ADDRB[13:3] — word address (maps to same address space as ADDRA)
// ADDRB[ 2:0] — bit index within the 8-bit word (0 = LSB)
// -----------------------------------------------------------------------
always @(posedge CLKB) begin
    DOUTB <= ram[ADDRB[13:3]][ADDRB[2:0]];   // read-first
    if (WEB)
        ram[ADDRB[13:3]][ADDRB[2:0]] <= DINB[0];
end

endmodule