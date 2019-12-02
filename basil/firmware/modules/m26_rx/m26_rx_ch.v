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

    output reg WRITE,
    output reg FRAME_START,
    output reg [15:0] DATA,
    output reg INVALID,
    output reg INVALID_FLAG
);

reg [15:0] mkd_sr;
always @(posedge CLK_RX)
    mkd_sr[15:0] <= {mkd_sr[14:0], MKD_RX};

reg [17:0] data_sr;
always @(posedge CLK_RX)
    data_sr[17:0] <= {DATA_RX, data_sr[17:1]};

reg start_cnt;
always @(posedge CLK_RX)
    if(RST)
        start_cnt <= 1'b0;
    else
        if(mkd_sr[15:12] == 4'b1111)
            start_cnt <= 1'b1;
        else
            start_cnt <= 1'b0;

reg start_cnt_dly;
always @(posedge CLK_RX)
    if(RST)
        start_cnt_dly <= 1'b0;
    else
        start_cnt_dly <= start_cnt;

always @(posedge CLK_RX)
    if(RST)
        FRAME_START <= 1'b0;
    else
        if(start_cnt_dly == 1)
            FRAME_START <= 1'b1;
        else
            FRAME_START <= 1'b0;

reg [13:0] data_cnt;  // must count until 574 * 16
always @(posedge CLK_RX)
    if(RST)
        data_cnt <= 14'h3FFF;
    else
        if(start_cnt)
            data_cnt <= 0;
        else if(data_cnt != 14'h3FFF)
            data_cnt <= data_cnt + 1;

reg data_len_ok;
always @(posedge CLK_RX)
    if(RST)
        data_len_ok <= 1'b0;
    else
        if(data_cnt==30 && data_sr[17:2] <= 570)  // maximum valid data words is 570 (total words 574)
            data_len_ok <= 1'b1;

always @(posedge CLK_RX)
    if(RST)
        INVALID <= 1'b0;
    else
        if(data_cnt==31)
            INVALID <= !data_len_ok;

always @(posedge CLK_RX)
    if(RST)
        INVALID <= 1'b0;
    else
        if(data_cnt==31 && !data_len_ok)
            INVALID_FLAG <= 1'b1;
        else
            INVALID_FLAG <= 1'b0;

reg [15:0] data_len;
always @(posedge CLK_RX)
    if(RST)
        data_len <= 0;
    else
        if(!data_len_ok)
            data_len <= 0;
        else if(data_cnt==31)
            data_len <= data_sr[16:1];

// Requiring Mimosa26 registers clkrateout = 1 and dualchannel = 1 (80MHz dual-channel)
always @(posedge CLK_RX)
    if(RST)
        WRITE <= 1'b0;
    else
        if(data_cnt == 0 || data_cnt == 16)  // write header and frame counter
            WRITE <= 1'b1;
        else if(data_len_ok && data_cnt % 16 == 0 && data_cnt / 16 <= data_len + 3)  // including trailer
            WRITE <= 1'b1;
        else if(!data_len_ok && data_cnt == 32)  // just data length w/o trailer
            WRITE <= 1'b1;
        else
            WRITE <= 1'b0;

always @(posedge CLK_RX)
    if(RST)
        DATA <= 1'b0;
    else
        if(data_cnt % 16 == 0)
            DATA <= data_sr[15:0];

endmodule
