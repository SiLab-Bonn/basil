/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none
 
module timestamp640_core
#(
    parameter ABUSWIDTH = 16,
    parameter IDENTIFIER = 4'b0001,
	parameter CLKDV = 4
)(
    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    input wire CLK320,
    input wire CLK160,
    input wire CLK40,
    input wire DI,
    input wire EXT_ENABLE,
	input wire [63:0] EXT_TIMESTAMP,
    output wire [63:0] TIMESTAMP_OUT,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,
    
    input wire FIFO_READ_TRAILING,
    output wire FIFO_EMPTY_TRAILING,
    output wire [31:0] FIFO_DATA_TRAILING
); 

localparam VERSION = 3;

//output format:
//31-28: ID, 27-24: 0x1, 23-0: 23-0th bit of timestamp data
//31-28: ID, 27-24: 0x2, 23-0: 47-24th bit of timestamp data
//31-28: ID, 27-24: 0x3, 23-8: tot 7-0: 55-48th bit of timestamp data

wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 

reg CONF_EN, CONF_EXT_ENABLE;
reg CONF_EXT_TIMESTAMP,CONF_EN_TRAILING,CONF_EN_INVERT;
reg [7:0] LOST_DATA_CNT;

always @(posedge BUS_CLK) begin
    if(RST) begin
        CONF_EN <= 0;
        CONF_EXT_TIMESTAMP <=0;
        CONF_EXT_ENABLE <= 0;
        CONF_EN_TRAILING <=0;
		CONF_EN_INVERT <=0;
    end
    else if(BUS_WR) begin
        if(BUS_ADD == 2)
            CONF_EN <= BUS_DATA_IN[0];
            CONF_EXT_TIMESTAMP <=BUS_DATA_IN[1];
            CONF_EXT_ENABLE <=BUS_DATA_IN[2];
            CONF_EN_TRAILING <=BUS_DATA_IN[3];
            CONF_EN_INVERT <=BUS_DATA_IN[4];
    end
end

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= {3'b0,CONF_EN_INVERT,
				                 CONF_EN_TRAILING,CONF_EXT_ENABLE,CONF_EXT_TIMESTAMP,CONF_EN};
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= LOST_DATA_CNT;
        else
            BUS_DATA_OUT <= 8'b0;
    end
end

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(CLK40), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;
wire EN_SYNC; 
assign EN_SYNC= CONF_EN | ( EXT_ENABLE & CONF_EXT_ENABLE);


reg [7:0] sync_cnt;
always@(posedge BUS_CLK) begin
    if(RST)
        sync_cnt <= 120;
    else if(sync_cnt != 100)
        sync_cnt <= sync_cnt +1;
end 
wire RST_LONG;
assign RST_LONG = sync_cnt[7];

reg [63:0] INT_TIMESTAMP;
wire [63:0] TIMESTAMP;
always@(posedge CLK40) begin
    if(RST_SYNC)
        INT_TIMESTAMP <= 0;
    else
        INT_TIMESTAMP <= INT_TIMESTAMP + 1;
end
assign TIMESTAMP = CONF_EXT_TIMESTAMP ?  EXT_TIMESTAMP: INT_TIMESTAMP;

// de-serialize
wire [CLKDV*4-1:0] TDC, TDC_DES;
reg  [CLKDV*4-1:0] TDC_DES_PREV;

ddr_des #(.CLKDV(CLKDV)) iddr_des_tdc(.CLK2X(CLK320), .CLK(CLK160), .WCLK(CLK40), .IN(DI), .OUT(TDC), .OUT_FAST());

assign TDC_DES = CONF_EN_INVERT ? ~TDC : TDC;

always @ (posedge CLK40)
    TDC_DES_PREV <= TDC_DES;
    
wire  [CLKDV*4:0] TDC_TO_COUNT;
assign TDC_TO_COUNT[CLKDV*4] = TDC_DES_PREV[0];
assign TDC_TO_COUNT[CLKDV*4-1:0] = TDC_DES;

reg [3:0] RISING_EDGES_CNT, FALLING_EDGES_CNT;
reg [3:0] RISING_POS, FALLING_POS;

integer i;
always @ (*) begin
    FALLING_EDGES_CNT = 0;
    RISING_EDGES_CNT = 0;
    RISING_POS = 0;
    FALLING_POS = 0;
    for (i=0; i<16; i=i+1) begin
        if ((TDC_TO_COUNT[16-i-1] == 1) && (TDC_TO_COUNT[16-i]==0)) begin
            if (RISING_EDGES_CNT == 0)
                RISING_POS = i;
                
            RISING_EDGES_CNT = RISING_EDGES_CNT + 1;
        end
        
        if ((TDC_TO_COUNT[i] == 0) && (TDC_TO_COUNT[i+1]==1)) begin
            if (FALLING_EDGES_CNT == 0)
                FALLING_POS = 15 - i;
            
            FALLING_EDGES_CNT = FALLING_EDGES_CNT + 1;
        end
    end
end

reg WAITING_FOR_TRAILING;
always@(posedge CLK40)
    if(RST)
        WAITING_FOR_TRAILING <= 0;
    else if(RISING_EDGES_CNT < FALLING_EDGES_CNT)
        WAITING_FOR_TRAILING <= 0;
    else if( (RISING_EDGES_CNT > FALLING_EDGES_CNT) & EN_SYNC)
        WAITING_FOR_TRAILING <= 1;

reg [67:0] LAST_RISING;
always@(posedge CLK40)
    if(RST)
        LAST_RISING <= 0;
    else if (RISING_EDGES_CNT > 0 )
        LAST_RISING <= {TIMESTAMP, RISING_POS};

reg [67:0] LAST_FALLING;
always@(posedge CLK40)
    if(RST)
        LAST_FALLING <= 0;
    else if (FALLING_EDGES_CNT > 0)
        LAST_FALLING <= {TIMESTAMP, FALLING_POS};

wire RISING;
assign RISING = (RISING_EDGES_CNT > 0 & EN_SYNC );

wire FALLING;
assign FALLING = (FALLING_EDGES_CNT > 0 & CONF_EN_TRAILING & EN_SYNC );

reg [2:0] FALLING_FF;
reg [2:0] RISING_FF;
wire FALLING_SYNC;
wire RISING_SYNC;
always@(posedge CLK40)
    if(RST) begin
        FALLING_FF <= 3'b0;
        RISING_FF <= 3'b0;
    end
    else begin
        FALLING_FF <= {FALLING_FF[1:0], FALLING};
        RISING_FF <= {RISING_FF[1:0], RISING};
    end
assign RISING_SYNC = RISING_FF[0] & ~RISING_FF[1];
assign FALLING_SYNC = FALLING_FF[0] & ~FALLING_FF[1];

wire [71:0] cdc_data_in;
assign cdc_data_in =  {4'b0,LAST_RISING} ;
wire [71:0] cdc_data_in_f;
assign cdc_data_in_f =  {4'b0,LAST_FALLING} ;

wire cdc_fifo_write;
assign cdc_fifo_write = RISING_SYNC ;
wire cdc_fifo_write_f;
assign cdc_fifo_write_f = CONF_EN_TRAILING ? FALLING_SYNC: 1'b0;

wire fifo_full,fifo_write,cdc_fifo_empty;
wire fifo_full_f,fifo_write_f,cdc_fifo_empty_f;
wire wfull,wfull_f;
always@(posedge CLK40) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && cdc_fifo_write && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT +1;
    else if (wfull_f && cdc_fifo_write_f && LOST_DATA_CNT != -1)
            LOST_DATA_CNT <= LOST_DATA_CNT +1;
end

////////////// write fifo (rising)
wire [71:0] cdc_data_out;   
wire cdc_fifo_read;
cdc_syncfifo 
#(.DSIZE(72), .ASIZE(8))
 cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data_in),
    .winc(cdc_fifo_write), .wclk(CLK40), .wrst(RST_LONG),
    .rinc(cdc_fifo_read), .rclk(BUS_CLK), .rrst(RST_LONG)
);
 
reg [1:0] byte2_cnt, byte2_cnt_prev;
always@(posedge BUS_CLK)
    byte2_cnt_prev <= byte2_cnt;
assign cdc_fifo_read = (byte2_cnt_prev==0 & byte2_cnt!=0);
assign fifo_write = byte2_cnt_prev != 0;

always@(posedge BUS_CLK)
    if(RST)
        byte2_cnt <= 0;
    else if(!cdc_fifo_empty && !fifo_full && byte2_cnt == 0 ) 
        byte2_cnt <= 3;
    else if (!fifo_full & byte2_cnt != 0)
        byte2_cnt <= byte2_cnt - 1;

reg [71:0] data_buf;
always@(posedge BUS_CLK)
    if(cdc_fifo_read)
        data_buf <= cdc_data_out;

wire [31:0] fifo_write_data_byte [3:0];
assign fifo_write_data_byte[0]={IDENTIFIER,4'b0001,data_buf[23:0]};
assign fifo_write_data_byte[1]={IDENTIFIER,4'b0010,data_buf[47:24]};
assign fifo_write_data_byte[2]={IDENTIFIER,4'b0011,data_buf[71:48]};
wire [31:0] fifo_data_in;
assign fifo_data_in = fifo_write_data_byte[byte2_cnt];

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(1024))  fifo_i
( .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
    .write(fifo_write),
    .read(FIFO_READ), 
    .data_in(fifo_data_in), 
    .full(fifo_full), 
    .empty(FIFO_EMPTY), 
    .data_out(FIFO_DATA[31:0]), .size() 
);

////////////// write fifo (falling)
wire [71:0] cdc_data_out_f;   
wire cdc_fifo_read_f;
cdc_syncfifo 
#(.DSIZE(72), .ASIZE(8))
 cdc_syncfifo_i_f
(
    .rdata(cdc_data_out_f),
    .wfull(wfull_f),
    .rempty(cdc_fifo_empty_f),
    .wdata(cdc_data_in_f),
    .winc(cdc_fifo_write_f), .wclk(CLK40), .wrst(RST_LONG),
    .rinc(cdc_fifo_read_f), .rclk(BUS_CLK), .rrst(RST_LONG)
);
 
reg [1:0] byte2_cnt_f, byte2_cnt_prev_f;
always@(posedge BUS_CLK)
    byte2_cnt_prev_f <= byte2_cnt_f;
assign cdc_fifo_read_f = (byte2_cnt_prev_f==0 & byte2_cnt_f!=0);
assign fifo_write_f = byte2_cnt_prev_f != 0;

always@(posedge BUS_CLK)
    if(RST)
        byte2_cnt_f <= 0;
    else if(!cdc_fifo_empty_f && !fifo_full_f && byte2_cnt_f == 0 ) 
        byte2_cnt_f <= 3;
    else if (!fifo_full_f & byte2_cnt_f != 0)
        byte2_cnt_f <= byte2_cnt_f - 1;

reg [71:0] data_buf_f;
always@(posedge BUS_CLK)
    if(cdc_fifo_read_f)
        data_buf_f <= cdc_data_out_f;

wire [31:0] fifo_write_data_byte_f [3:0];
assign fifo_write_data_byte_f[0]={IDENTIFIER,4'b0101,data_buf_f[23:0]};
assign fifo_write_data_byte_f[1]={IDENTIFIER,4'b0110,data_buf_f[47:24]};
assign fifo_write_data_byte_f[2]={IDENTIFIER,4'b0111,data_buf_f[71:48]};
wire [31:0] fifo_data_in_f;
assign fifo_data_in_f = fifo_write_data_byte_f[byte2_cnt_f];

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(1024))  fifo_i_f
( .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
    .write(fifo_write_f),
    .read(FIFO_READ_TRAILING), 
    .data_in(fifo_data_in_f), 
    .full(fifo_full_f), 
    .empty(FIFO_EMPTY_TRAILING), 
    .data_out(FIFO_DATA_TRAILING[31:0]), .size() 
);

endmodule
