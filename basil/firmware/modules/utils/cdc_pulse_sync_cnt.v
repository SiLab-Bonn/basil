/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none


module cdc_pulse_sync_cnt (
    input clk_in,
    input pulse_in,
    input clk_out,
    output pulse_out
);

reg [7:0] sync_cnt;
always @(posedge clk_in) begin
    if(pulse_in)
        sync_cnt <= 120;
    else if(sync_cnt != 100)
        sync_cnt <= sync_cnt + 1;
end

(* ASYNC_REG = "TRUE" *) reg out_sync_ff_1;
(* ASYNC_REG = "TRUE" *) reg out_sync_ff_2;
reg out_sync_ff_3;
always @(posedge clk_out) begin
    out_sync_ff_1 <= sync_cnt[7];
    out_sync_ff_2 <= out_sync_ff_1;
    out_sync_ff_3 <= out_sync_ff_2;
end

assign pulse_out = !out_sync_ff_3 && out_sync_ff_2;

endmodule
