/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
module m26_rx_ch
(
    input wire RST,
    input wire CLK_RX,
    input wire MKD_RX,
    input wire DATA_RX,
    
    output wire WRITE, FRAME_START,
    output wire [15:0] DATA
    
); 

reg [15:0] mkd_sr;
always@(posedge CLK_RX)
    mkd_sr[15:0] <= {mkd_sr[14:0], MKD_RX};

reg [15:0] data_sr;
always@(posedge CLK_RX)
    data_sr[15:0] <= {DATA_RX, data_sr[15:1]};
    
assign FRAME_START = (mkd_sr[15:12] == 4'b1111);

reg [15:0] data_cnt;
always@(posedge CLK_RX)
    if(RST)
        data_cnt <= 16'hffff;
    else if(FRAME_START)
        data_cnt <= 0;
    else if(data_cnt != 16'hffff)
        data_cnt <= data_cnt + 1;

reg [15:0] data_len;
always@(posedge CLK_RX)
    if(RST)
        data_len <= 0;
    else if(data_cnt==31)
        data_len <= data_sr;

        
assign WRITE = FRAME_START | data_cnt == 15 | data_cnt == 31 | ((data_cnt + 1) % 16 == 0 && data_cnt / 16 < data_len + 3);
assign DATA = data_sr;

endmodule
