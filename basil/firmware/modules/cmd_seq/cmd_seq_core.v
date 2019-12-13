/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module cmd_seq_core #(
    parameter                   ABUSWIDTH = 16,
    parameter                   OUTPUTS = 1,  // from (0 : 8]
    parameter                   CMD_MEM_SIZE = 2048  // max. 8192-1 bytes
) (
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire [ABUSWIDTH-1:0]  BUS_ADD,
    input wire [7:0]            BUS_DATA_IN,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    output reg [7:0]            BUS_DATA_OUT,

    output wire [OUTPUTS-1:0]   CMD_CLK_OUT,
    input wire                  CMD_CLK_IN,
    input wire                  CMD_EXT_START_FLAG,
    output wire                 CMD_EXT_START_ENABLE,
    output wire [OUTPUTS-1:0]   CMD_DATA,
    output reg                  CMD_READY,
    output reg                  CMD_START_FLAG
);

localparam VERSION = 1;

generate
if (OUTPUTS > 8) begin
    illegal_outputs_parameter non_existing_module();
end
endgenerate
generate
if (CMD_MEM_SIZE > 8191) begin
    illegal_outputs_parameter non_existing_module();
end
endgenerate
// IEEE Std 1800-2009
// generate
// if (CONDITION > MAX_ALLOWED) begin
//     $error("%m ** Illegal Condition ** CONDITION(%d) > MAX_ALLOWED(%d)", CONDITION, MAX_ALLOWED);
// end
// endgenerate

`include "../includes/log2func.v"
localparam CMD_ADDR_SIZE = `CLOG2(CMD_MEM_SIZE);

wire SOFT_RST; //0
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

// reset sync
// when write to addr = 0 then reset
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
    .CLK_B(CMD_CLK_IN),
    .FLAG_IN_CLK_A(RST),
    .FLAG_OUT_CLK_B(RST_CMD_CLK)
);

wire CONF_START; // 1
assign CONF_START = (BUS_ADD==1 && BUS_WR);

wire CONF_START_FLAG_SYNC;
flag_domain_crossing conf_start_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(CMD_CLK_IN),
    .FLAG_IN_CLK_A(CONF_START),
    .FLAG_OUT_CLK_B(CONF_START_FLAG_SYNC)
);

reg [0:0] CONF_READY; // 1
wire CONF_EN_EXT_START, CONF_DIS_CLOCK_GATE, CONF_DIS_CMD_PULSE; // 2
wire [1:0] CONF_OUTPUT_MODE; // 2 Mode == 0: posedge, 1: negedge, 2: Manchester Code according to IEEE 802.3, 3:  Manchester Code according to G.E. Thomas aka Biphase-L or Manchester-II
wire [15:0] CONF_CMD_SIZE; // 3 - 4
wire [31:0] CONF_REPEAT_COUNT; // 5 - 8
wire [15:0] CONF_START_REPEAT; // 9 - 10
wire [15:0] CONF_STOP_REPEAT; // 11 - 12
wire [7:0] CONF_OUTPUT_ENABLE; //13

// ATTENTION:
// -(CONF_CMD_SIZE - CONF_START_REPEAT - CONF_STOP_REPEAT) must be greater than or equal to 2
// - CONF_START_REPEAT must be greater than or equal to 2
// - CONF_STOP_REPEAT must be greater than or equal to 2
reg [7:0] status_regs [13:0];

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 8'b0000_0000;
        status_regs[3] <= 0;
        status_regs[4] <= 0;
        status_regs[5] <= 8'd1; // CONF_REPEAT_COUNT, repeat once by default
        status_regs[6] <= 0;
        status_regs[7] <= 0;
        status_regs[8] <= 0;
        status_regs[9] <= 0; // CONF_START_REPEAT
        status_regs[10] <= 0;
        status_regs[11] <= 0;// CONF_STOP_REPEAT
        status_regs[12] <= 0;
        status_regs[13] <= 8'hff; //OUTPUT_EN
    end
    else if(BUS_WR && BUS_ADD < 14)
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
end

assign CONF_CMD_SIZE = {status_regs[4], status_regs[3]};
assign CONF_REPEAT_COUNT = {status_regs[8], status_regs[7], status_regs[6], status_regs[5]};
assign CONF_START_REPEAT = {status_regs[10], status_regs[9]};
assign CONF_STOP_REPEAT = {status_regs[12], status_regs[11]};
assign CONF_OUTPUT_ENABLE = status_regs[13];

assign CONF_DIS_CMD_PULSE = status_regs[2][4];
assign CONF_DIS_CLOCK_GATE = status_regs[2][3];
assign CONF_OUTPUT_MODE = status_regs[2][2:1];
assign CONF_EN_EXT_START = status_regs[2][0];


three_stage_synchronizer conf_en_ext_start_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_EN_EXT_START),
    .OUT(CMD_EXT_START_ENABLE)
);

wire [15:0] CONF_CMD_SIZE_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(16)
) cmd_size_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_CMD_SIZE),
    .OUT(CONF_CMD_SIZE_CMD_CLK)
);

wire [31:0] CONF_REPEAT_COUNT_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(32)
) repeat_cnt_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_REPEAT_COUNT),
    .OUT(CONF_REPEAT_COUNT_CMD_CLK)
);

wire [15:0] CONF_START_REPEAT_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(16)
) start_repeat_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_START_REPEAT),
    .OUT(CONF_START_REPEAT_CMD_CLK)
);

wire [15:0] CONF_STOP_REPEAT_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(16)
) stop_repeat_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_STOP_REPEAT),
    .OUT(CONF_STOP_REPEAT_CMD_CLK)
);

wire [OUTPUTS-1:0] CONF_OUTPUT_ENABLE_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(OUTPUTS)
) conf_output_enable_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_OUTPUT_ENABLE[OUTPUTS-1:0]),
    .OUT(CONF_OUTPUT_ENABLE_CMD_CLK)
);

wire CONF_DIS_CMD_PULSE_CMD_CLK;
three_stage_synchronizer conf_dis_cmd_pulse_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_DIS_CMD_PULSE),
    .OUT(CONF_DIS_CMD_PULSE_CMD_CLK)
);

wire CONF_DIS_CLOCK_GATE_CMD_CLK;
three_stage_synchronizer conf_dis_clock_gate_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_DIS_CLOCK_GATE),
    .OUT(CONF_DIS_CLOCK_GATE_CMD_CLK)
);

wire [1:0] CONF_OUTPUT_MODE_CMD_CLK;
three_stage_synchronizer #(
    .WIDTH(2)
) conf_output_mode_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_OUTPUT_MODE),
    .OUT(CONF_OUTPUT_MODE_CMD_CLK)
);

wire [7:0] CMD_MEM_DATA;
always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= {7'b0, CONF_READY};
        else if(BUS_ADD < 14)
            BUS_DATA_OUT <= status_regs[BUS_ADD[3:0]];
        else if(BUS_ADD < 16)
            BUS_DATA_OUT <= 8'b0;
        else if(BUS_ADD < (16 + CMD_MEM_SIZE))
            BUS_DATA_OUT <= CMD_MEM_DATA;
    end
end

// (* RAM_STYLE="{BLOCK}" *)
reg [7:0] cmd_mem [0:CMD_MEM_SIZE-1];
always @(posedge BUS_CLK) begin
    if (BUS_WR && BUS_ADD >= 16 && BUS_ADD < (16 + CMD_MEM_SIZE))
        cmd_mem[BUS_ADD - 16] <= BUS_DATA_IN;
end

reg [CMD_ADDR_SIZE-1:0] CMD_MEM_ADD;
assign CMD_MEM_DATA = cmd_mem[BUS_RD && BUS_ADD >= 16 && BUS_ADD < (16 + CMD_MEM_SIZE) ? (BUS_ADD - 16) : CMD_MEM_ADD];

wire EXT_START_FLAG;
assign EXT_START_FLAG = (CMD_EXT_START_FLAG & CMD_EXT_START_ENABLE);
wire send_cmd;
assign send_cmd = CONF_START_FLAG_SYNC | EXT_START_FLAG;

localparam WAIT = 0, SEND = 1;

reg [15:0] cnt;
reg [31:0] repeat_cnt;
reg state, next_state;

always @(posedge CMD_CLK_IN)
    if (RST_CMD_CLK)
        state <= WAIT;
    else
        state <= next_state;

// reg END_SEQ_REP_NEXT, END_SEQ_REP;
// always @(*) begin
//     if((repeat_cnt < CONF_REPEAT_COUNT_CMD_CLK || CONF_REPEAT_COUNT_CMD_CLK == 0) && cnt == CONF_CMD_SIZE_CMD_CLK - 1 - CONF_STOP_REPEAT_CMD_CLK && !END_SEQ_REP)
//         END_SEQ_REP_NEXT = 1;
//     else
//         END_SEQ_REP_NEXT = 0;
// end

// always @(posedge CMD_CLK_IN)
//     END_SEQ_REP <= END_SEQ_REP_NEXT;

reg START_STOP_REPEAT_OK;
always @(posedge CMD_CLK_IN)
    if ((CONF_START_REPEAT_CMD_CLK + CONF_STOP_REPEAT_CMD_CLK) > CONF_CMD_SIZE_CMD_CLK)
        START_STOP_REPEAT_OK <= 1'b0;
    else
        START_STOP_REPEAT_OK <= 1'b1;

reg [31:0] SET_REPEAT_COUNT;
always @(posedge CMD_CLK_IN)
    if (CONF_START_REPEAT_CMD_CLK + CONF_STOP_REPEAT_CMD_CLK == CONF_CMD_SIZE_CMD_CLK)
        SET_REPEAT_COUNT <= 1;
    else
        SET_REPEAT_COUNT <= CONF_REPEAT_COUNT_CMD_CLK;

always @(*) begin
    case (state)
        WAIT:
            if (send_cmd && CONF_CMD_SIZE_CMD_CLK != 0 && START_STOP_REPEAT_OK)
                next_state = SEND;
            else
                next_state = WAIT;
        SEND:
            if (cnt >= CONF_CMD_SIZE_CMD_CLK && repeat_cnt >= SET_REPEAT_COUNT && SET_REPEAT_COUNT != 0)
                next_state = WAIT;
            else
                next_state = SEND;
        default:
            next_state = WAIT;
    endcase
end

always @(posedge CMD_CLK_IN) begin
    if (RST_CMD_CLK) begin
        cnt <= 0;
    end else begin
        if (next_state == WAIT) begin
            cnt <= 0;  // TODO: adding start value here
        end else begin
            if ((repeat_cnt < SET_REPEAT_COUNT || SET_REPEAT_COUNT == 0) && (cnt == CONF_CMD_SIZE_CMD_CLK - CONF_STOP_REPEAT_CMD_CLK - 1)) begin
                cnt <= CONF_START_REPEAT_CMD_CLK;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
end

always @(posedge CMD_CLK_IN) begin
    if (RST_CMD_CLK)
        repeat_cnt <= 1;
    else
        if (next_state == WAIT)
            repeat_cnt <= 1;
        else if ((next_state == SEND) && (cnt == CONF_CMD_SIZE_CMD_CLK - CONF_STOP_REPEAT_CMD_CLK - 1))
            repeat_cnt <= repeat_cnt + 1;
end

// always @(posedge CMD_CLK_IN) begin
//     if (RST_CMD_CLK) begin
//         CMD_MEM_ADD <= 0;
//     end else begin
//         CMD_MEM_ADD <= cnt / 8;
//     end
// end

// reg cmd_data_ser;
// always @(posedge CMD_CLK_IN) begin
//     if (state == WAIT)
//         cmd_data_ser <= 1'b0;
//     else
//         cmd_data_ser <= CMD_MEM_DATA[7 - ((cnt_buf) % 8)];
// end

always @(posedge CMD_CLK_IN) begin
    if (RST_CMD_CLK) begin
        CMD_MEM_ADD <= 0;
    end else begin
        if (cnt == CONF_CMD_SIZE_CMD_CLK - CONF_STOP_REPEAT_CMD_CLK - 1 && repeat_cnt < SET_REPEAT_COUNT && SET_REPEAT_COUNT != 0) begin
            CMD_MEM_ADD <= CONF_START_REPEAT_CMD_CLK / 8;
        end else begin
        // if ()
            CMD_MEM_ADD <= (cnt + 1) / 8;
        end
    end
end

reg [7:0] CMD_MEM_DATA_BUF;
always @(posedge CMD_CLK_IN) begin
    CMD_MEM_DATA_BUF <= CMD_MEM_DATA;
end

reg [15:0] cnt_buf;
always @(posedge CMD_CLK_IN) begin
    cnt_buf <= cnt;
end

reg cmd_data_ser;
always @(posedge CMD_CLK_IN) begin
    if (state == WAIT)
        cmd_data_ser <= 1'b0;
    else
        cmd_data_ser <= CMD_MEM_DATA_BUF[7 - ((cnt_buf) % 8)];
end

reg [OUTPUTS-1:0] cmd_data_neg;
reg [OUTPUTS-1:0] cmd_data_pos;
always @(negedge CMD_CLK_IN)
    cmd_data_neg <= {OUTPUTS{cmd_data_ser}} & CONF_OUTPUT_ENABLE_CMD_CLK;

always @(posedge CMD_CLK_IN)
    cmd_data_pos <= {OUTPUTS{cmd_data_ser}} & CONF_OUTPUT_ENABLE_CMD_CLK;


genvar k;
generate
    for (k = 0; k < OUTPUTS; k = k + 1) begin: gen
        ODDR MANCHESTER_CODE_INST (
            .Q(CMD_DATA[k]),
            .C(CMD_CLK_IN),
            .CE(1'b1),
            .D1((CONF_OUTPUT_MODE_CMD_CLK == 2'b00) ? cmd_data_pos[k] : ((CONF_OUTPUT_MODE_CMD_CLK == 2'b01) ? cmd_data_neg[k] : ((CONF_OUTPUT_MODE_CMD_CLK == 2'b10) ? ~cmd_data_pos[k] :  cmd_data_pos[k]))),
            .D2((CONF_OUTPUT_MODE_CMD_CLK == 2'b00) ? cmd_data_pos[k] : ((CONF_OUTPUT_MODE_CMD_CLK == 2'b01) ? cmd_data_neg[k] : ((CONF_OUTPUT_MODE_CMD_CLK == 2'b10) ?  cmd_data_pos[k] : ~cmd_data_pos[k]))),
            .R(1'b0),
            .S(1'b0)
        );

        ODDR CMD_CLK_FORWARDING_INST (
            .Q(CMD_CLK_OUT[k]),
            .C(CMD_CLK_IN),
            .CE(1'b1),
            .D1(1'b1),
            .D2(1'b0),
            .R(CONF_DIS_CLOCK_GATE_CMD_CLK),
            .S(1'b0)
        );
    end
endgenerate

// ready signal
always @(posedge CMD_CLK_IN)
    CMD_READY <= ~next_state;

// command start flag
reg CMD_START_SIGNAL;
always @(posedge CMD_CLK_IN)
    if (state == SEND && cnt_buf == CONF_START_REPEAT_CMD_CLK && CONF_DIS_CMD_PULSE_CMD_CLK == 1'b0)
        CMD_START_SIGNAL <= 1'b1;
    else
        CMD_START_SIGNAL <= 1'b0;

reg CMD_START_SIGNAL_FF, CMD_START_SIGNAL_FF2;
always @(posedge CMD_CLK_IN) begin
    CMD_START_SIGNAL_FF <= CMD_START_SIGNAL;
    CMD_START_SIGNAL_FF2 <= CMD_START_SIGNAL_FF;
end

always @(posedge CMD_CLK_IN)
    if (CONF_OUTPUT_MODE_CMD_CLK == 2'b00)
        CMD_START_FLAG <= ~CMD_START_SIGNAL_FF2 & CMD_START_SIGNAL_FF;  // delay by 1, 180 degree phase shifted data in output mode 0
    else
        CMD_START_FLAG <= ~CMD_START_SIGNAL_FF & CMD_START_SIGNAL;

// command start flag
reg CMD_BUSY_FLAG;
always @(posedge CMD_CLK_IN)
    if (state != next_state && next_state == SEND)
        CMD_BUSY_FLAG <= 1'b1;
    else
        CMD_BUSY_FLAG <= 1'b0;

// ready flag
reg CMD_READY_FLAG;
always @(posedge CMD_CLK_IN)
    if (state != next_state && next_state == WAIT)
        CMD_READY_FLAG <= 1'b1;
    else
        CMD_READY_FLAG <= 1'b0;

wire CMD_BUSY_FLAG_BUS_CLK;
flag_domain_crossing cmd_busy_flag_domain_crossing (
    .CLK_A(CMD_CLK_IN),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(CMD_BUSY_FLAG),
    .FLAG_OUT_CLK_B(CMD_BUSY_FLAG_BUS_CLK)
);

wire CMD_READY_FLAG_BUS_CLK;
flag_domain_crossing cmd_ready_flag_domain_crossing (
    .CLK_A(CMD_CLK_IN),
    .CLK_B(BUS_CLK),
    .FLAG_IN_CLK_A(CMD_READY_FLAG),
    .FLAG_OUT_CLK_B(CMD_READY_FLAG_BUS_CLK)
);

always @(posedge BUS_CLK)
    if(RST)
        CONF_READY <= 1;
    else
        if(CMD_BUSY_FLAG_BUS_CLK || CONF_START)
            CONF_READY <= 0;
        else if(CMD_READY_FLAG_BUS_CLK)
            CONF_READY <= 1;

endmodule
