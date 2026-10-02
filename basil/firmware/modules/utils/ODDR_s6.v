/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef ODDR_S6_SIM
`define ODDR_S6_SIM

`timescale 1ps / 1ps


// Preserve the existing module name and its callers.
// verilog_lint: waive module-filename
module ODDR (
    input  wire D1,
    D2,
    input  wire C,
    CE,
    R,
    S,
    output wire Q
);
    // This Xilinx primitive requires the external vendor simulation library.
    // verilator lint_off MODMISSING


    (* maybe_unknown *)
    ODDR2 ODDR2_inst (
        .Q (Q),
        .C0(C),
        .C1(~C),
        .CE(CE),
        .D0(D1),
        .D1(D2),
        .R (R),
        .S (S)
    );

    // verilator lint_on MODMISSING

endmodule

`endif
