/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module OSERDESE2 
#(
    parameter DATA_RATE_OQ = "DDR",
    parameter DATA_WIDTH = 4,
    parameter SERDES_MODE = "MASTER"
)(
        output wire OQ,
        output wire OFB,
        input wire TQ,
        input wire TFB,
        input wire SHIFTOUT1,
        input wire SHIFTOUT2,
        input wire CLK,
        input wire CLKDIV,
        input wire D1,
        input wire D2,
        input wire D3,
        input wire D4,
        input wire D5,
        input wire D6,
        input wire D7,
        input wire D8,
        input wire TCE,
        input wire OCE,
        input wire TBYTEIN,
        input wire TBYTEOUT,
        input wire RST,
        input wire SHIFTIN1,
        input wire SHIFTIN2,
        input wire T1,
        input wire T2,
        input wire T3,
        input wire T4
);
reg OQ_reg;
always@(posedge CLKDIV) begin
    if (RST)
     OQ_reg <= 1'b0;
    else
     OQ_reg <= 1'b1;  //TODO implement phase
end
assign OFB = 1'b0;
assign OQ = OQ_reg;

endmodule