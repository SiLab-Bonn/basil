/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

// synchronize flag (signal lasts just one clock cycle) to new clock domain (CLK_B)

module flag_domain_crossing(
    input wire      CLK_A,
    input wire      CLK_B,
    input wire      FLAG_IN_CLK_A,
    output wire     FLAG_OUT_CLK_B
);


reg         FLAG_TOGGLE_CLK_A;
initial     FLAG_TOGGLE_CLK_A = 0;
reg [2:0]   SYNC_CLK_B;

always @ (posedge CLK_A)
begin
    if (FLAG_IN_CLK_A)
    begin
        FLAG_TOGGLE_CLK_A <= ~FLAG_TOGGLE_CLK_A;
    end
end

always @ (posedge CLK_B)
begin
    SYNC_CLK_B <= {SYNC_CLK_B[1:0], FLAG_TOGGLE_CLK_A};
end

assign FLAG_OUT_CLK_B = (SYNC_CLK_B[2] ^ SYNC_CLK_B[1]); // XOR

endmodule
