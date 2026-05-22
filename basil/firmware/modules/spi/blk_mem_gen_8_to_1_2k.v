/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 *
 * Asymmetric true dual-port BRAM: 2048 x 8-bit (Port A) / 16384 x 1-bit (Port B).
 * Total capacity: 16,384 bits → inferred as RAMB18E1 on 7-series (Kintex-7).
 *
 * Replaces the legacy RAMB16_S1_S9 primitive (Spartan-3/Virtex-4 era),
 * which is unsupported in Vivado.
 *
 * Inference strategy:
 *   Underlying array is 16384 × 1-bit. Port B (1-bit) accesses it directly.
 *   Port A (8-bit) uses a single always block with a procedural for loop
 *   that expands to 8 consecutive 1-bit locations at {ADDRA, i[2:0]}.
 *   Vivado sees only two clocked ports and infers a single RAMB18E1 in
 *   true dual-port (TDP) mode with asymmetric widths.
 *   (* ram_style = "block" *) attribute forces BRAM over distributed RAM.
 *
 * Port mapping (unchanged from original):
 *   Port A: 8-bit wide, 2048 deep  — ADDRA[10:0], DINA[7:0], DOUTA[7:0], WEA
 *   Port B: 1-bit wide, 16384 deep — ADDRB[13:0], DINB[0],   DOUTB[0],   WEB
 *
 * Read behaviour: read-first on both ports (consistent with legacy primitive).
 * ------------------------------------------------------------
 */
`ifndef BASIL_SPI_BLK_MEM_GEN_8_TO_1_2K_V
`define BASIL_SPI_BLK_MEM_GEN_8_TO_1_2K_V

`timescale 1ps/1ps
`default_nettype none


module blk_mem_gen_8_to_1_2k #(
    // Disable a port's write logic when its write enable is tied low.
    // This avoids elaborating unused cross-clock RAM write paths.
    parameter PORT_A_WRITABLE = 1,
    parameter PORT_B_WRITABLE = 1
) (
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

// -------------------------------------------------------------------
// Underlying array: 16384 × 1-bit, total 16,384 bits.
// Vivado infers a single RAMB18E1 in true-dual-port mode with
// asymmetric widths (Port A = 8-bit, Port B = 1-bit).
// -------------------------------------------------------------------

(* ram_style = "block" *)
reg [0:0] ram [0:16383];

// ------------------------------
// Port A — 8-bit synchronous (procedural for loop, one port)
//
// ADDRA[10:0] selects a word; bit i lives at {ADDRA, i[2:0]}.
// The procedural for loop exposes only a single write port,
// matching the Vivado BRAM inference requirements.
// ------------------------------
integer i;

generate
    if (PORT_A_WRITABLE) begin : port_a_read_write
        always @(posedge CLKA) begin
            for (i = 0; i < 8; i = i + 1) begin
                DOUTA[i] <= ram[{ADDRA, i[2:0]}];
                if (WEA)
                    ram[{ADDRA, i[2:0]}] <= DINA[i];
            end
        end
    end else begin : port_a_read_only
        always @(posedge CLKA) begin
            for (i = 0; i < 8; i = i + 1)
                DOUTA[i] <= ram[{ADDRA, i[2:0]}];
        end
    end
endgenerate

// ------------------------------
// Port B — 1-bit synchronous (simple, one port)
// ------------------------------
generate
    if (PORT_B_WRITABLE) begin : port_b_read_write
        always @(posedge CLKB) begin
            DOUTB          <= ram[ADDRB];
            if (WEB)
                ram[ADDRB] <= DINB[0];
        end
    end else begin : port_b_read_only
        always @(posedge CLKB)
            DOUTB <= ram[ADDRB];
    end
endgenerate

endmodule

`endif
