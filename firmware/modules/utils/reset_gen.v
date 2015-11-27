/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module reset_gen #(
    parameter CNT = 8'd128
) (
    CLK,
    RST
); 

input wire CLK;
output wire RST;

reg [7:0] rst_cnt;
 
initial rst_cnt = CNT;

always@(posedge CLK)
     if(rst_cnt != 0)
        rst_cnt <= rst_cnt -1;

assign RST = (rst_cnt != 0 );

endmodule
