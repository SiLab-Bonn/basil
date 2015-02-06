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
    parameter                   DIVISOR = 8, // dividing CMD_CLK by DIVISOR for TLU_CLOCK
    parameter                   ABUSWIDTH = 16
)
(
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire [ABUSWIDTH-1:0]  BUS_ADD,
    input wire      [7:0]       BUS_DATA_IN,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    output reg      [7:0]       BUS_DATA_OUT,
    
    input wire                  CMD_CLK, // clock of the TLU FSM
    
    input wire                  FIFO_READ,
    output wire                 FIFO_EMPTY,
    output wire     [31:0]      FIFO_DATA,
    
    output reg                  FIFO_PREEMPT_REQ, // FIFO hold request
    
    input wire                  RJ45_TRIGGER, // trigger input
    input wire                  LEMO_TRIGGER, // trigger input
    input wire                  RJ45_RESET, // trigger reset input
    input wire                  LEMO_RESET, // trigger reset input
    output reg                  RJ45_ENABLED, // RJ45 enabled signal
    output wire                 TLU_BUSY, // TLU FSM busy signal
    output reg                  TLU_CLOCK, // trigger data clock
    
    input wire                  EXT_VETO, // external veto signal (e.g. FIFO buffer full signal)
    
    input wire                  CMD_READY, // CMD FSM ready signal
    output wire                 CMD_EXT_START_FLAG, // CMD FSM external start flag (send command)
    input wire                  CMD_EXT_START_ENABLE, // CMD FSM external start enabled
    
    output reg      [31:0]      TIMESTAMP
);

localparam VERSION = 1;

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

wire RST_CMD_CLK;
flag_domain_crossing cmd_rst_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(CMD_CLK),
    .FLAG_IN_CLK_A(RST),
    .FLAG_OUT_CLK_B(RST_CMD_CLK)
);

reg [7:0] status_regs[15:0];

// reg 0 for SOFT_RST
wire [1:0] TLU_MODE; // 2'b00 - RJ45 disabled, 2'b01 - TLU no handshake, 2'b10 - TLU simple handshake, 2'b11 - TLU trigger data handshake
assign TLU_MODE = status_regs[1][1:0];
wire TLU_TRIGGER_DATA_MSB_FIRST; // set endianness of TLU number
assign TLU_TRIGGER_DATA_MSB_FIRST = status_regs[1][2];
wire TLU_DISABLE_VETO;
assign TLU_DISABLE_VETO = status_regs[1][3];
wire [3:0] TLU_TRIGGER_DATA_DELAY;
assign TLU_TRIGGER_DATA_DELAY = status_regs[1][7:4];
wire [4:0] TLU_TRIGGER_CLOCK_CYCLES;
assign TLU_TRIGGER_CLOCK_CYCLES = status_regs[2][4:0];
wire TLU_ENABLE_RESET;
assign TLU_ENABLE_RESET = status_regs[2][5];
wire TLU_INVERT_LEMO_TRIGGER;
assign TLU_INVERT_LEMO_TRIGGER = status_regs[2][6];
//wire FORCE_USE_RJ45;
//assign FORCE_USE_RJ45 = status_regs[2][7];
wire CONF_EN_WRITE_TS;
assign CONF_EN_WRITE_TS = status_regs[2][7];
wire [7:0] TLU_TRIGGER_LOW_TIME_OUT;
assign TLU_TRIGGER_LOW_TIME_OUT = status_regs[3];
//wire [31:0] SET_TRIGGER_NUMBER;
//assign SET_TRIGGER_NUMBER = {status_regs[11], status_regs[10], status_regs[9], status_regs[8]};

always @(posedge BUS_CLK)
begin
    if(RST)
    begin
        status_regs[0] <= 0;
        status_regs[1] <= 8'b0000_0000;
        status_regs[2] <= 8'd0; // 0: 32 clock cycles
        status_regs[3] <= 8'd0;
        status_regs[4] <= 0; // TLU trigger number
        status_regs[5] <= 0;
        status_regs[6] <= 0;
        status_regs[7] <= 0;
        status_regs[8] <= 0; // set trigger counter
        status_regs[9] <= 0;
        status_regs[10] <= 0;
        status_regs[11] <= 0;
        status_regs[12] <= 0; // spare
        status_regs[13] <= 0;
        status_regs[14] <= 0;
        status_regs[15] <= 0;
    end
    else if(BUS_WR && BUS_ADD < 16)
    begin
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
    end
end

// read reg
reg [7:0] LOST_DATA_CNT; // BUS_ADD==0
reg [31:0] CURRENT_TLU_TRIGGER_NUMBER_BUF; // BUS_ADD==4 - 7
reg [31:0] CURRENT_TRIGGER_NUMBER, CURRENT_TRIGGER_NUMBER_BUF; // BUS_ADD==8 - 11

always @ (posedge BUS_CLK)
begin
    if (BUS_ADD == 0)
        BUS_DATA_OUT <= VERSION;
    else if (BUS_ADD == 1)
        BUS_DATA_OUT <= status_regs[1];
    else if (BUS_ADD == 2)
        BUS_DATA_OUT <= status_regs[2]; //{RJ45_ENABLED, status_regs[2][6:0]};
    else if (BUS_ADD == 3)
        BUS_DATA_OUT <= status_regs[3];
    else if (BUS_ADD == 4)
        BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUF[7:0];
    else if (BUS_ADD == 5)
        BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUF[15:8];
    else if (BUS_ADD == 6)
        BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUF[23:16];
    else if (BUS_ADD == 7)
        BUS_DATA_OUT <= CURRENT_TLU_TRIGGER_NUMBER_BUF[31:24];
    else if (BUS_ADD == 8)
        BUS_DATA_OUT <= CURRENT_TRIGGER_NUMBER_BUF[7:0];
    else if (BUS_ADD == 9)
        BUS_DATA_OUT <= CURRENT_TRIGGER_NUMBER_BUF[15:8];
    else if (BUS_ADD == 10)
        BUS_DATA_OUT <= CURRENT_TRIGGER_NUMBER_BUF[23:16];
    else if (BUS_ADD == 11)
        BUS_DATA_OUT <= CURRENT_TRIGGER_NUMBER_BUF[31:24];
    else if (BUS_ADD == 12)
        BUS_DATA_OUT <= LOST_DATA_CNT;
    else
        BUS_DATA_OUT <= 0;
end

//assign some_value = (BUS_ADD==x && BUS_WR);
//assign some_value = status_regs[x]; // single reg
//assign some_value = {status_regs[x], status_regs[y]}; // multiple regs, specific order
//assign some_value = {status_regs[x:y]}; // multiple regs
//assign some_value = {status_regs[x][y]}; // single bit
//assign some_value = {status_regs[x][y:z]}; // multiple bits

// register sync
wire [1:0] TLU_MODE_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(2)
) three_stage_tlu_mode_synchronizer (
    .CLK(CMD_CLK),
    .IN(TLU_MODE),
    .OUT(TLU_MODE_CMD_CLK)
);

wire [7:0] TLU_TRIGGER_LOW_TIME_OUT_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(8)
) three_stage_trigger_low_timeout_synchronizer (
    .CLK(CMD_CLK),
    .IN(TLU_TRIGGER_LOW_TIME_OUT),
    .OUT(TLU_TRIGGER_LOW_TIME_OUT_CMD_CLK)
);

wire [4:0] TLU_TRIGGER_CLOCK_CYCLES_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(5)
) three_stage_trigger_clock_cycles_synchronizer (
    .CLK(CMD_CLK),
    .IN(TLU_TRIGGER_CLOCK_CYCLES),
    .OUT(TLU_TRIGGER_CLOCK_CYCLES_CMD_CLK)
);

wire [3:0] TLU_TRIGGER_DATA_DELAY_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(4)
) three_stage_trigger_data_delay_synchronizer (
    .CLK(CMD_CLK),
    .IN(TLU_TRIGGER_DATA_DELAY),
    .OUT(TLU_TRIGGER_DATA_DELAY_CMD_CLK)
);

wire TLU_TRIGGER_DATA_MSB_FIRST_CMD_CLK;
three_stage_synchronizer three_stage_trigger_data_msb_first_synchronizer (
    .CLK(CMD_CLK),
    .IN(TLU_TRIGGER_DATA_MSB_FIRST),
    .OUT(TLU_TRIGGER_DATA_MSB_FIRST_CMD_CLK)
);

wire TLU_DISABLE_VETO_CMD_CLK;
three_stage_synchronizer three_stage_disable_veto_synchronizer (
    .CLK(CMD_CLK),
    .IN(TLU_DISABLE_VETO),
    .OUT(TLU_DISABLE_VETO_CMD_CLK)
);

wire CONF_EN_WRITE_TS_CMD_CLK;
three_stage_synchronizer three_stage_enable_write_ts_synchronizer (
    .CLK(CMD_CLK),
    .IN(CONF_EN_WRITE_TS),
    .OUT(CONF_EN_WRITE_TS_CMD_CLK)
);

wire TLU_ENABLE_RESET_CMD_CLK;
three_stage_synchronizer three_stage_enable_reset_command_synchronizer (
    .CLK(CMD_CLK),
    .IN(TLU_ENABLE_RESET),
    .OUT(TLU_ENABLE_RESET_CMD_CLK)
);

// input sync
wire CMD_EXT_START_ENABLE_BUS_CLK;
three_stage_synchronizer three_stage_cmd_external_start_synchronizer (
    .CLK(BUS_CLK),
    .IN(CMD_EXT_START_ENABLE),
    .OUT(CMD_EXT_START_ENABLE_BUS_CLK)
);

// TLU input sync
wire RJ45_TRIGGER_CMD_CLK, LEMO_TRIGGER_CMD_CLK, RJ45_RESET_CMD_CLK, LEMO_RESET_CMD_CLK, EXT_VETO_CMD_CLK;

wire LEMO_TRIGGER_MOD;
assign LEMO_TRIGGER_MOD = TLU_INVERT_LEMO_TRIGGER ? ~LEMO_TRIGGER : LEMO_TRIGGER;

three_stage_synchronizer three_stage_rj45_trigger_synchronizer_cmd_clk (
    .CLK(CMD_CLK),
    .IN(RJ45_TRIGGER),
    .OUT(RJ45_TRIGGER_CMD_CLK)
);

three_stage_synchronizer three_stage_lemo_trigger_synchronizer_cmd_clk (
    .CLK(CMD_CLK),
    .IN(LEMO_TRIGGER_MOD),
    .OUT(LEMO_TRIGGER_CMD_CLK)
);

three_stage_synchronizer three_stage_rj45_reset_synchronizer_cmd_clk (
    .CLK(CMD_CLK),
    .IN(RJ45_RESET),
    .OUT(RJ45_RESET_CMD_CLK)
);

three_stage_synchronizer three_stage_lemo_reset_synchronizer_cmd_clk (
    .CLK(CMD_CLK),
    .IN(LEMO_RESET),
    .OUT(LEMO_RESET_CMD_CLK)
);

three_stage_synchronizer three_stage_lemo_ext_veto_synchronizer_cmd_clk (
    .CLK(CMD_CLK),
    .IN(EXT_VETO),
    .OUT(EXT_VETO_CMD_CLK)
);

// output sync
// nothing to do here

// TLU clock (not a real clock ...)
wire TLU_ASSERT_VETO, TLU_CLOCK_ENABLE;
integer counter_clk;
always @ (posedge CMD_CLK)
begin
    if (TLU_ASSERT_VETO) // synchronous set
        TLU_CLOCK <= 1'b1;
    else
    begin
        if (TLU_CLOCK_ENABLE)
        begin
            if (counter_clk == 0)
                TLU_CLOCK <= ~TLU_CLOCK;
            else
                TLU_CLOCK <= TLU_CLOCK;
        end
        else
            TLU_CLOCK <= 1'b0;
    end
end

	
always @ (posedge CMD_CLK)
begin
    if (RST_CMD_CLK)
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

// Trigger input port select
always @ (posedge CMD_CLK)
begin
    if (RST_CMD_CLK)
        RJ45_ENABLED <= 1'b0;
    else
    begin
//        if (FORCE_USE_RJ45 == 1'b1 && TLU_MODE != 2'b00)
//            RJ45_ENABLED <= 1'b1;
        if ((RJ45_TRIGGER_CMD_CLK == 1'b1 && RJ45_RESET_CMD_CLK == 1'b1 && !(RJ45_ENABLED == 1'b1)) || TLU_MODE_CMD_CLK == 2'b00)
            RJ45_ENABLED <= 1'b0;
        else
            RJ45_ENABLED <= 1'b1;
    end
end

wire TRIGGER_CMD_CLK, TRIGGER_RESET_CMD_CLK;
assign TRIGGER_CMD_CLK = (RJ45_ENABLED == 1'b1) ? RJ45_TRIGGER_CMD_CLK : LEMO_TRIGGER_CMD_CLK; // RJ45 inputs tied to 1 if no connector is plugged in
assign TRIGGER_RESET_CMD_CLK = (RJ45_ENABLED == 1'b1) ? RJ45_RESET_CMD_CLK : LEMO_RESET_CMD_CLK; // RJ45 inputs tied to 1 if no connector is plugged in

// Trigger flag
reg TLU_TRIGGER_CMD_CLK_FF;
always @ (posedge CMD_CLK)
    TLU_TRIGGER_CMD_CLK_FF <= TRIGGER_CMD_CLK;

wire TLU_TRIGGER_FLAG_CMD_CLK;
assign TLU_TRIGGER_FLAG_CMD_CLK = ~TLU_TRIGGER_CMD_CLK_FF & TRIGGER_CMD_CLK;

// Reset flag
reg TLU_RESET_CMD_CLK_FF;
always @ (posedge CMD_CLK)
    TLU_RESET_CMD_CLK_FF <= TRIGGER_RESET_CMD_CLK;

wire TLU_RESET_FLAG_CMD_CLK;
wire TLU_RESET_FLAG_BUS_CLK;
assign TLU_RESET_FLAG_CMD_CLK = ~TLU_RESET_CMD_CLK_FF & TRIGGER_RESET_CMD_CLK & TLU_ENABLE_RESET_CMD_CLK;
flag_domain_crossing tlu_reset_flag_domain_crossing (
    .CLK_A(CMD_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(TLU_RESET_FLAG_CMD_CLK),
    .FLAG_OUT_CLK_B(TLU_RESET_FLAG_BUS_CLK)
);

// writing current TLU trigger number to register
reg [31:0] CURRENT_TLU_TRIGGER_NUMBER_CMD_CLK;
wire [31:0] TLU_TRIGGER_NUMBER_DATA;
wire TLU_FIFO_WRITE;
always @ (posedge CMD_CLK)
begin
    if (RST_CMD_CLK)
        CURRENT_TLU_TRIGGER_NUMBER_CMD_CLK <= 32'b0;
    else if (TLU_FIFO_WRITE == 1'b1)
        CURRENT_TLU_TRIGGER_NUMBER_CMD_CLK <= TLU_TRIGGER_NUMBER_DATA;
end

wire TLU_FIFO_WRITE_BUS_CLK;
flag_domain_crossing tlu_fifo_write_flag_domain_crossing (
    .CLK_A(CMD_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(TLU_FIFO_WRITE),
    .FLAG_OUT_CLK_B(TLU_FIFO_WRITE_BUS_CLK)
);

reg [31:0] CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK;
always @ (posedge BUS_CLK)
begin
    if (RST)
        CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK <= 32'b0;
    else if (TLU_FIFO_WRITE_BUS_CLK == 1'b1)
        CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK <= CURRENT_TLU_TRIGGER_NUMBER_CMD_CLK;
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        CURRENT_TLU_TRIGGER_NUMBER_BUF <= 32'b0;
    else if (BUS_ADD == 4)
        CURRENT_TLU_TRIGGER_NUMBER_BUF <= CURRENT_TLU_TRIGGER_NUMBER_BUS_CLK;
end

wire CMD_EXT_START_FLAG_BUS_CLK;
flag_domain_crossing cmd_ext_start_flag_domain_crossing (
    .CLK_A(CMD_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(CMD_EXT_START_FLAG),
    .FLAG_OUT_CLK_B(CMD_EXT_START_FLAG_BUS_CLK)
);

always @ (posedge BUS_CLK)
begin
    if (RST | TLU_RESET_FLAG_BUS_CLK == 1'b1)
        CURRENT_TRIGGER_NUMBER <= 32'b0;
    //else if (BUS_ADD == 11 && BUS_WR)
    //    CURRENT_TRIGGER_NUMBER <= SET_TRIGGER_NUMBER;
    else if (CMD_EXT_START_FLAG_BUS_CLK == 1'b1 && CMD_EXT_START_ENABLE_BUS_CLK == 1'b1 && CURRENT_TRIGGER_NUMBER != 32'b1111_1111_1111_1111_1111_1111_1111_1111)
        CURRENT_TRIGGER_NUMBER <= CURRENT_TRIGGER_NUMBER + 1;
    //else if (CMD_EXT_START_ENABLE_FLAG_BUS_CLK == 1'b1)
    //    CURRENT_TRIGGER_NUMBER <= 32'b0;
end

always @ (posedge BUS_CLK)
begin
    if (RST)
        CURRENT_TRIGGER_NUMBER_BUF <= 32'b0;
    else if (BUS_ADD == 8)
        CURRENT_TRIGGER_NUMBER_BUF <= CURRENT_TRIGGER_NUMBER;
end

// 40 MHz time stamp
always @ (posedge CMD_CLK)
begin
    if (RST_CMD_CLK | TLU_RESET_FLAG_CMD_CLK)
        TIMESTAMP <= 32'b0;
    else
        TIMESTAMP <= TIMESTAMP + 1;
end

// TLU FSM
wire FIFO_PREEMPT_REQ_FLAG_CMD_CLK;
wire [31:0] TLU_FIFO_DATA;
tlu_controller_fsm #(
    .DIVISOR(DIVISOR)
) tlu_controller_fsm_inst (
    .RESET(RST_CMD_CLK),
    .CLK(CMD_CLK),
    
    .TLU_FIFO_WRITE(TLU_FIFO_WRITE),
    .TLU_FIFO_DATA(TLU_FIFO_DATA),
    
    .FIFO_PREEMPT_REQ_FLAG(FIFO_PREEMPT_REQ_FLAG_CMD_CLK),

    .TIMESTAMP(TIMESTAMP),
    .TIMESTAMP_DATA(),
    .TLU_TRIGGER_NUMBER_DATA(TLU_TRIGGER_NUMBER_DATA),
    
    .CMD_READY(CMD_READY),
    .CMD_EXT_START_FLAG(CMD_EXT_START_FLAG),
    .CMD_EXT_START_ENABLE(CMD_EXT_START_ENABLE),
    
    .TLU_TRIGGER(TRIGGER_CMD_CLK),
    .TLU_TRIGGER_FLAG(TLU_TRIGGER_FLAG_CMD_CLK),
    
    .TLU_MODE(TLU_MODE_CMD_CLK),
    .TLU_TRIGGER_LOW_TIME_OUT(TLU_TRIGGER_LOW_TIME_OUT_CMD_CLK),
    .TLU_TRIGGER_CLOCK_CYCLES(TLU_TRIGGER_CLOCK_CYCLES_CMD_CLK),
    .TLU_TRIGGER_DATA_DELAY(TLU_TRIGGER_DATA_DELAY_CMD_CLK),
    .TLU_TRIGGER_DATA_MSB_FIRST(TLU_TRIGGER_DATA_MSB_FIRST_CMD_CLK),
    .TLU_DISABLE_VETO(TLU_DISABLE_VETO_CMD_CLK),
    .EXT_VETO(EXT_VETO_CMD_CLK),
    .TLU_RESET_FLAG(TLU_RESET_FLAG_CMD_CLK),
    
    .WRITE_TIMESTAMP(CONF_EN_WRITE_TS_CMD_CLK),
    
    .TLU_BUSY(TLU_BUSY),
    .TLU_CLOCK_ENABLE(TLU_CLOCK_ENABLE),
    .TLU_ASSERT_VETO(TLU_ASSERT_VETO),

    .TLU_TRIGGER_LOW_TIMEOUT_ERROR(),
    .TLU_TRIGGER_ACCEPT_ERROR()
);

wire FIFO_PREEMPT_REQ_FLAG_BUS_CLK;
flag_domain_crossing fifo_preempt_flag_domain_crossing (
    .CLK_A(CMD_CLK),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(FIFO_PREEMPT_REQ_FLAG_CMD_CLK),
    .FLAG_OUT_CLK_B(FIFO_PREEMPT_REQ_FLAG_BUS_CLK)
);

// FIFO empty flag
reg FIFO_EMPTY_FF;
always @ (posedge BUS_CLK)
    FIFO_EMPTY_FF <= FIFO_EMPTY;

wire FIFO_EMPTY_FLAG_BUS_CLK;
assign FIFO_EMPTY_FLAG_BUS_CLK = FIFO_EMPTY_FF & ~FIFO_EMPTY; // assert flag when FIFO is empty again

always @ (posedge BUS_CLK)
    if (RST)
        FIFO_PREEMPT_REQ <= 1'b0;
    else
        if (FIFO_PREEMPT_REQ_FLAG_BUS_CLK)
            FIFO_PREEMPT_REQ <= 1'b1;
        else if (FIFO_EMPTY_FLAG_BUS_CLK)
            FIFO_PREEMPT_REQ <= 1'b0;

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
assign cdc_fifo_write = !wfull && TLU_FIFO_WRITE;
wire fifo_full, cdc_fifo_empty;

always@(posedge CMD_CLK) begin
    if(RST_CMD_CLK)
        LOST_DATA_CNT <= 0;
    else if (wfull && TLU_FIFO_WRITE && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT + 1;
end

wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(TLU_FIFO_DATA),
    .winc(cdc_fifo_write), .wclk(CMD_CLK), .wrst(RST_LONG),
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
    .data_out(FIFO_DATA[31:0]), .size() 
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
    .TRIG0({TLU_MODE,BUS_DATA_IN,BUS_ADD,BUS_RD,BUS_WR, BUS_CLK ,RST})
);
`endif

endmodule
