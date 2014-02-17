/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $:
 *  $Date::                      $:
 */

 /*  _____ _   _   _ 
 * |_   _| | | | | |
 *   | | | |_| |_| |
 *   |_| |___|\___/
 *
 * TLU controller supporting EUDET TLU 0.1/0.2
 */
 
`timescale 1 ps / 1ps
`default_nettype none
 
 module tlu_controller_core
#(
    parameter                   DIVISOR = 12
)
(
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire      [15:0]      BUS_ADD,
    input wire      [7:0]       BUS_DATA_IN,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    output reg      [7:0]       BUS_DATA_OUT,
    
    input wire                  CMD_CLK,
    
    input wire                  FIFO_READ,
    output wire                 FIFO_EMPTY,
    output wire     [31:0]      FIFO_DATA,
    
    output wire                 FIFO_PREEMPT_REQ,
    
    input wire                  RJ45_TRIGGER,
    input wire                  LEMO_TRIGGER,
    input wire                  RJ45_RESET,
    input wire                  LEMO_RESET,
    output reg                  RJ45_ENABLED,
    output wire                 TLU_BUSY,
    output reg                  TLU_CLOCK,
    
    input wire                  EXT_VETO,
    
    input wire                  CMD_READY,
    output wire                 CMD_EXT_START_FLAG,
    input wire                  CMD_EXT_START_ENABLE,
    
    input wire                  FIFO_NEAR_FULL
);

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
wire [31:0] SET_TRIGGER_NUMBER;
assign SET_TRIGGER_NUMBER = {status_regs[11], status_regs[10], status_regs[9], status_regs[8]};

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
reg [31:0] CURRENT_TLU_TRIGGER_NUMBER;
reg [31:0] CURRENT_TLU_TRIGGER_NUMBER_BUF;
reg [31:0] CURRENT_TRIGGER_NUMBER;
reg [31:0] CURRENT_TRIGGER_NUMBER_BUF;

always @ (negedge BUS_CLK)
begin
    //BUS_DATA_OUT <= 0;
    if (BUS_ADD == 0)
        BUS_DATA_OUT <= status_regs[0];
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
        BUS_DATA_OUT <= 8'b0;
    else if (BUS_ADD == 13)
        BUS_DATA_OUT <= 8'b0;
    else if (BUS_ADD == 14)
        BUS_DATA_OUT <= 8'b0;
    else if (BUS_ADD == 15)
        BUS_DATA_OUT <= 8'b0;
    // else if(BUS_ADD < 4)
        // BUS_DATA_OUT <= status_regs[BUS_ADD[3:0]]; // BUG AR 20391: use synchronous logic
    else
        BUS_DATA_OUT <= 0;
end

//always @(*)
//begin
//    BUS_DATA_OUT = 0;
//	 
//    if (BUS_ADD == 4)
//        BUS_DATA_OUT = CURRENT_TLU_TRIGGER_NUMBER_BUF[7:0];
//    else if (BUS_ADD == 5)
//        BUS_DATA_OUT = CURRENT_TLU_TRIGGER_NUMBER_BUF[15:8];
//    else if (BUS_ADD == 6)
//        BUS_DATA_OUT = CURRENT_TLU_TRIGGER_NUMBER_BUF[23:16];
//    else if (BUS_ADD == 7)
//        BUS_DATA_OUT = CURRENT_TLU_TRIGGER_NUMBER_BUF[31:24];
//    else if(BUS_ADD < 4)
//        BUS_DATA_OUT = status_regs[BUS_ADD[2:0]]; // BUG AR 20391
//    
////    if(BUS_ADD == 1)
////        BUS_DATA_OUT = {8'b0};
////    else if(BUS_ADD == 2)
////        BUS_DATA_OUT = {8'b0};
////    else if(BUS_ADD == 3)
////        BUS_DATA_OUT = {8'b0};
////    else if(BUS_ADD == 4)
////        BUS_DATA_OUT = {8'b0};
////    else if(BUS_ADD == 5)
////        BUS_DATA_OUT = {8'b0};
////    else if(BUS_ADD == 6)
////        BUS_DATA_OUT = {8'b0};
////    else if(BUS_ADD == 7)
////        BUS_DATA_OUT = {8'b0};
//end

//assign some_value = (BUS_ADD==x && BUS_WR);
//assign some_value = status_regs[x]; // single reg
//assign some_value = {status_regs[x], status_regs[y]}; // multiple regs, specific order
//assign some_value = {status_regs[x:y]}; // multiple regs
//assign some_value = {status_regs[x][y]}; // single bit
//assign some_value = {status_regs[x][y:z]}; // multiple bits

wire                TLU_CLOCK_ENABLE;
wire                TLU_ASSERT_VETO;
wire                TLU_TRIGGER_FLAG_BUS_CLK;
wire                TLU_RESET_FLAG_BUS_CLK;

// Register sync
// nothing to do here

// Input sync
wire CMD_READY_BUS_CLK;
three_stage_synchronizer three_stage_cmd_ready_synchronizer (
    .CLK(BUS_CLK),
    .IN(CMD_READY),
    .OUT(CMD_READY_BUS_CLK)
);

wire CMD_EXT_START_ENABLE_BUS_CLK;
three_stage_synchronizer three_stage_cmd_external_start_synchronizer (
    .CLK(BUS_CLK),
    .IN(CMD_EXT_START_ENABLE),
    .OUT(CMD_EXT_START_ENABLE_BUS_CLK)
);

// Output sync
wire CMD_EXT_START_FLAG_BUS_CLK;
flag_domain_crossing cmd_ext_start_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(CMD_CLK),
    .FLAG_IN_CLK_A(CMD_EXT_START_FLAG_BUS_CLK),
    .FLAG_OUT_CLK_B(CMD_EXT_START_FLAG)
);

// TLU clock (not a real clock ...)
integer counter_clk;
always @ (posedge BUS_CLK)
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

	
always @ (posedge BUS_CLK)
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

// Trigger sync
wire RJ45_TRIGGER_BUS_CLK, LEMO_TRIGGER_BUS_CLK, RJ45_RESET_BUS_CLK, LEMO_RESET_BUS_CLK, EXT_VETO_BUS_CLK;

wire LEMO_TRIGGER_MOD;
assign LEMO_TRIGGER_MOD = TLU_INVERT_LEMO_TRIGGER ? ~LEMO_TRIGGER : LEMO_TRIGGER;

three_stage_synchronizer three_stage_rj45_trigger_synchronizer_bus_clk (
    .CLK(BUS_CLK),
    .IN(RJ45_TRIGGER),
    .OUT(RJ45_TRIGGER_BUS_CLK)
);

three_stage_synchronizer three_stage_lemo_trigger_synchronizer_bus_clk (
    .CLK(BUS_CLK),
    .IN(LEMO_TRIGGER_MOD),
    .OUT(LEMO_TRIGGER_BUS_CLK)
);

three_stage_synchronizer three_stage_rj45_reset_synchronizer_bus_clk (
    .CLK(BUS_CLK),
    .IN(RJ45_RESET),
    .OUT(RJ45_RESET_BUS_CLK)
);

three_stage_synchronizer three_stage_lemo_reset_synchronizer_bus_clk (
    .CLK(BUS_CLK),
    .IN(LEMO_RESET),
    .OUT(LEMO_RESET_BUS_CLK)
);

three_stage_synchronizer three_stage_lemo_ext_veto_synchronizer_bus_clk (
    .CLK(BUS_CLK),
    .IN(EXT_VETO),
    .OUT(EXT_VETO_BUS_CLK)
);

// Trigger input port select
always @ (posedge BUS_CLK)
begin
    if (RST)
        RJ45_ENABLED <= 1'b0;
    else
    begin
//        if (FORCE_USE_RJ45 == 1'b1 && TLU_MODE != 2'b00)
//            RJ45_ENABLED <= 1'b1;
        if ((RJ45_TRIGGER_BUS_CLK == 1'b1 && RJ45_RESET_BUS_CLK == 1'b1 && !(RJ45_ENABLED == 1'b1)) || TLU_MODE == 2'b00)
            RJ45_ENABLED <= 1'b0;
        else
            RJ45_ENABLED <= 1'b1;
    end
end

wire TLU_TRIGGER_BUS_CLK, TLU_RESET_BUS_CLK;
assign TLU_TRIGGER_BUS_CLK = (RJ45_ENABLED == 1'b1) ? RJ45_TRIGGER_BUS_CLK : LEMO_TRIGGER_BUS_CLK; // RJ45 inputs tied to 1 if no connector is plugged in
assign TLU_RESET_BUS_CLK = (RJ45_ENABLED == 1'b1) ? RJ45_RESET_BUS_CLK : LEMO_RESET_BUS_CLK; // RJ45 inputs tied to 1 if no connector is plugged in

// Trigger flag
reg TLU_TRIGGER_BUS_CLK_FF;
always @ (posedge BUS_CLK)
    TLU_TRIGGER_BUS_CLK_FF <= TLU_TRIGGER_BUS_CLK;

assign TLU_TRIGGER_FLAG_BUS_CLK = ~TLU_TRIGGER_BUS_CLK_FF & TLU_TRIGGER_BUS_CLK;

// Reset flag
reg TLU_RESET_BUS_CLK_FF;
always @ (posedge BUS_CLK)
    TLU_RESET_BUS_CLK_FF <= TLU_RESET_BUS_CLK;

assign TLU_RESET_FLAG_BUS_CLK = ~TLU_RESET_BUS_CLK_FF & TLU_RESET_BUS_CLK;

// writing current TLU trigger number to register
wire TLU_DATA_READY_FLAG;
wire [31:0] TLU_DATA;
always @ (posedge BUS_CLK)
begin
    if (RST)
        CURRENT_TLU_TRIGGER_NUMBER <= 32'b0;
    else
    begin
        if (TLU_DATA_READY_FLAG == 1'b1)
            CURRENT_TLU_TRIGGER_NUMBER <= TLU_DATA[31:0];
        else
            CURRENT_TLU_TRIGGER_NUMBER <= CURRENT_TLU_TRIGGER_NUMBER;
    end
end

always @ (negedge BUS_CLK)
begin
    if (RST)
        CURRENT_TLU_TRIGGER_NUMBER_BUF <= 32'b0;
    else
    begin
        if (BUS_ADD == 4)
            CURRENT_TLU_TRIGGER_NUMBER_BUF <= CURRENT_TLU_TRIGGER_NUMBER;
        else
            CURRENT_TLU_TRIGGER_NUMBER_BUF <= CURRENT_TLU_TRIGGER_NUMBER_BUF;
    end
end

// writing current trigger number (not TLU) to register
// reg CMD_EXT_START_ENABLE_BUS_CLK_FF;
// always @ (posedge BUS_CLK)
    // CMD_EXT_START_ENABLE_BUS_CLK_FF <= CMD_EXT_START_ENABLE_BUS_CLK;

// wire CMD_EXT_START_ENABLE_FLAG_BUS_CLK;
// assign CMD_EXT_START_ENABLE_FLAG_BUS_CLK = ~CMD_EXT_START_ENABLE_BUS_CLK_FF & CMD_EXT_START_ENABLE_BUS_CLK;

// latching trigger number
// wire LATCH_TRIGGER_NUMBER_BUS_CLK;
// assign LATCH_TRIGGER_NUMBER_BUS_CLK = (BUS_ADD == 11 && BUS_WR);

// reg LATCH_TRIGGER_NUMBER_FF;
// always @(posedge BUS_CLK) begin
    // LATCH_TRIGGER_NUMBER_FF <= LATCH_TRIGGER_NUMBER_BUS_CLK;
// end

// wire LATCH_TRIGGER_NUMBER;
// assign LATCH_TRIGGER_NUMBER = ~LATCH_TRIGGER_NUMBER_FF & LATCH_TRIGGER_NUMBER_BUS_CLK;

always @ (posedge BUS_CLK)
begin
    if (RST || (TLU_RESET_FLAG_BUS_CLK == 1'b1 && TLU_ENABLE_RESET == 1'b1))
        CURRENT_TRIGGER_NUMBER <= 32'b0;
    else
    begin
        if (BUS_ADD == 11 && BUS_WR)
            CURRENT_TRIGGER_NUMBER <= SET_TRIGGER_NUMBER;
        else if (CMD_EXT_START_FLAG_BUS_CLK == 1'b1 && CMD_EXT_START_ENABLE_BUS_CLK == 1'b1 && CURRENT_TRIGGER_NUMBER != 32'b1111_1111_1111_1111_1111_1111_1111_1111)
            CURRENT_TRIGGER_NUMBER <= CURRENT_TRIGGER_NUMBER + 1;
        //else if (CMD_EXT_START_ENABLE_FLAG_BUS_CLK == 1'b1)
        //    CURRENT_TRIGGER_NUMBER <= 32'b0;
        else
            CURRENT_TRIGGER_NUMBER <= CURRENT_TRIGGER_NUMBER;
    end
end

always @ (negedge BUS_CLK)
begin
    if (RST)
        CURRENT_TRIGGER_NUMBER_BUF <= 32'b0;
    else
    begin
        if (BUS_ADD == 8)
            CURRENT_TRIGGER_NUMBER_BUF <= CURRENT_TRIGGER_NUMBER;
        else
            CURRENT_TRIGGER_NUMBER_BUF <= CURRENT_TRIGGER_NUMBER_BUF;
    end
end

// fucking FSM
tlu_controller_fsm #(
    .DIVISOR(DIVISOR)
) tlu_controller_fsm_inst (
    .RESET(RST),
    .CLK(BUS_CLK),
    
    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),
    
    .FIFO_PREEMPT_REQ(FIFO_PREEMPT_REQ),
    
    .TLU_DATA(TLU_DATA),
    .TLU_DATA_READY_FLAG(TLU_DATA_READY_FLAG),
    
    .CMD_READY(CMD_READY_BUS_CLK),
    .CMD_EXT_START_FLAG(CMD_EXT_START_FLAG_BUS_CLK),
    .CMD_EXT_START_ENABLE(CMD_EXT_START_ENABLE_BUS_CLK),
    
    .TLU_TRIGGER(TLU_TRIGGER_BUS_CLK),
    .TLU_TRIGGER_FLAG(TLU_TRIGGER_FLAG_BUS_CLK),
    
    .TLU_MODE(TLU_MODE),
    .TLU_TRIGGER_LOW_TIME_OUT(TLU_TRIGGER_LOW_TIME_OUT),
    .TLU_TRIGGER_CLOCK_CYCLES(TLU_TRIGGER_CLOCK_CYCLES),
    .TLU_TRIGGER_DATA_DELAY(TLU_TRIGGER_DATA_DELAY),
    .TLU_TRIGGER_DATA_MSB_FIRST(TLU_TRIGGER_DATA_MSB_FIRST),
    .TLU_DISABLE_VETO(TLU_DISABLE_VETO),
    .EXT_VETO(EXT_VETO_BUS_CLK),
    
    .TLU_BUSY(TLU_BUSY),
    .TLU_CLOCK_ENABLE(TLU_CLOCK_ENABLE),
    .TLU_ASSERT_VETO(TLU_ASSERT_VETO),

    .TLU_TRIGGER_LOW_TIMEOUT_ERROR(),
    .TLU_TRIGGER_ACCEPT_ERROR(),
    
    .WRITE_TIMESTAMP(CONF_EN_WRITE_TS),
    
    .FIFO_NEAR_FULL(FIFO_NEAR_FULL)
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
