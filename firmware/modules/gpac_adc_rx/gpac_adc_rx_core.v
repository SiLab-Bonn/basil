/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module gpac_adc_rx_core
#(
    parameter   ABUSWIDTH = 16,
    parameter [1:0] ADC_ID = 0,
    parameter [0:0] HEADER_ID = 0
)
(
    input wire ADC_ENC,
    input wire [13:0] ADC_IN,

    input wire ADC_SYNC,
    input wire ADC_TRIGGER,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    output wire LOST_ERROR
);

localparam VERSION = 1;

// 0 - soft reset
// 1 - start/status

//TODO: 
// - external trigger /rising falling

wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 

reg [7:0] status_regs [15:0];

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 8'b0000_0000; // CONF_START_WITH_SYNC = TRUE
        status_regs[3] <= 0;
        status_regs[4] <= 0;
        status_regs[5] <= 0;
        status_regs[6] <= 1;
        status_regs[7] <= 0;
        status_regs[8] <= 0;
    end
    else if(BUS_WR && BUS_ADD < 16)
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
end

wire START;
assign START = (BUS_ADD==1 && BUS_WR);

wire CONF_START_WITH_SYNC;
assign CONF_START_WITH_SYNC = status_regs[2][0];

wire CONF_EN_EX_TRIGGER;
assign CONF_EN_EX_TRIGGER = status_regs[2][1];

wire CONF_SINGLE_DATA;
assign CONF_SINGLE_DATA = status_regs[2][2];

wire [23:0] CONF_DATA_CNT;
assign CONF_DATA_CNT = {status_regs[5], status_regs[4], status_regs[3]};

wire [7:0] CONF_SAMPLE_SKIP = status_regs[6];
wire [7:0] CONF_SAMPEL_DLY = status_regs[7];

reg [7:0] CONF_ERROR_LOST;
assign LOST_ERROR = CONF_ERROR_LOST != 0;

reg CONF_DONE;

wire [7:0] BUS_STATUS_OUT;
assign BUS_STATUS_OUT = status_regs[BUS_ADD[3:0]];
    
always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= {7'b0, CONF_DONE};
        else if(BUS_ADD == 8)
            BUS_DATA_OUT <= CONF_ERROR_LOST;
        else if(BUS_ADD < 16)
            BUS_DATA_OUT <= BUS_STATUS_OUT;
    end
end

wire rst_adc_sync;
cdc_reset_sync isync_rst (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(ADC_ENC), .pulse_out(rst_adc_sync));

wire start_adc_sync;
cdc_pulse_sync istart_rst (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(ADC_ENC), .pulse_out(start_adc_sync));

wire adc_sync_pulse;
pulse_gen_rising pulse_adc_sync (.clk_in(ADC_ENC), .in(ADC_SYNC), .out(adc_sync_pulse));

//long reset is needed
reg [7:0] sync_cnt;
always@(posedge BUS_CLK) begin
    if(RST)
        sync_cnt <= 120;
    else if(sync_cnt != 100)
        sync_cnt <= sync_cnt +1;
end  
wire RST_LONG;
assign RST_LONG = sync_cnt[7];

/*
reg [7:0] align_cnt;
always@(posedge ADC_ENC) begin
    if(adc_sync_pulse)
        align_cnt <= 0;
    else if(align_cnt == (CONF_SAMPLE_SKIP - 1))
        align_cnt <= 0;
    else
        align_cnt <= align_cnt + 1;
end
*/

reg adc_sync_wait;
always@(posedge ADC_ENC) begin
    if(rst_adc_sync)
        adc_sync_wait <= 0;
    else if(start_adc_sync)
        adc_sync_wait <= 1;
    else if (adc_sync_pulse)
        adc_sync_wait <= 0;
end

wire start_data_count;
assign start_data_count = (CONF_START_WITH_SYNC ? (adc_sync_wait && adc_sync_pulse) : start_adc_sync) || ( CONF_EN_EX_TRIGGER && ADC_TRIGGER);


reg [23:0] rec_cnt;
always@(posedge ADC_ENC) begin
    if(rst_adc_sync)
        rec_cnt <= 0;
    else if(start_data_count && (rec_cnt > CONF_DATA_CNT || rec_cnt == 0))
        rec_cnt <= 1;
    else if(rec_cnt != -1 && rec_cnt>0 && CONF_DATA_CNT!=0 )
        rec_cnt <= rec_cnt + 1;
end

wire DONE;
assign DONE  = rec_cnt > CONF_DATA_CNT;

reg cdc_fifo_write_single;

always@(*) begin
    if(CONF_DATA_CNT==0 && rec_cnt>=1) //forever
        cdc_fifo_write_single = 1;
    else if(rec_cnt>=1 && rec_cnt <= CONF_DATA_CNT) //to CONF_DATA_CNT
        cdc_fifo_write_single = 1;
    else
        cdc_fifo_write_single = 0;
end

reg [13:0] prev_data;
reg prev_sync;
reg prev_ready;

always@(posedge ADC_ENC) begin
    if(rst_adc_sync || start_adc_sync)
        prev_ready <= 0;
    else
        prev_ready <= !prev_ready;
end

//
reg [13:0] ADC_IN_DLY, adc_dly_mem;
reg [13:0] dly_mem [255:0];
reg [7:0] dly_addr_read,  dly_addr_write;

always@(posedge ADC_ENC)
    if(rst_adc_sync)
        dly_addr_write <= 0;
    else
        dly_addr_write <= dly_addr_write + 1;

always@(posedge ADC_ENC)
        dly_mem[dly_addr_write] <= ADC_IN;

always@(posedge ADC_ENC)
        adc_dly_mem <= dly_mem[dly_addr_read];

always@(*) begin
    dly_addr_read = dly_addr_write - CONF_SAMPEL_DLY;
    ADC_IN_DLY = CONF_SAMPEL_DLY == 0 ? ADC_IN : adc_dly_mem;
end     
//

always@(posedge ADC_ENC) begin
        prev_data <= ADC_IN_DLY;
        prev_sync <= ADC_SYNC;
end

wire fifo_full, cdc_fifo_empty, cdc_fifo_write_double;
assign cdc_fifo_write_double = cdc_fifo_write_single && prev_ready; //write every second

wire wfull;
reg cdc_fifo_write;

always@(posedge ADC_ENC) begin
    if(rst_adc_sync)
        CONF_ERROR_LOST <= 0;
    else if (CONF_ERROR_LOST!=8'hff && wfull && cdc_fifo_write)
        CONF_ERROR_LOST <= CONF_ERROR_LOST +1;
end

reg [31:0] data_to_fifo;
always@(*) begin
    if(CONF_SINGLE_DATA)
        data_to_fifo = {HEADER_ID, ADC_ID, CONF_EN_EX_TRIGGER ? rec_cnt == 1 : ADC_SYNC, 14'b0, ADC_IN_DLY};
    else
        data_to_fifo = {HEADER_ID, ADC_ID, prev_sync, prev_data, ADC_IN_DLY};

    if(CONF_SINGLE_DATA)
        cdc_fifo_write = cdc_fifo_write_single;
    else
        cdc_fifo_write = cdc_fifo_write_double;

end

wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(3)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(data_to_fifo), //.wdata({ADC_SYNC,2'd0,ADC_SYNC,14'd0,adc_des}),
    .winc(cdc_fifo_write), .wclk(ADC_ENC), .wrst(RST_LONG),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(RST_LONG)
);

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(1024))  fifo_i
( .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
    .write(!cdc_fifo_empty),
    .read(FIFO_READ), 
    .data_in(cdc_data_out), 
    .full(fifo_full), 
    .empty(FIFO_EMPTY), 
    .data_out(FIFO_DATA[31:0]), .size());

//assign FIFO_DATA[31:30]  = 0;

wire DONE_SYNC;
cdc_pulse_sync done_pulse_sync (.clk_in(ADC_ENC), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));

always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(START)
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;

endmodule
