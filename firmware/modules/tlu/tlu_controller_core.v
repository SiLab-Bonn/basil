/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

 /*  _____ _   _   _
 * |_   _| | | | | |
 *   | | | |_| |_| |
 *   |_| |___|\___/
 *
 * TLU controller supporting EUDET TLU 0.1/0.2
 */

module tlu_controller_core
#(
    parameter                   ABUSWIDTH = 16,
    parameter                   DIVISOR = 8, // dividing TRIGGER_CLK by DIVISOR for TLU_CLOCK
    parameter                   TLU_TRIGGER_MAX_CLOCK_CYCLES = 17 // bit length of trigger data always TLU_TRIGGER_MAX_CLOCK_CYCLES - 1
)
(
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire [ABUSWIDTH-1:0]  BUS_ADD,
    input wire      [7:0]       BUS_DATA_IN,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    output reg      [7:0]       BUS_DATA_OUT,

    input wire                  TRIGGER_CLK, // clock of the TLU FSM

    input wire                  FIFO_READ,
    output wire                 FIFO_EMPTY,
    output wire     [31:0]      FIFO_DATA,

    output reg                  FIFO_PREEMPT_REQ, // FIFO hold request

    input wire      [7:0]       TRIGGER, // trigger input
    input wire      [7:0]       TRIGGER_VETO, // veto input

    input wire                  EXT_TRIGGER_ENABLE, // enable trigger FSM
    input wire                  TRIGGER_ACKNOWLEDGE, // acknowledge signal/flag
    output wire                 TRIGGER_ACCEPTED_FLAG, // trigger start flag

    input wire                  TLU_TRIGGER, // TLU
    input wire                  TLU_RESET,
    output wire                 TLU_BUSY,
    output wire                 TLU_CLOCK,

    output wire     [31:0]      TIMESTAMP
);

localparam VERSION = 8;

// Registers
wire SOFT_RST; // Address: 0
assign SOFT_RST = (BUS_ADD == 0 && BUS_WR);

// reset sync
// when writing to addr = 0 then reset
reg RST_FF, RST_FF2, BUS_RST_FF, BUS_RST_FF2;
always @(posedge BUS_CLK) begin
    RST_FF <= SOFT_RST;
    RST_FF2 <= RST_FF;
    BUS_RST_FF <= BUS_RST;
    BUS_RST_FF2 <= BUS_RST_FF;
end

wire SOFT_RST_FLAG;
assign SOFT_RST_FLAG = ~RST_FF2 & RST_FF;
wire BUS_RST_FLAG;
assign BUS_RST_FLAG = BUS_RST_FF2 & ~BUS_RST_FF; // trailing edge
wire RST;
assign RST = BUS_RST_FLAG | SOFT_RST_FLAG;

wire RST_SYNC;
flag_domain_crossing rst_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(TRIGGER_CLK),
    .FLAG_IN_CLK_A(RST),
    .FLAG_OUT_CLK_B(RST_SYNC)
);

reg [7:0] status_regs[31:0];

// reg 0 for SOFT_RST
wire [1:0] TRIGGER_MODE; // 2'b00 - standard trigger, 2'b01 - TLU no handshake, 2'b10 - TLU simple handshake, 2'b11 - TLU trigger data handshake
assign TRIGGER_MODE = status_regs[1][1:0];
wire TLU_TRIGGER_DATA_MSB_FIRST; // set endianness of TLU number
assign TLU_TRIGGER_DATA_MSB_FIRST = status_regs[1][2];
wire CONF_TRIGGER_ENABLE;
assign CONF_TRIGGER_ENABLE = status_regs[1][3];
wire [3:0] TLU_TRIGGER_DATA_DELAY;
assign TLU_TRIGGER_DATA_DELAY = status_regs[1][7:4];
wire [1:0] CONF_DATA_FORMAT;
assign CONF_DATA_FORMAT = status_regs[2][1:0];
wire TLU_ENABLE_RESET_TS;
assign TLU_ENABLE_RESET_TS = status_regs[2][5];
wire TLU_ENABLE_VETO;
assign TLU_ENABLE_VETO = status_regs[2][6];
wire [7:0] TLU_TRIGGER_LOW_TIME_OUT;
assign TLU_TRIGGER_LOW_TIME_OUT = status_regs[3];
wire [7:0] TRIGGER_SELECT;
assign TRIGGER_SELECT = status_regs[13];
wire [7:0] VETO_SELECT;
assign VETO_SELECT = status_regs[14];
wire [7:0] TRIGGER_INVERT;
assign TRIGGER_INVERT = status_regs[15];
wire [31:0] TRIGGER_COUNTER_MAX;
assign TRIGGER_COUNTER_MAX = {status_regs[19], status_regs[18], status_regs[17], status_regs[16]};
wire [7:0] CONF_TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES;
assign CONF_TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES = status_regs[20];
wire [7:0] CONF_TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES;
assign CONF_TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES = status_regs[21];
wire [7:0] CONF_TRIGGER_THRESHOLD;
assign CONF_TRIGGER_THRESHOLD = status_regs[24];

always @(posedge BUS_CLK)
begin
    if(RST)
    begin
        status_regs[0] <= 8'b0;
        status_regs[1] <= 8'b0;
        status_regs[2] <= 8'b0;
        status_regs[3] <= 8'b1111_1111;
        status_regs[4] <= 8'b0; // TLU trigger number
        status_regs[5] <= 8'b0;
        status_regs[6] <= 8'b0;
        status_regs[7] <= 8'b0;
        status_regs[8] <= 8'b0; // trigger counter
        status_regs[9] <= 8'b0;
        status_regs[10] <= 8'b0;
        status_regs[11] <= 8'b0;
        status_regs[12] <= 8'b0; // lost data counter
        status_regs[13] <= 8'b0; // trigger select
        status_regs[14] <= 8'b0; // veto select
        status_regs[15] <= 8'b0; // trigger invert
        status_regs[16] <= 8'b0; // max. trigger counter
        status_regs[17] <= 8'b0;
        status_regs[18] <= 8'b0;
        status_regs[19] <= 8'b0;
        status_regs[20] <= 8'd3; // TLU trigger high accept clock cycles
        status_regs[21] <= 8'b0; // TLU busy low to veto high wait cycles
        status_regs[22] <= 8'b0; // trigger low timeout error
        status_regs[23] <= 8'b0; // trigger accept error
        status_regs[24] <= 8'b0; // trigger threshold
    end
    else if(BUS_WR && BUS_ADD < 25)
    begin
        status_regs[BUS_ADD[4:0]] <= BUS_DATA_IN;
    end
end

// read reg
reg [7:0] LOST_DATA_CNT; // BUS_ADD==0
reg [31:0] CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK, CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK_BUF; // BUS_ADD==4 - 7
reg [31:0] TRIGGER_COUNTER, TRIGGER_COUNTER_BUF; // BUS_ADD==8 - 11
reg [7:0] TLU_TRIGGER_LOW_TIMEOUT_ERROR_CNT;
reg [7:0] TLU_TRIGGER_ACCEPT_ERROR_CNT;

always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        if (BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if (BUS_ADD == 1)
            BUS_DATA_OUT <= status_regs[1];
        else if (BUS_ADD == 2)
            BUS_DATA_OUT <= status_regs[2];
        else if (BUS_ADD == 3)
            BUS_DATA_OUT <= status_regs[3];
        else if (BUS_ADD == 4)
            BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK[7:0];
        else if (BUS_ADD == 5)
            BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK_BUF[15:8];
        else if (BUS_ADD == 6)
            BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK_BUF[23:16];
        else if (BUS_ADD == 7)
            BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK_BUF[31:24];
        else if (BUS_ADD == 8)
            BUS_DATA_OUT <= TRIGGER_COUNTER[7:0];
        else if (BUS_ADD == 9)
            BUS_DATA_OUT <= TRIGGER_COUNTER_BUF[15:8];
        else if (BUS_ADD == 10)
            BUS_DATA_OUT <= TRIGGER_COUNTER_BUF[23:16];
        else if (BUS_ADD == 11)
            BUS_DATA_OUT <= TRIGGER_COUNTER_BUF[31:24];
        else if (BUS_ADD == 12)
            BUS_DATA_OUT <= LOST_DATA_CNT;
        else if (BUS_ADD == 13)
            BUS_DATA_OUT <= status_regs[13];
        else if (BUS_ADD == 14)
            BUS_DATA_OUT <= status_regs[14];
        else if (BUS_ADD == 15)
            BUS_DATA_OUT <= status_regs[15];
        else if (BUS_ADD == 16)
            BUS_DATA_OUT <= status_regs[16];
        else if (BUS_ADD == 17)
            BUS_DATA_OUT <= status_regs[17];
        else if (BUS_ADD == 18)
            BUS_DATA_OUT <= status_regs[18];
        else if (BUS_ADD == 19)
            BUS_DATA_OUT <= status_regs[19];
        else if (BUS_ADD == 20)
            BUS_DATA_OUT <= status_regs[20];
        else if (BUS_ADD == 21)
            BUS_DATA_OUT <= status_regs[21];
        else if (BUS_ADD == 22)
            BUS_DATA_OUT <= TLU_TRIGGER_LOW_TIMEOUT_ERROR_CNT;
        else if (BUS_ADD == 23)
            BUS_DATA_OUT <= TLU_TRIGGER_ACCEPT_ERROR_CNT;
        else if (BUS_ADD == 24)
            BUS_DATA_OUT <= status_regs[24];
        else
            BUS_DATA_OUT <= 0;
    end
end

//assign some_value = (BUS_ADD==x && BUS_WR);
//assign some_value = status_regs[x]; // single reg
//assign some_value = {status_regs[x], status_regs[y]}; // multiple regs, specific order
//assign some_value = {status_regs[x:y]}; // multiple regs
//assign some_value = {status_regs[x][y]}; // single bit
//assign some_value = {status_regs[x][y:z]}; // multiple bits

// register sync
wire [1:0] TRIGGER_MODE_SYNC;
three_stage_synchronizer #(
    .WIDTH(2)
) three_stage_tlu_mode_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(TRIGGER_MODE),
    .OUT(TRIGGER_MODE_SYNC)
);

wire [7:0] TLU_TRIGGER_LOW_TIME_OUT_SYNC;
three_stage_synchronizer #(
    .WIDTH(8)
) three_stage_trigger_low_timeout_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(TLU_TRIGGER_LOW_TIME_OUT),
    .OUT(TLU_TRIGGER_LOW_TIME_OUT_SYNC)
);

/*
wire [4:0] TLU_TRIGGER_CLOCK_CYCLES_SYNC;
three_stage_synchronizer #(
    .WIDTH(5)
) three_stage_trigger_clock_cycles_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(TLU_TRIGGER_CLOCK_CYCLES),
    .OUT(TLU_TRIGGER_CLOCK_CYCLES_SYNC)
);
*/

wire [3:0] TLU_TRIGGER_DATA_DELAY_SYNC;
three_stage_synchronizer #(
    .WIDTH(4)
) three_stage_trigger_data_delay_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(TLU_TRIGGER_DATA_DELAY),
    .OUT(TLU_TRIGGER_DATA_DELAY_SYNC)
);

wire TLU_TRIGGER_DATA_MSB_FIRST_SYNC;
three_stage_synchronizer three_stage_trigger_data_msb_first_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(TLU_TRIGGER_DATA_MSB_FIRST),
    .OUT(TLU_TRIGGER_DATA_MSB_FIRST_SYNC)
);

wire CONF_TRIGGER_ENABLE_SYNC;
three_stage_synchronizer three_stage_conf_trigger_enable_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(CONF_TRIGGER_ENABLE),
    .OUT(CONF_TRIGGER_ENABLE_SYNC)
);

wire TLU_ENABLE_VETO_SYNC;
three_stage_synchronizer three_stage_tlu_en_veto_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(TLU_ENABLE_VETO),
    .OUT(TLU_ENABLE_VETO_SYNC)
);

wire TLU_ENABLE_RESET_TS_SYNC;
three_stage_synchronizer three_stage_enable_tlu_reset_ts_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(TLU_ENABLE_RESET_TS),
    .OUT(TLU_ENABLE_RESET_TS_SYNC)
);

// TLU input sync
wire TLU_TRIGGER_SYNC, TRIGGER_OR_SYNC, TLU_RESET_SYNC, TRIGGER_VETO_OR_SYNC;

three_stage_synchronizer three_stage_rj45_trigger_synchronizer_trg_clk (
    .CLK(TRIGGER_CLK),
    .IN(TLU_TRIGGER),
    .OUT(TLU_TRIGGER_SYNC)
);

wire [7:0] TRIGGER_XOR_INVERT;
wire TRIGGER_OR;
assign TRIGGER_XOR_INVERT = TRIGGER ^ TRIGGER_INVERT;
assign TRIGGER_OR = |(TRIGGER_XOR_INVERT & TRIGGER_SELECT);

three_stage_synchronizer three_stage_lemo_trigger_synchronizer_trg_clk (
    .CLK(TRIGGER_CLK),
    .IN(TRIGGER_OR),
    .OUT(TRIGGER_OR_SYNC)
);

three_stage_synchronizer three_stage_rj45_reset_synchronizer_trg_clk (
    .CLK(TRIGGER_CLK),
    .IN(TLU_RESET),
    .OUT(TLU_RESET_SYNC)
);

wire TRIGGER_VETO_OR;
assign TRIGGER_VETO_OR = |(TRIGGER_VETO & VETO_SELECT);

three_stage_synchronizer three_stage_lemo_ext_veto_synchronizer_trg_clk (
    .CLK(TRIGGER_CLK),
    .IN(TRIGGER_VETO_OR),
    .OUT(TRIGGER_VETO_OR_SYNC)
);

wire [7:0] CONF_TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES_SYNC;
three_stage_synchronizer #(
    .WIDTH(8)
) three_stage_handshake_accept_wait_cycles_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(CONF_TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES),
    .OUT(CONF_TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES_SYNC)
);

wire [7:0] CONF_TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES_SYNC;
three_stage_synchronizer #(
    .WIDTH(8)
) three_stage_busy_veto_wait_cycles_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(CONF_TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES),
    .OUT(CONF_TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES_SYNC)
);

wire [7:0] CONF_TRIGGER_THRESHOLD_SYNC;
three_stage_synchronizer #(
    .WIDTH(8)
) three_stage_trigger_threshold_synchronizer (
    .CLK(TRIGGER_CLK),
    .IN(CONF_TRIGGER_THRESHOLD),
    .OUT(CONF_TRIGGER_THRESHOLD_SYNC)
);

// output sync
// nothing to do here

// TLU clock (not a real clock ...)
wire TLU_ASSERT_VETO, TLU_CLOCK_ENABLE;
integer counter_clk;

reg TLU_ASSERT_VETO_FF;
always @ (posedge TRIGGER_CLK)
    TLU_ASSERT_VETO_FF <= TLU_ASSERT_VETO;

wire TLU_ASSERT_VETO_LE;
assign TLU_ASSERT_VETO_LE = ~TLU_ASSERT_VETO_FF & TLU_ASSERT_VETO;
wire TLU_ASSERT_VETO_TE;
assign TLU_ASSERT_VETO_TE = TLU_ASSERT_VETO_FF & ~TLU_ASSERT_VETO;

reg TLU_VETO;
//always @ (RST_SYNC or TRIGGER_ACCEPTED_FLAG or TLU_ASSERT_VETO_TE or TLU_ASSERT_VETO_LE)
//begin
//    if (RST_SYNC)
//        TLU_VETO <= 1'b0;
//    if (TRIGGER_ACCEPTED_FLAG)
//        TLU_VETO <= 1'b0;
//    else if (TLU_ASSERT_VETO_TE)
//        TLU_VETO <= 1'b0;
//    else if (TLU_ASSERT_VETO_LE)
//        TLU_VETO <= 1'b1;
//end
always @ (posedge TRIGGER_CLK)
begin
    if (RST_SYNC)
        TLU_VETO <= 1'b0;
    if (TRIGGER_ACCEPTED_FLAG)
        TLU_VETO <= 1'b0;
    else if (TLU_ASSERT_VETO_TE)
        TLU_VETO <= 1'b0;
    else if (TLU_ASSERT_VETO_LE)
        TLU_VETO <= 1'b1;
end

reg TLU_CLOCK_SIGNAL;
always @ (posedge TRIGGER_CLK)
begin
    if (RST_SYNC)
        TLU_CLOCK_SIGNAL <= 1'b0;
    else
        if (TLU_CLOCK_ENABLE)
            if (counter_clk == 0)
                TLU_CLOCK_SIGNAL <= ~TLU_CLOCK_SIGNAL;
            else
                TLU_CLOCK_SIGNAL <= TLU_CLOCK_SIGNAL;
        else
            TLU_CLOCK_SIGNAL <= 1'b0;
end
assign TLU_CLOCK = TLU_CLOCK_SIGNAL | TLU_VETO;

always @ (posedge TRIGGER_CLK)
begin
    if (RST_SYNC)
        counter_clk <= 0;
    else
    begin
        if (TLU_CLOCK_ENABLE)
        begin
            if (counter_clk == ((DIVISOR >> 1) - 1))
                counter_clk <= 0;
            else
                counter_clk <= counter_clk + 1;
        end
        else
            counter_clk <= 0;
    end
end

wire TRIGGER_FSM;
assign TRIGGER_FSM = (TRIGGER_MODE != 2'b00) ? TLU_TRIGGER_SYNC : TRIGGER_OR_SYNC; // RJ45 inputs tied to 1 if no connector is plugged in

// Reset flag
reg TLU_RESET_SYNC_FF;
always @ (posedge TRIGGER_CLK)
    TLU_RESET_SYNC_FF <= TLU_RESET_SYNC;

wire TLU_RESET_FLAG_SYNC;
assign TLU_RESET_FLAG_SYNC = ~TLU_RESET_SYNC_FF & TLU_RESET_SYNC & TLU_ENABLE_RESET_TS_SYNC;

// writing current TLU trigger number to register
reg [31:0] CURRENT_TLU_TRIGGER_NUMBER_SYNC;
wire [31:0] TLU_TRIGGER_NUMBER_DATA;
wire TRIGGER_DATA_WRITE;
always @ (posedge TRIGGER_CLK)
begin
    if (RST_SYNC)
        CURRENT_TLU_TRIGGER_NUMBER_SYNC <= 32'b0;
    else if (TRIGGER_DATA_WRITE == 1'b1)
        CURRENT_TLU_TRIGGER_NUMBER_SYNC <= TLU_TRIGGER_NUMBER_DATA;
end

wire TRIGGER_DATA_WRITE_BUS_CLK;
flag_domain_crossing trigger_data_write_flag_domain_crossing (
    .CLK_A(TRIGGER_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(TRIGGER_DATA_WRITE),
    .FLAG_OUT_CLK_B(TRIGGER_DATA_WRITE_BUS_CLK)
);

always @ (posedge BUS_CLK)
begin
    if (RST)
        CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK <= 32'b0;
    else if (TRIGGER_DATA_WRITE_BUS_CLK == 1'b1)
        CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK <= CURRENT_TLU_TRIGGER_NUMBER_SYNC;
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK_BUF <= 32'b0;
    else if (BUS_ADD == 4 && BUS_RD)
        CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK_BUF <= CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK;
end

wire TRIGGER_ACCEPTED_FLAG_BUS_CLK;
flag_domain_crossing trigger_accepted_flag_domain_crossing (
    .CLK_A(TRIGGER_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(TRIGGER_ACCEPTED_FLAG),
    .FLAG_OUT_CLK_B(TRIGGER_ACCEPTED_FLAG_BUS_CLK)
);

wire TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG, TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG_BUS_CLK;
flag_domain_crossing trigger_low_timeout_error_flag_domain_crossing (
    .CLK_A(TRIGGER_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG),
    .FLAG_OUT_CLK_B(TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG_BUS_CLK)
);

always @ (posedge BUS_CLK)
begin
    if (RST)
        TLU_TRIGGER_LOW_TIMEOUT_ERROR_CNT <= 8'b0;
    else if (TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG_BUS_CLK == 1'b1 && TLU_TRIGGER_LOW_TIMEOUT_ERROR_CNT != -1)
        TLU_TRIGGER_LOW_TIMEOUT_ERROR_CNT <= TLU_TRIGGER_LOW_TIMEOUT_ERROR_CNT + 1;
end

wire TLU_TRIGGER_ACCEPT_ERROR_FLAG, TLU_TRIGGER_ACCEPT_ERROR_FLAG_BUS_CLK;
flag_domain_crossing trigger_accept_error_flag_domain_crossing (
    .CLK_A(TRIGGER_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(TLU_TRIGGER_ACCEPT_ERROR_FLAG),
    .FLAG_OUT_CLK_B(TLU_TRIGGER_ACCEPT_ERROR_FLAG_BUS_CLK)
);

always @ (posedge BUS_CLK)
begin
    if (RST)
        TLU_TRIGGER_ACCEPT_ERROR_CNT <= 8'b0;
    else if (TLU_TRIGGER_ACCEPT_ERROR_FLAG_BUS_CLK == 1'b1 && TLU_TRIGGER_ACCEPT_ERROR_CNT != -1)
        TLU_TRIGGER_ACCEPT_ERROR_CNT <= TLU_TRIGGER_ACCEPT_ERROR_CNT + 1;
end

wire TRIGGER_COUNTER_SET;
reg TRIGGER_COUNTER_SET_FF;
assign TRIGGER_COUNTER_SET = (BUS_ADD == 11 && BUS_WR);

always @ (posedge BUS_CLK)
begin
    TRIGGER_COUNTER_SET_FF <= TRIGGER_COUNTER_SET;
end
//wire TRIGGER_COUNTER_SET_FLAG;
//assign TRIGGER_COUNTER_SET_FLAG = ~TRIGGER_COUNTER_SET_FF & TRIGGER_COUNTER_SET;

wire TRIGGER_COUNTER_SET_FLAG_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(TRIGGER_COUNTER_SET_FF), .clk_out(TRIGGER_CLK), .pulse_out(TRIGGER_COUNTER_SET_FLAG_SYNC));

always @ (posedge BUS_CLK)
begin
    if (RST)
        TRIGGER_COUNTER <= 32'b0;
    else if (TRIGGER_COUNTER_SET)
        TRIGGER_COUNTER <= {BUS_DATA_IN, status_regs[10], status_regs[9], status_regs[8]};
    else if (TRIGGER_ACCEPTED_FLAG_BUS_CLK == 1'b1)
        TRIGGER_COUNTER <= TRIGGER_COUNTER + 1;
    //else if (ENABLE_TLU_FLAG_BUS_CLK == 1'b1)
    //    TRIGGER_COUNTER <= 32'b0;
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        TRIGGER_COUNTER <= 32'b0;
    else if (TRIGGER_COUNTER_SET)
        TRIGGER_COUNTER <= {BUS_DATA_IN, status_regs[10], status_regs[9], status_regs[8]};
    else if (TRIGGER_ACCEPTED_FLAG_BUS_CLK == 1'b1)
        TRIGGER_COUNTER <= TRIGGER_COUNTER + 1;
    //else if (ENABLE_TLU_FLAG_BUS_CLK == 1'b1)
    //    TRIGGER_COUNTER <= 32'b0;
end

// return TRIGGER_ACCEPTED_FLAG to the FSM when TRIGGER_ACKNOWLEDGE is not provided externally
wire TRIGGER_ACKNOWLEDGE_FSM;
assign TRIGGER_ACKNOWLEDGE_FSM = (EXT_TRIGGER_ENABLE == 1'b1) ? TRIGGER_ACKNOWLEDGE : TRIGGER_ACCEPTED_FLAG;

reg TRIGGER_LIMIT_REACHED;
always @ (posedge BUS_CLK)
begin
    if (RST)
        TRIGGER_LIMIT_REACHED <= 1'b0;
    else if (TRIGGER_COUNTER >= TRIGGER_COUNTER_MAX && TRIGGER_COUNTER_MAX != 32'b0)
        TRIGGER_LIMIT_REACHED <= 1'b1;
    else
        TRIGGER_LIMIT_REACHED <= 1'b0;
end

wire TRIGGER_LIMIT_REACHED_SYNC;
three_stage_synchronizer three_stage_trigger_limit_synchronizer_trigger_clk (
    .CLK(TRIGGER_CLK),
    .IN(TRIGGER_LIMIT_REACHED),
    .OUT(TRIGGER_LIMIT_REACHED_SYNC)
);

reg TRIGGER_ENABLE_FSM;
always @ (posedge TRIGGER_CLK)
begin
    if (RST_SYNC)
        TRIGGER_ENABLE_FSM <= 1'b0;
    else if ((EXT_TRIGGER_ENABLE == 1'b1 || CONF_TRIGGER_ENABLE_SYNC == 1'b1) && !TRIGGER_LIMIT_REACHED_SYNC)
        TRIGGER_ENABLE_FSM <= 1'b1;
    else
        TRIGGER_ENABLE_FSM <= 1'b0;
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        TRIGGER_COUNTER_BUF <= 32'b0;
    else if (BUS_ADD == 8 && BUS_RD)
        TRIGGER_COUNTER_BUF <= TRIGGER_COUNTER;
end

wire FIFO_PREEMPT_REQ_TRIGGER_CLK, FIFO_PREEMPT_REQ_BUS_CLK;
three_stage_synchronizer three_stage_fifo_preempt_req_synchronizer (
    .CLK(BUS_CLK),
    .IN(FIFO_PREEMPT_REQ_TRIGGER_CLK),
    .OUT(FIFO_PREEMPT_REQ_BUS_CLK)
);

reg FIFO_PREEMPT_REQ_BUS_CLK_FF;
always @ (posedge BUS_CLK)
    FIFO_PREEMPT_REQ_BUS_CLK_FF <= FIFO_PREEMPT_REQ_BUS_CLK;

wire FIFO_PREEMPT_REQ_LE_BUS_CLK;
assign FIFO_PREEMPT_REQ_LE_BUS_CLK = ~FIFO_PREEMPT_REQ_BUS_CLK_FF & FIFO_PREEMPT_REQ_BUS_CLK;
wire FIFO_PREEMPT_REQ_TE_BUS_CLK;
assign FIFO_PREEMPT_REQ_TE_BUS_CLK = FIFO_PREEMPT_REQ_BUS_CLK_FF & ~FIFO_PREEMPT_REQ_BUS_CLK;

reg FIFO_EMPTY_FF;
always @ (posedge BUS_CLK)
    FIFO_EMPTY_FF <= FIFO_EMPTY;

wire FIFO_EMPTY_FLAG_BUS_CLK;
assign FIFO_EMPTY_FLAG_BUS_CLK = ~FIFO_EMPTY_FF & FIFO_EMPTY; // assert flag when FIFO is empty again

wire FIFO_EMPTY_FLAG;
flag_domain_crossing fifo_preempt_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(TRIGGER_CLK),
    .FLAG_IN_CLK_A(FIFO_EMPTY_FLAG_BUS_CLK),
    .FLAG_OUT_CLK_B(FIFO_EMPTY_FLAG)
);

// 8 to 10 clock cycles after trigger (depending on TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES)
always @ (posedge BUS_CLK) begin
    if (RST)
        FIFO_PREEMPT_REQ <= 1'b0;
    else
        if (FIFO_EMPTY_FLAG_BUS_CLK)
            FIFO_PREEMPT_REQ <= 1'b0;
        else if (FIFO_PREEMPT_REQ_TE_BUS_CLK == 1'b1)
            FIFO_PREEMPT_REQ <= 1'b0;
        else if (FIFO_PREEMPT_REQ_LE_BUS_CLK == 1'b1)
            FIFO_PREEMPT_REQ <= 1'b1; // needs to be delayed by 1 clock cycle, otherwise it will not work
end

// TLU FSM

wire [31:0] TRIGGER_DATA;
tlu_controller_fsm #(
    .DIVISOR(DIVISOR),
    .TLU_TRIGGER_MAX_CLOCK_CYCLES(TLU_TRIGGER_MAX_CLOCK_CYCLES)
) tlu_controller_fsm_inst (
    .RESET(RST_SYNC),
    .TRIGGER_CLK(TRIGGER_CLK),

    .TRIGGER_DATA_WRITE(TRIGGER_DATA_WRITE),
    .TRIGGER_DATA(TRIGGER_DATA),

    .FIFO_PREEMPT_REQ(FIFO_PREEMPT_REQ_TRIGGER_CLK),
    .FIFO_ACKNOWLEDGE(FIFO_EMPTY_FLAG),

    .TIMESTAMP(TIMESTAMP),
    .TIMESTAMP_DATA(),
    .TLU_TRIGGER_NUMBER_DATA(TLU_TRIGGER_NUMBER_DATA),

    .TRIGGER_COUNTER_DATA(),
    .TRIGGER_COUNTER_SET(TRIGGER_COUNTER_SET_FLAG_SYNC),
    .TRIGGER_COUNTER_SET_VALUE(TRIGGER_COUNTER),

    .TRIGGER_MODE(TRIGGER_MODE_SYNC),
    .TRIGGER_THRESHOLD(CONF_TRIGGER_THRESHOLD_SYNC),

    .TRIGGER(TRIGGER_FSM),
    .TRIGGER_VETO(TRIGGER_VETO_OR_SYNC),
    .TRIGGER_ENABLE(TRIGGER_ENABLE_FSM),
    .TRIGGER_ACKNOWLEDGE(TRIGGER_ACKNOWLEDGE_FSM),
    .TRIGGER_ACCEPTED_FLAG(TRIGGER_ACCEPTED_FLAG),

    .TLU_TRIGGER_LOW_TIME_OUT(TLU_TRIGGER_LOW_TIME_OUT_SYNC),
//    .TLU_TRIGGER_CLOCK_CYCLES(TLU_TRIGGER_CLOCK_CYCLES_SYNC),
    .TLU_TRIGGER_DATA_DELAY(TLU_TRIGGER_DATA_DELAY_SYNC),
    .TLU_TRIGGER_DATA_MSB_FIRST(TLU_TRIGGER_DATA_MSB_FIRST_SYNC),
    .TLU_ENABLE_VETO(TLU_ENABLE_VETO_SYNC),
    .TLU_RESET_FLAG(TLU_RESET_FLAG_SYNC),

    .CONF_DATA_FORMAT(CONF_DATA_FORMAT),

    .TLU_BUSY(TLU_BUSY),
    .TLU_CLOCK_ENABLE(TLU_CLOCK_ENABLE),
    .TLU_ASSERT_VETO(TLU_ASSERT_VETO),

    .TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES(CONF_TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES_SYNC),
    .TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES(CONF_TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES_SYNC),

    .TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG(TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG),
    .TLU_TRIGGER_ACCEPT_ERROR_FLAG(TLU_TRIGGER_ACCEPT_ERROR_FLAG)
);

reg [7:0] rst_cnt;
always@(posedge BUS_CLK) begin
    if (RST)
        rst_cnt <= 8'b1111_1111; // start value
    else if (rst_cnt != 0)
        rst_cnt <= rst_cnt - 1;
end

wire RST_LONG;
assign RST_LONG = |rst_cnt;

wire wfull;
wire cdc_fifo_write;
assign cdc_fifo_write = !wfull && TRIGGER_DATA_WRITE;
wire fifo_full, cdc_fifo_empty;

always@(posedge TRIGGER_CLK) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && TRIGGER_DATA_WRITE && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT + 1;
end

wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(TRIGGER_DATA),
    .winc(cdc_fifo_write), .wclk(TRIGGER_CLK), .wrst(RST_LONG),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(RST_LONG)
);

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(8))  fifo_i
(
    .clk(BUS_CLK), .reset(RST_LONG | BUS_RST),
    .write(!cdc_fifo_empty),
    .read(FIFO_READ),
    .data_in(cdc_data_out),
    .full(fifo_full),
    .empty(FIFO_EMPTY),
    .data_out(FIFO_DATA[31:0]),
    .size()
);

// Chipscope
`ifdef SYNTHESIS_NOT
//`ifdef SYNTHESIS
wire [35:0] control_bus;
chipscope_icon ichipscope_icon
(
    .CONTROL0(control_bus)
);

chipscope_ila ichipscope_ila
(
    .CONTROL(control_bus),
    .CLK(BUS_CLK),
    .TRIG0({TRIGGER_MODE,BUS_DATA_IN,BUS_ADD,BUS_RD,BUS_WR, BUS_CLK ,RST})
);
`endif

endmodule
