
///////////////////////
// Closed loop solution
/////////////////////
module pulse_sync (input clk_in, input pulse_in, input clk_out, output pulse_out);

wire aq_sync;

reg [1:0] in_pre_sync;
always@(posedge clk_in) begin
    in_pre_sync[0] <= pulse_in;
    in_pre_sync[1] <= in_pre_sync[0];
end

reg in_sync_pulse;
initial in_sync_pulse = 0; //works only in FPGA
always@(posedge clk_in) begin
    if (aq_sync)
        in_sync_pulse <= 0;
    else if (!in_pre_sync[1] && in_pre_sync[0])
        in_sync_pulse <= 1;
end

reg [2:0] out_sync;
always@(posedge clk_out) begin
    out_sync[0] <= in_sync_pulse;
    out_sync[1] <= out_sync[0];
    out_sync[2] <= out_sync[1];
end

assign pulse_out = !out_sync[2] && out_sync[1];	
    
reg [1:0] aq_sync_ff;
always@(posedge clk_in) begin
    aq_sync_ff[0] <= out_sync[2];
    aq_sync_ff[1] <= aq_sync_ff[0];
end

assign aq_sync = aq_sync_ff[1];

endmodule

module pulse_sync_cnt (input clk_in, input pulse_in, input clk_out, output pulse_out);

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