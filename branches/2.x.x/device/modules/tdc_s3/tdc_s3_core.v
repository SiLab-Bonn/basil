/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SILAB , Physics Institute of Bonn University , All Right 
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $:
 *  $Date::                      $:
 */
 
module tdc_s3_core
#(
    parameter DATA_IDENTIFIER = 4'b0100,
    parameter CLKDV = 4
)(
    input wire CLK320,
    input wire CLK160,
    input wire DV_CLK,
    input wire TDC_IN, // pulse need to be longer than one cycle of CLK320, distance of pulses needs to be longer than one cycle of DV_CLK
    output wire TDC_OUT, // sampled with 320MHz, kept high for at least DV_CLK

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    input wire BUS_CLK,
    input wire [15:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    input wire ARM_TDC, // enable TDC for single measurement, assuming signal slower than DV_CLK
    input wire EXT_EN, // enable TDC for a fixed time period (signal needs to be asserted to enable TDC) e.g. for occupancy measurements, assuming signal slower than DV_CLK
    
    input wire [15:0] TIMESTAMP
);

// output format: 4-bit DATA_IDENTIFIER (parameter) + 16 bit event counter + 12 bit TDC data
// the TDC counter has a overflow bin: TDC value is 0 when an overflow occurs

wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR); 

wire RST;
assign RST = BUS_RST | SOFT_RST; 


reg [7:0] status_regs[1:0];

wire CONF_EN; // ENABLE BUS_ADD==1 BIT==0
assign CONF_EN = status_regs[1][0];
wire CONF_EN_EXT; // ENABLE EXTERN BUS_ADD==1 BIT==1
assign CONF_EN_EXT = status_regs[1][1];
wire CONF_EN_ARM_TDC; // BUS_ADD==1 BIT==2
assign CONF_EN_ARM_TDC = status_regs[1][2];
wire CONF_EN_WRITE_TS; // BUS_ADD==1 BIT==3
assign CONF_EN_WRITE_TS = status_regs[1][3];
reg [7:0] LOST_DATA_CNT, LOST_DATA_CNT_BUF; // BUS_ADD==0
reg [31:0] EVENT_CNT, EVENT_CNT_BUF; // BUS_ADD==2 - 3

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 8'b0;
        status_regs[1] <= 8'b0;
    end
    else if(BUS_WR && BUS_ADD < 2)
        status_regs[BUS_ADD[0]] <= BUS_DATA_IN;
end

localparam VERSION = 1;

always @(posedge BUS_CLK) begin
    if (BUS_ADD == 0)
        BUS_DATA_OUT <= VERSION;
    else if(BUS_ADD == 1)
        BUS_DATA_OUT <= status_regs[1];
    else if(BUS_ADD == 2)
        BUS_DATA_OUT <= EVENT_CNT_BUF[7:0];
    else if(BUS_ADD == 3)
        BUS_DATA_OUT <= EVENT_CNT_BUF[15:8];
    else if(BUS_ADD == 4)
        BUS_DATA_OUT <= EVENT_CNT_BUF[23:16];
    else if(BUS_ADD == 5)
        BUS_DATA_OUT <= EVENT_CNT_BUF[31:24];
    else if(BUS_ADD == 6)
        BUS_DATA_OUT <= LOST_DATA_CNT_BUF;
    else
        BUS_DATA_OUT <= 0;
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        LOST_DATA_CNT_BUF <= 8'b0;
    else
    begin
        if (BUS_ADD == 2)
            LOST_DATA_CNT_BUF <= LOST_DATA_CNT;
        else
            LOST_DATA_CNT_BUF <= LOST_DATA_CNT_BUF;
    end
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        EVENT_CNT_BUF <= 32'b0;
    else
    begin
        if (BUS_ADD == 2)
            EVENT_CNT_BUF <= EVENT_CNT;
        else
            EVENT_CNT_BUF <= EVENT_CNT_BUF;
    end
end

// 320MHz clock domain
// *** do not touch code below ***

wire [1:0] DDRQ;
IFDDRRSE IFDDRRSE_inst (
    .Q0(DDRQ[1]), // Posedge data output
    .Q1(DDRQ[0]), // Negedge data output
    .C0(CLK320), // 0 degree clock input
    .C1(~CLK320), // 180 degree clock input
    .CE(1'b1), // Clock enable input
    .D(TDC_IN), // Data input (connect directly to top-level port)
    .R(1'b0), // Synchronous reset input
    .S(1'b0) // Synchronous preset input
);

reg [1:0] DDRQ_DLY;

always@(posedge CLK320)
    DDRQ_DLY[1:0] <= DDRQ[1:0];

reg [3:0] DDRQ_DATA;
always@(posedge CLK320)
    DDRQ_DATA[3:0] <= {DDRQ_DLY[1:0], DDRQ[1:0]};

// *** do not touch code above ***

reg [3:0] DATA_IN;
always@(posedge CLK160)
    DATA_IN[3:0] <= {DDRQ_DATA[3:0]};


reg [CLKDV*4-1:0] DATA_IN_SR;
always@(posedge CLK160)
    DATA_IN_SR <= {DATA_IN_SR[CLKDV*4-5:0],DATA_IN[3:0]};

reg [CLKDV*4-1:0] DATA;
always@(posedge DV_CLK)
    DATA <= DATA_IN_SR;

assign TDC_OUT = |DATA;
    
wire ONE_DETECTED;
assign ONE_DETECTED = |DATA; // asserted when one or more 1 occur

wire ZERO_DETECTED;
assign ZERO_DETECTED = |(~DATA); // asserted when one or more 0 occur

wire SMALL_TOT;
assign SMALL_TOT = ONE_DETECTED && (DATA[0]==0);

wire RST_SYNC;
flag_domain_crossing cmd_rst_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(DV_CLK),
    .FLAG_IN_CLK_A(RST),
    .FLAG_OUT_CLK_B(RST_SYNC)
);

reg [7:0] sync_cnt;
always@(posedge BUS_CLK) begin
    if(RST)
        sync_cnt <= 120;
    else if(sync_cnt != 100)
        sync_cnt <= sync_cnt +1;
end 

wire RST_LONG;
assign RST_LONG = sync_cnt[7];

wire CONF_EN_DV_CLK;

three_stage_synchronizer conf_en_three_stage_synchronizer_DV_CLK (
    .CLK(DV_CLK),
    .IN(CONF_EN | (CONF_EN_EXT & EXT_EN)),
    .OUT(CONF_EN_DV_CLK)
);

wire ARM_TDC_CLK160;
three_stage_synchronizer three_stage_rj45_trigger_synchronizer_bus_clk (
    .CLK(CLK160),
    .IN(ARM_TDC),
    .OUT(ARM_TDC_CLK160)
);

reg ARM_TDC_CLK160_FF;
always@(posedge CLK160) begin
    ARM_TDC_CLK160_FF <= ARM_TDC_CLK160;
end

wire ARM_TDC_FLAG_CLK160;
assign ARM_TDC_FLAG_CLK160 = ~ARM_TDC_CLK160_FF & ARM_TDC_CLK160;

wire ARM_TDC_FLAG_DV_CLK;
flag_domain_crossing arm_tdc_flag_domain_crossing (
    .CLK_A(CLK160),
    .CLK_B(DV_CLK),
    .FLAG_IN_CLK_A(ARM_TDC_FLAG_CLK160),
    .FLAG_OUT_CLK_B(ARM_TDC_FLAG_DV_CLK)
);

wire CONF_EN_ARM_TDC_DV_CLK;
three_stage_synchronizer conf_en_arm_three_stage_synchronizer_DV_CLK (
    .CLK(DV_CLK),
    .IN(CONF_EN_ARM_TDC),
    .OUT(CONF_EN_ARM_TDC_DV_CLK)
);

reg [1:0] state, next_state;
localparam      IDLE  = 2'b00,
                ARMED = 2'b01,
                COUNT = 2'b10;

always @ (posedge DV_CLK)
    if (RST_SYNC)
      state <= IDLE;
    else
      state <= next_state;

always @ (*) begin
    case(state)
        IDLE:
            if (ONE_DETECTED && CONF_EN_DV_CLK && !CONF_EN_ARM_TDC_DV_CLK && !SMALL_TOT)
                next_state = COUNT;
            else if (ARM_TDC_FLAG_DV_CLK && CONF_EN_DV_CLK && CONF_EN_ARM_TDC_DV_CLK)
                next_state = ARMED;
            else
                next_state = IDLE;

        ARMED:
            if (ONE_DETECTED && !SMALL_TOT)
                next_state = COUNT;
            else if (!CONF_EN_DV_CLK || SMALL_TOT) // return here to idle when small ToT detected
                next_state = IDLE;
            else
                next_state = ARMED;

        COUNT:
            if (ZERO_DETECTED)
                next_state = IDLE;
            else if (!CONF_EN_DV_CLK)
                next_state = IDLE;
            else
                next_state = COUNT;
        default : next_state = IDLE;
    endcase
end

wire FINISH;
assign FINISH = (state == COUNT && next_state == IDLE) || (state == IDLE && SMALL_TOT && CONF_EN_DV_CLK && !CONF_EN_ARM_TDC_DV_CLK) || (state == ARMED && SMALL_TOT && CONF_EN_DV_CLK);

wire START;
assign START = ((state == IDLE && next_state == COUNT) || (state == ARMED && next_state == COUNT));

reg [15:0] CURR_TIMESTAMP;
always @ (posedge DV_CLK)
    if (RST_SYNC)
        CURR_TIMESTAMP <= 16'b0;
    else
        if (START)
            CURR_TIMESTAMP <= TIMESTAMP;
        else if (FINISH && state == IDLE)
            CURR_TIMESTAMP <= TIMESTAMP;

integer i;
integer ONES;
always@(*) begin 
    ONES = 0;
    for(i=0; i<CLKDV*4; i=i+1) begin
        ONES = ONES + DATA[i];
    end
end

reg [12:0] TDC_PRE; // overflow bit
always @ (posedge DV_CLK)
    if(RST_SYNC)
        TDC_PRE <= 0;
    else if(START)
        TDC_PRE <= ONES;
    else if(state == COUNT && (TDC_PRE + ONES > 13'b0_1111_1111_1111 || TDC_PRE == 13'b0))
        TDC_PRE <= 13'b0; // overflow!
    else if(state == COUNT)
        TDC_PRE <= TDC_PRE + ONES;

wire [11:0] TDC_VAL;
// also check here for overflow
assign TDC_VAL = ((state == IDLE && SMALL_TOT && CONF_EN_DV_CLK) || (state == ARMED && SMALL_TOT && CONF_EN_DV_CLK)) ? ONES : (TDC_PRE + ONES < 13'b1_0000_0000_0000 && TDC_PRE != 13'b0) ? TDC_PRE + ONES : 12'b0;

always @ (posedge DV_CLK)
    if(RST_SYNC)
        EVENT_CNT <= 0;
    else if (FINISH)
        EVENT_CNT <= EVENT_CNT + 1;

wire wfull;
wire cdc_fifo_write;
assign cdc_fifo_write = !wfull && FINISH;

wire [31:0] cdc_data;
assign cdc_data = (CONF_EN_WRITE_TS) ? {DATA_IDENTIFIER, CURR_TIMESTAMP, TDC_VAL} : {DATA_IDENTIFIER, EVENT_CNT[15:0], TDC_VAL};

always@(posedge DV_CLK) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && FINISH && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT + 1;
end

wire fifo_full, cdc_fifo_empty;

wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write), .wclk(DV_CLK), .wrst(RST_LONG),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(RST_LONG)
);

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(512))  fifo_i
(
    .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
    .write(!cdc_fifo_empty),
    .read(FIFO_READ), 
    .data_in(cdc_data_out), 
    .full(fifo_full), 
    .empty(FIFO_EMPTY), 
    .data_out(FIFO_DATA[31:0]), .size() 
);

endmodule
