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


reg FLAG_TOGGLE_CLK_A;
initial FLAG_TOGGLE_CLK_A = 0;
always @(posedge CLK_A)
begin
    if (FLAG_IN_CLK_A)
    begin
        FLAG_TOGGLE_CLK_A <= ~FLAG_TOGGLE_CLK_A;
    end
end

(* ASYNC_REG = "TRUE" *) reg flag_out_d_ff_1;
(* ASYNC_REG = "TRUE" *) reg flag_out_d_ff_2;
reg flag_out_d_ff_3;

always @(posedge CLK_B) // first stage
begin
    flag_out_d_ff_1 <= FLAG_TOGGLE_CLK_A;
end

always @(posedge CLK_B) // second stage
begin
    flag_out_d_ff_2 <= flag_out_d_ff_1;
end

always @(posedge CLK_B)
begin
    flag_out_d_ff_3 <= flag_out_d_ff_2;
end

assign FLAG_OUT_CLK_B = (flag_out_d_ff_3 ^ flag_out_d_ff_2); // XOR

endmodule
