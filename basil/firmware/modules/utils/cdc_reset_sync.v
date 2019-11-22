/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

// Closed loop solution

module cdc_reset_sync (
    input wire clk_in,
    input wire pulse_in,
    input wire clk_out,
    output wire pulse_out
);

wire aq_sync;

reg [1:0] in_pre_sync;
always @(posedge clk_in) begin
    in_pre_sync[0] <= pulse_in;
    in_pre_sync[1] <= in_pre_sync[0];
end

reg in_sync_pulse;
initial in_sync_pulse = 0;  // works only in FPGA
always @(posedge clk_in) begin
    if (in_pre_sync[1])
        in_sync_pulse <= 1;
    else if (aq_sync)
        in_sync_pulse <= 0;
end

(* ASYNC_REG = "TRUE" *) reg out_sync_ff_1;
(* ASYNC_REG = "TRUE" *) reg out_sync_ff_2;
always @(posedge clk_out) begin
    out_sync_ff_1 <= in_sync_pulse;
    out_sync_ff_2 <= out_sync_ff_1;
end

assign pulse_out = out_sync_ff_2;

(* ASYNC_REG = "TRUE" *) reg aq_sync_ff_1;
(* ASYNC_REG = "TRUE" *) reg aq_sync_ff_2;
always @(posedge clk_in) begin
    aq_sync_ff_1 <= out_sync_ff_2;
    aq_sync_ff_2 <= aq_sync_ff_1;
end

assign aq_sync = aq_sync_ff_2;

endmodule
