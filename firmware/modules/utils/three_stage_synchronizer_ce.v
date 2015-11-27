/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

// synchronizing asynchronous signals/flags, prevents metastable events

module three_stage_synchronizer_ce #(
    parameter WIDTH = 1
) (
    input wire                  CLK,
    input wire                  CE,
    input wire  [WIDTH-1:0]     IN,
    output reg  [WIDTH-1:0]     OUT
);

reg [WIDTH-1:0] out_d_ff_1, out_d_ff_2;


always @(posedge CLK) // first stage
begin
    if (CE)
    begin
        out_d_ff_1 <= IN;
        out_d_ff_2 <= out_d_ff_1;
        OUT <= out_d_ff_2;
    end
end

endmodule
