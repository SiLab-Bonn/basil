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
always@(posedge clk_in) begin
    if(pulse_in)
        sync_cnt <= 120;
    else if(sync_cnt != 100)
        sync_cnt <= sync_cnt +1;
end 

reg [2:0] sync;
always @(posedge clk_out) begin
    sync[0] <= sync_cnt[7];
    sync[1] <= sync[0];
    sync[2] <= sync[1];
end

wire RST_SYNC;
assign pulse_out = !sync[2] && sync[1];

endmodule
