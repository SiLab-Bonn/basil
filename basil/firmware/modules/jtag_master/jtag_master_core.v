/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module jtag_master_core #(
    parameter ABUSWIDTH = 16,
    parameter MEM_BYTES = 16
) (
    input wire                      BUS_CLK,
    input wire                      BUS_RST,
    input wire [ABUSWIDTH-1:0]      BUS_ADD,
    input wire [7:0]                BUS_DATA_IN,
    input wire                      BUS_RD,
    input wire                      BUS_WR,
    output reg [7:0]                BUS_DATA_OUT,

    input wire JTAG_CLK,

    output wire TCK,        // TCK
    input wire TDO,         // TDO
    output reg TDI,         // TDI
    output reg TMS,         // TMS

    output reg SEN,
    output reg SLD
);

localparam VERSION = 1;
localparam DEF_BIT_OUT = 8*MEM_BYTES;
reg [7:0] status_regs [15:0];

wire RST;
wire SOFT_RST;
wire RST_SYNC;
assign RST = BUS_RST || SOFT_RST;

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 0;
        status_regs[3] <= DEF_BIT_OUT[7:0]; //bits
        status_regs[4] <= DEF_BIT_OUT[15:8]; //bits
        status_regs[5] <= 0;  //wait
        status_regs[6] <= 0;  //wait
        status_regs[7] <= 0;  //wait
        status_regs[8] <= 0;  //wait
        status_regs[9] <= 1;  //word count
        status_regs[10] <= 0; //word count
        status_regs[11] <= 0; //Jtag command
        status_regs[12] <= 0; //Jtag command
        status_regs[13] <= 0; //0:enable external start
    end
    else if(BUS_WR && BUS_ADD < 16)
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
end

// Parameters from registers //

reg [7:0] BUS_IN_MEM;
reg [7:0] BUS_OUT_MEM;
reg CONF_DONE;

wire START;
wire START_SYNC;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

wire [15:0] CONF_BIT_OUT;
assign CONF_BIT_OUT = {status_regs[4],status_regs[3]};

wire [15:0] JTAG_OP_CODE;
assign JTAG_OP_CODE = {status_regs [12], status_regs [11]};

wire [15:0] WORD_COUNT;
assign WORD_COUNT = {status_regs [10], status_regs [9]};

wire [31:0] CONF_WAIT;
assign CONF_WAIT = {status_regs[8], status_regs[7], status_regs[6], status_regs[5]};

wire CONF_EN;
assign CONF_EN = status_regs[13][0];

wire [32:0] STOP_BIT;
assign STOP_BIT = CONF_BIT_OUT + CONF_WAIT;
/////

/// Basil Bus Communication ///
reg [7:0] BUS_DATA_OUT_REG;
always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT_REG <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT_REG <= {7'b0, CONF_DONE};
         else if(BUS_ADD == 13)
            BUS_DATA_OUT_REG <= {7'b0, CONF_EN};
        else if(BUS_ADD == 14)
            BUS_DATA_OUT_REG <= MEM_BYTES[7:0];
        else if(BUS_ADD == 15)
            BUS_DATA_OUT_REG <= MEM_BYTES[15:8];
        else if (BUS_ADD < 16)
            BUS_DATA_OUT_REG <= status_regs[BUS_ADD[3:0]];
    end
end

reg [ABUSWIDTH-1:0]  PREV_BUS_ADD;
always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        PREV_BUS_ADD <= BUS_ADD;
    end
end

always @(*) begin
    if(PREV_BUS_ADD < 16)
        BUS_DATA_OUT = BUS_DATA_OUT_REG;
    else if(PREV_BUS_ADD < 16+MEM_BYTES)
        BUS_DATA_OUT = BUS_IN_MEM;
    else if(PREV_BUS_ADD < 16+MEM_BYTES+MEM_BYTES)
        BUS_DATA_OUT = BUS_OUT_MEM;
    else
        BUS_DATA_OUT = 8'hxx;
end

reg [7:0] BUS_DATA_IN_IB;
wire [7:0] BUS_IN_MEM_IB;
wire [7:0] BUS_OUT_MEM_IB;
integer i;
always @(*) begin
    for(i=0;i<8;i=i+1) begin
        BUS_DATA_IN_IB[i] = BUS_DATA_IN[7-i];
        BUS_IN_MEM[i] = BUS_IN_MEM_IB[7-i];
        BUS_OUT_MEM[i] = BUS_OUT_MEM_IB[7-i];
    end
end
////

reg [15:0] state, next_state;
localparam TEST_LOGIC_RESET = 0,
    RUN_TEST_IDLE = 1,
    SELECT_DR_SCAN = 2,
    CAPTURE_DR = 3,
    SHIFT_DR = 4,
    EXIT1_DR = 5,
    PAUSE_DR = 6,
    EXIT2_DR = 7, 
    UPDATE_DR = 8,
    SELECT_IR_SCAN = 9,
    CAPTURE_IR = 10,
    SHIFT_IR = 11,
    EXIT1_IR = 12,
    PAUSE_IR = 13,
    EXIT2_IR = 14,
    UPDATE_IR = 15;

// Memory Management //
wire SDI_MEM;
reg [32:0] out_bit_cnt;
reg [32:0] out_word_cnt;
reg [32:0] reset_cnt;

wire [13:0] memout_addrb;
assign memout_addrb = (out_word_cnt * CONF_BIT_OUT) + CONF_BIT_OUT - 1 - out_bit_cnt;
wire [10:0] memout_addra;
assign memout_addra = (BUS_ADD-16);

blk_mem_gen_8_to_1_2k memout(
    .CLKA(BUS_CLK),
    .CLKB(JTAG_CLK),
    .DOUTA(BUS_IN_MEM_IB),
    .DOUTB(SDI_MEM),
    .WEA(BUS_WR && BUS_ADD >=16 && BUS_ADD < 16+MEM_BYTES),
    .WEB(1'b0),
    .ADDRA(memout_addra),
    .ADDRB(memout_addrb),
    .DINA(BUS_DATA_IN_IB),
    .DINB(1'b0)
);

wire [10:0] ADDRA_MIN;
assign ADDRA_MIN = (BUS_ADD-16-MEM_BYTES);
wire [13:0] ADDRB_MIN;
assign ADDRB_MIN = (out_word_cnt * CONF_BIT_OUT) + CONF_BIT_OUT - out_bit_cnt;
reg SEN_INT;

blk_mem_gen_8_to_1_2k memin(
    .CLKA(BUS_CLK),
    .CLKB(JTAG_CLK),
    .DOUTA(BUS_OUT_MEM_IB),
    .DOUTB(),
    .WEA(1'b0),
    .WEB(SEN_INT && (state == SHIFT_DR || state == SHIFT_IR)),
    .ADDRA(ADDRA_MIN),
    .ADDRB(ADDRB_MIN),
    .DINA(BUS_DATA_IN_IB),
    .DINB(TDO)
);
///

// JTAG Master Machine state //
localparam DR_SCAN = 1, IR_SCAN = 0;
reg transfert_active = 0;

// Assign next state of the FSM
always @(posedge JTAG_CLK) begin
    if (RST_SYNC)
        state <= TEST_LOGIC_RESET;
    else
        state <= next_state;
end

// State transition conditions
always @(*) begin
    case (state)
        TEST_LOGIC_RESET: 
        begin
            if (reset_cnt <= 5)
            begin
                next_state <= TEST_LOGIC_RESET;
                SEN_INT <= 1;
            end
            else
            begin
                next_state <= RUN_TEST_IDLE;
                SEN_INT <= 0;
            end
        end
        RUN_TEST_IDLE:
        begin
            if (START_SYNC || (out_word_cnt != WORD_COUNT && SEN_INT))
            begin
                next_state <= SELECT_DR_SCAN;
                SEN_INT <= 1;
            end
            else
            begin
                next_state <= RUN_TEST_IDLE;
                SEN_INT <= 0;
            end
        end
        SELECT_DR_SCAN:
        begin
            if (JTAG_OP_CODE == DR_SCAN)
                next_state <= CAPTURE_DR;
            else if (JTAG_OP_CODE == IR_SCAN)
                next_state <= SELECT_IR_SCAN;
            else
                next_state <= SELECT_IR_SCAN;
        end
        CAPTURE_DR: next_state <= SHIFT_DR;
        SHIFT_DR:
        begin
            if (out_bit_cnt == STOP_BIT)
                next_state <= EXIT1_DR;
            else
                next_state <= SHIFT_DR;
        end
        EXIT1_DR:       next_state <= UPDATE_DR;
        PAUSE_DR:       next_state <= EXIT2_DR;
        EXIT2_DR:       next_state <= UPDATE_DR;
        UPDATE_DR:      next_state <= RUN_TEST_IDLE;
        SELECT_IR_SCAN: next_state <= CAPTURE_IR;
        CAPTURE_IR:     next_state <= SHIFT_IR;
        SHIFT_IR:
        begin
            if (out_bit_cnt == STOP_BIT)
                next_state <= EXIT1_IR;
            else
                next_state <= SHIFT_IR;
        end
        EXIT1_IR:       next_state <= UPDATE_IR;
        PAUSE_IR:       next_state <= EXIT2_IR;
        EXIT2_IR:       next_state <= UPDATE_IR;
        UPDATE_IR:      next_state <= RUN_TEST_IDLE;
        default:        next_state <= RUN_TEST_IDLE;
    endcase
end

// Bit counter
always @(negedge JTAG_CLK)
begin
    if (RST_SYNC)
        out_bit_cnt <= 0;
    else if (state == SHIFT_DR || state == SHIFT_IR)
        out_bit_cnt <= out_bit_cnt + 1;
    else
        out_bit_cnt <= 0;
end 

// Word counter
always @(posedge JTAG_CLK)
begin // - 1 because we must change of step on last bit
    if (RST_SYNC)
        out_word_cnt <= 0;
    else if (state == UPDATE_DR || state == UPDATE_IR)
        out_word_cnt <= out_word_cnt + 1;
    else if (out_word_cnt == WORD_COUNT && state == RUN_TEST_IDLE)
        out_word_cnt <= 0;
end

// Reset counter
always @(posedge JTAG_CLK)
begin
    if (state == TEST_LOGIC_RESET)
        reset_cnt <= reset_cnt + 1;
    else
        reset_cnt <= 0;
end

// Outputs of FMS
always @(negedge JTAG_CLK)
begin
    case(state)
        TEST_LOGIC_RESET:
        begin
            if (next_state == RUN_TEST_IDLE)
                TMS <= 0;
            else if (reset_cnt < 5)
                TMS <= 1;
            else
                TMS <= 0;
        end
        RUN_TEST_IDLE:
        begin
            if (next_state == SELECT_DR_SCAN)
                TMS <= 1;
            else
                TMS <= 0;
        end
        SELECT_DR_SCAN:
        begin
            if (next_state == CAPTURE_DR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        CAPTURE_DR:
        begin
            if (next_state == SHIFT_DR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        SHIFT_DR:
        begin
            if (next_state == SHIFT_DR && out_bit_cnt != STOP_BIT - 1) // -1 beacause we need to change state on last bit
                TMS <= 0;
            else
                TMS <= 1;
        end
        EXIT1_DR:
        begin
            if (next_state == PAUSE_DR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        PAUSE_DR:
        begin
            if (next_state == PAUSE_DR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        EXIT2_DR:
        begin
            if (next_state == SHIFT_DR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        UPDATE_DR:
        begin
            if (next_state == RUN_TEST_IDLE)
                TMS <= 0;
            else
                TMS <= 1;
        end
        SELECT_IR_SCAN:
        begin
            if(next_state == CAPTURE_IR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        CAPTURE_IR:
        begin
            if (next_state == SHIFT_IR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        SHIFT_IR:
        begin
            if (next_state == SHIFT_IR && out_bit_cnt != STOP_BIT - 1) // -1 beacause we need to change state on last bit
                TMS <= 0;
            else
                TMS <= 1;
        end
        EXIT1_IR:
        begin
            if (next_state == PAUSE_IR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        PAUSE_IR:
        begin
            if (next_state == PAUSE_IR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        EXIT2_IR:
        begin
            if (next_state == SHIFT_IR)
                TMS <= 0;
            else
                TMS <= 1;
        end
        UPDATE_IR:
        begin
            if (next_state == RUN_TEST_IDLE)
                TMS <= 0;
            else
                TMS <= 1;
        end
        default:    TMS <= 1;
    endcase
end
////

// Synchronous signals //

wire RST_SOFT_SYNC;
cdc_reset_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(JTAG_CLK), .pulse_out(RST_SOFT_SYNC));
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(JTAG_CLK), .pulse_out(START_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;
///

// Transmission done signal //
reg [1:0] sync_ld;
always @(posedge JTAG_CLK) begin
    sync_ld[0] <= SEN_INT;
    sync_ld[1] <= sync_ld[0];
end

always @(posedge JTAG_CLK)
    SLD <= (sync_ld[1]==1 && sync_ld[0]==0);

wire DONE_SYNC, DONE;
assign DONE = (out_word_cnt == WORD_COUNT && state == RUN_TEST_IDLE) || (reset_cnt == 5);
cdc_pulse_sync done_pulse_sync (.clk_in(JTAG_CLK), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));

always @(posedge BUS_CLK)
    if(START || RST)
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;
///

// Outputs //
CG_MOD_pos icg2(.ck_in(JTAG_CLK), .enable(SEN), .ck_out(TCK));

always @(negedge JTAG_CLK)
    TDI <= SDI_MEM & SEN_INT;

always @(negedge JTAG_CLK)
    SEN <= SEN_INT;
///

endmodule
