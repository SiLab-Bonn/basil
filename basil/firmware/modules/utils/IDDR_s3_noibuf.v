/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef IDDR_S3_NOIBUF_SIM
`define IDDR_S3_NOIBUF_SIM

`timescale 1ps / 1ps
`default_nettype none


module IDDR (
    output wire Q1,
    Q2,
    input  wire C,
    CE,
    D,
    R,
    S
);
    // This Xilinx primitive requires the external vendor simulation library.
    // verilator lint_off MODMISSING


    (* maybe_unknown *)
    FDRSE #(
        .INIT(1'b0)
    ) F0 (
        .C (C),
        .CE(CE),
        .R (R),
        .D (D),
        .S (S),
        .Q (Q1)
    );

    // verilator lint_on MODMISSING

    // This Xilinx primitive requires the external vendor simulation library.
    // verilator lint_off MODMISSING


    (* maybe_unknown *)
    FDRSE #(
        .INIT("0")
    ) F1 (
        .C (~C),
        .CE(CE),
        .R (R),
        .D (D),
        .S (S),
        .Q (Q2)
    );

    // verilator lint_on MODMISSING


endmodule

`endif
