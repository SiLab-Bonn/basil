/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef ODDR_S6
`define ODDR_S6

`timescale 1ps/1ps
`default_nettype none


module ODDR (
    input wire D1, D2,
    input wire C, CE, R, S,
    output wire Q
);

ODDR2 ODDR2_inst (
  .Q(Q),
  .C0(C),
  .C1(~C),
  .CE(CE),
  .D0(D1),
  .D1(D2),
  .R(R),
  .S(S)
);

endmodule

`endif
