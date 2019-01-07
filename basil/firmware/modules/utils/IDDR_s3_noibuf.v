/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module IDDR (
    output wire Q1, Q2, 
    input wire C, CE, D, R, S
);
              
FDRSE F0 (
    .C(C),
    .CE(CE),
    .R(R),
    .D(D),
    .S(S),
    .Q(Q1)
);
defparam F0.INIT = 1'b0;

FDRSE F1 (
    .C(~C),
    .CE(CE),
    .R(R),
    .D(D),
    .S(S),
    .Q(Q2)
);
defparam F1.INIT = "0";

endmodule
