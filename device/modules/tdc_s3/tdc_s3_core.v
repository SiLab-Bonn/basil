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
    parameter DATA_IDENTIFIER = 4'b0100
)(
    input CLK320,
    input CLK160,
    input CLK40,
    input TDC_IN,
    output TDC_OUT,

    input FIFO_READ,
    output FIFO_EMPTY,
    output [31:0] FIFO_DATA,

    input BUS_CLK,
    input [15:0] BUS_ADD,
    input [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input BUS_RST,
    input BUS_WR,
    input BUS_RD,

    input ARM_TDC // assuming slower than 48MHz
);

//output format #ID (4 bit DATA_IDENTIFIER (parameter) + 16 bit event counter + 12 bit TDC data) 

wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 


reg [7:0] status_regs[1:0];

wire CONF_EN; //ENABLE BUS_ADD==1 BIT==0
assign CONF_EN = status_regs[1][0];
wire CONF_EN_ARM_TDC; //ENABLE BUS_ADD==1 BIT==1
assign CONF_EN_ARM_TDC = status_regs[1][1];

reg [7:0] LOST_DATA_CNT; //BUS_ADD==2

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 8'b0;
        status_regs[1] <= 8'b0;
    end
    else if(BUS_WR && BUS_ADD < 2)
    begin
        status_regs[BUS_ADD[0]] <= BUS_DATA_IN;
    end
end

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if (BUS_ADD == 0)
            BUS_DATA_OUT <= status_regs[0];
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= status_regs[1];
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= LOST_DATA_CNT;
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

assign TDC_OUT = |DATA_IN;

reg [15:0] DATA_IN_SR;
always@(posedge CLK160)
    DATA_IN_SR[15:0] <= {DATA_IN_SR[11:0],DATA_IN[3:0]};

reg [15:0] DATA;
always@(posedge CLK40)
    DATA <= DATA_IN_SR;

wire ONE_DETECTED;
assign ONE_DETECTED = |DATA;

wire ZERO_DETECTED;
assign ZERO_DETECTED = |(~DATA);

wire RST_SYNC;
flag_domain_crossing cmd_rst_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(CLK40),
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


wire ARM_TDC_BUS_CLK;
three_stage_synchronizer three_stage_rj45_trigger_synchronizer_bus_clk (
    .CLK(BUS_CLK),
    .IN(ARM_TDC),
    .OUT(ARM_TDC_BUS_CLK)
);

wire ARM_TDC_CLK40;
flag_domain_crossing arm_tdc_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(CLK40),
    .FLAG_IN_CLK_A(ARM_TDC_BUS_CLK),
    .FLAG_OUT_CLK_B(ARM_TDC_CLK40)
);

wire CONF_EN_CLK40;
three_stage_synchronizer conf_en_three_stage_synchronizer_clk40 (
    .CLK(CLK40),
    .IN(CONF_EN),
    .OUT(CONF_EN_CLK40)
);

wire CONF_EN_ARM_TDC_CLK40;
three_stage_synchronizer conf_en_arm_three_stage_synchronizer_clk40 (
    .CLK(CLK40),
    .IN(CONF_EN_ARM_TDC),
    .OUT(CONF_EN_ARM_TDC_CLK40)
);

reg [1:0] state, next_state;
localparam      IDLE  = 2'b00,
                ARMED = 2'b01,
                COUNT = 2'b10;

always @ (posedge CLK40)
    if (RST_SYNC)
      state <= IDLE;
    else
      state <= next_state;

always @ (state or ONE_DETECTED or ZERO_DETECTED or CONF_EN_CLK40 or CONF_EN_ARM_TDC_CLK40 or ARM_TDC_CLK40) begin
    case(state)
        IDLE:
            if (ONE_DETECTED && CONF_EN_CLK40 && !CONF_EN_ARM_TDC_CLK40)
                next_state = COUNT;
            else if (ARM_TDC_CLK40 && CONF_EN_CLK40 && CONF_EN_ARM_TDC_CLK40)
                next_state = ARMED;
            else
                next_state = IDLE;

        ARMED:
            if (ONE_DETECTED)
                next_state = COUNT;
            else if (!CONF_EN_CLK40)
                next_state = IDLE;
            else
                next_state = ARMED;

        COUNT:
            if (ZERO_DETECTED)
                next_state = IDLE;
            else if (!CONF_EN_CLK40)
                next_state = IDLE;
            else
                next_state = COUNT;
        default : next_state = IDLE;
    endcase
end

wire FINISH;
assign FINISH = (state == COUNT && next_state == IDLE);
wire START;
assign START = ((state == IDLE && next_state == COUNT) || (state == ARMED && next_state == COUNT));

integer i;
reg [4:0] ONES;
always@(*) begin 
    ONES = 0;
    for(i=0;i<16;i=i+1) begin
        ONES = ONES + DATA[i];
    end
end

reg [11:0] TDC_PRE;
always @ (posedge CLK40)
    if(RST_SYNC)
        TDC_PRE <= 0;
    else if(START)
        TDC_PRE <= ONES;
    else if(state == COUNT)
        TDC_PRE <= TDC_PRE + ONES;

wire [11:0] TDC_VAL;
assign TDC_VAL = TDC_PRE + ONES;

reg [15:0] EVENT_CNT;
always @ (posedge CLK40)
    if(RST_SYNC)
        EVENT_CNT <= 0;
    else if (FINISH)
        EVENT_CNT <= EVENT_CNT +1;

wire wfull;
wire cdc_fifo_write;
assign cdc_fifo_write = !wfull && FINISH;

wire [31:0] cdc_data;
assign cdc_data = {DATA_IDENTIFIER, EVENT_CNT, TDC_VAL};

always@(posedge CLK40) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && cdc_fifo_write && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT +1;
end

wire fifo_full, cdc_fifo_empty;

wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write), .wclk(CLK40), .wrst(RST_LONG),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(RST_LONG)
);

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(1024))  fifo_i
( .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
    .write(!cdc_fifo_empty),
    .read(FIFO_READ), 
    .data_in(cdc_data_out), 
    .full(fifo_full), 
    .empty(FIFO_EMPTY), 
    .data_out(FIFO_DATA[31:0]), .size() 
);

endmodule
