/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 *
 * This is a 16,384-bit asymmetric true-dual-port synchronous RAM. Port A
 * addresses 2048 8-bit words through ADDRA, DINA, DOUTA, and WEA. Port B
 * addresses 16384 individual bits through ADDRB, DINB, DOUTB, and WEB.
 * When one port reads and writes the same location on a clock edge, its output
 * receives the previous value while the new value is stored. Access to the
 * same bit from both independently clocked ports should be avoided.
 *
 * The behavioral description follows the AMD UG901 asymmetric
 * true-dual-port read-first inference template. The ram_style attribute asks
 * Vivado to map it to a 7-series RAMB18E1, while the same RTL remains usable
 * with Verilator and Icarus.
 // docs.amd.com/r/en-US/2026.1/ug901-vivado-synthesis/True-Dual-Port-Asymmetric-RAM-Read-First-Verilog
 * https:
 *
 * The RAMB18E1 primitive is documented in AMD UG953.
 * https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/RAMB18E1
 * ------------------------------------------------------------
 */
`ifndef BLK_MEM_GEN_8_TO_1_2K
`define BLK_MEM_GEN_8_TO_1_2K

`timescale 1ns / 1ps
`default_nettype none


module blk_mem_gen_8_to_1_2k (
    CLKA,
    CLKB,
    DOUTA,
    DOUTB,
    WEA,
    WEB,
    ADDRA,
    ADDRB,
    DINA,
    DINB
);

    input wire CLKA;
    input wire CLKB;
    output reg [7 : 0] DOUTA;
    output reg DOUTB;
    input wire WEA;
    input wire WEB;
    input wire [10 : 0] ADDRA;
    input wire [13 : 0] ADDRB;
    input wire [7 : 0] DINA;
    input wire DINB;

    // Both ports can read and write. Current SPI instances tie one write enable low,
    // but retaining the exact TDP template keeps the memory reusable and inferable.
    // Static lint cannot prove that the two SPI instances have only one active writer.
    // verilator lint_off MULTIDRIVEN
    (* ram_style = "block" *)
    reg ram[0:16383];
    // verilator lint_on MULTIDRIVEN

    // Narrow 1-bit port.
    always @(posedge CLKB) begin
        DOUTB <= ram[ADDRB];
        if (WEB) ram[ADDRB] <= DINB;
    end

    // Wide 8-bit port. Concatenating the byte address and fixed loop index is the
    // UG901 asymmetric-port form. Nonblocking assignments provide read-first
    // behavior when this port writes.
    always @(posedge CLKA) begin : port_a
        integer bit_index;
        reg [2:0] lsb_address;

        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            lsb_address = bit_index[2:0];
            DOUTA[bit_index] <= ram[{ADDRA, lsb_address}];
            if (WEA) ram[{ADDRA, lsb_address}] <= DINA[bit_index];
        end
    end

endmodule

`endif
