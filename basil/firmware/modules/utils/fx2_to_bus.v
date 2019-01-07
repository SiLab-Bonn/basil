/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module fx2_to_bus
#(
    parameter                   WIDTH = 16 // 16 bit bus from FX2
) (
    input wire [WIDTH-1:0]      ADD,
    input wire                  RD_B, // neg active, two clock cycles
    input wire                  WR_B, // neg active

    input wire                  BUS_CLK, // FCLK
    output wire [WIDTH-1:0]     BUS_ADD,
    output wire                 BUS_RD,
    output wire                 BUS_WR,
    output wire                 CS_FPGA
);

// remove offset from FX2
assign BUS_ADD = ADD - 16'h4000;

// chip select FPGA
assign CS_FPGA = ~ADD[15] & ADD[14];

// generate read strobe which one clock cycle long
// this is very important to prevent corrupted data
reg RD_B_FF;
always @ (posedge BUS_CLK) begin
    RD_B_FF <= RD_B;
end
assign BUS_RD = ~RD_B & RD_B_FF;

assign BUS_WR = ~WR_B;

endmodule
