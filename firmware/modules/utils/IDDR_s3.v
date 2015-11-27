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

IFDDRRSE IFDDRRSE_inst (
    .Q0(Q1), 
    .Q1(Q2), 
    .C0(C), 
    .C1(~C), 
    .CE(CE), 
    .D(D), 
    .R(R), 
    .S(S)
);

endmodule
