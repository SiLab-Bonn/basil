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

`timescale 1 ps / 1ps
`default_nettype none

module cmd_seq_core
#(
    parameter                   CMD_MEM_SIZE = 2048
) (
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire [15:0]           BUS_ADD,
    input wire [7:0]            BUS_DATA_IN,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    output reg [7:0]            BUS_DATA_OUT,
    
    output wire                 CMD_CLK_OUT,
    input wire                  CMD_CLK_IN,
    input wire                  CMD_EXT_START_FLAG,
    output wire                 CMD_EXT_START_ENABLE,
    output wire                 CMD_DATA,
    output reg                  CMD_READY,
    output reg                  CMD_START_FLAG
);

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

wire START; //1
assign START = (BUS_ADD==1 && BUS_WR);

// start sync
// when write to addr = 1 then send command
reg START_FF, START_FF2;
always @(posedge BUS_CLK) begin
    START_FF <= START;
    START_FF2 <= START_FF;
end

wire START_FLAG;
assign START_FLAG = ~START_FF2 & START_FF;

wire start_sync;
flag_domain_crossing cmd_start_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(CMD_CLK_IN),
    .FLAG_IN_CLK_A(START_FLAG),
    .FLAG_OUT_CLK_B(start_sync)
);

wire CONF_FINISH; //1
wire CONF_EN_EXT_START, CONF_DIS_CLOCK_GATE, CONF_EN_NEGEDGE_DATA, CONF_DIS_CMD_PULSE; //2
wire [15:0] CONF_CMD_SIZE; //3 - 4
wire [31:0] CONF_REPEAT_COUNT; //5 - 6

reg [7:0] status_regs[15:0];

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 8'b0000_0000;
        status_regs[3] <= 0;
        status_regs[4] <= 0;
        status_regs[5] <= 8'd1; // repeat once by default
        status_regs[6] <= 0;
        status_regs[7] <= 0;
        status_regs[8] <= 0;
        status_regs[9] <= 0;
        status_regs[10] <= 0;
        status_regs[11] <= 0;
        status_regs[12] <= 0;
        status_regs[13] <= 0;
        status_regs[14] <= 0;
        status_regs[15] <= 0;
    end
    else if(BUS_WR && BUS_ADD < 16)
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
end


assign CONF_CMD_SIZE = {status_regs[4], status_regs[3]};
assign CONF_REPEAT_COUNT = {status_regs[8], status_regs[7], status_regs[6], status_regs[5]};

assign CONF_DIS_CMD_PULSE = status_regs[2][3];
assign CONF_DIS_CLOCK_GATE = status_regs[2][2]; // no clock domain crossing needed
assign CONF_EN_NEGEDGE_DATA = status_regs[2][1]; // no clock domain crossing needed
assign CONF_EN_EXT_START = status_regs[2][0];

wire CONF_DIS_CMD_PULSE_CMD_CLK;
three_stage_synchronizer conf_dis_cmd_pulse_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_DIS_CMD_PULSE),
    .OUT(CONF_DIS_CMD_PULSE_CMD_CLK)
);

three_stage_synchronizer conf_en_ext_start_sync (
    .CLK(CMD_CLK_IN),
    .IN(CONF_EN_EXT_START),
    .OUT(CMD_EXT_START_ENABLE)
);

(* RAM_STYLE="{AUTO | BLOCK | BLOCK_POWER1 | BLOCK_POWER2}" *)
reg [7:0] cmd_mem [CMD_MEM_SIZE-1:0];
always @ (negedge BUS_CLK) begin
    if(BUS_ADD == 1)
        BUS_DATA_OUT <= {7'b0, CONF_FINISH};
    else if(BUS_ADD < 16)
        BUS_DATA_OUT <= status_regs[BUS_ADD[3:0]];
    else if(BUS_ADD < CMD_MEM_SIZE)
        BUS_DATA_OUT <= cmd_mem[BUS_ADD[10:0]-16];
    else
        BUS_DATA_OUT <= 8'b0;
end

always @ (posedge BUS_CLK) begin
    if (BUS_WR && BUS_ADD >= 16)
        cmd_mem[BUS_ADD[10:0]-16] <= BUS_DATA_IN;
end
        
reg [7:0] CMD_MEM_DATA;
reg [10:0] CMD_MEM_ADD;
always @(posedge CMD_CLK_IN)
    CMD_MEM_DATA <= cmd_mem[CMD_MEM_ADD];

wire ext_send_cmd;
assign ext_send_cmd = (CMD_EXT_START_FLAG & CMD_EXT_START_ENABLE);
wire send_cmd;
assign send_cmd = start_sync | ext_send_cmd;

localparam WAIT = 1, SEND = 2;

reg [15:0] cnt;
reg [31:0] repeat_cnt;
reg [2:0] state, next_state;

always @ (posedge CMD_CLK_IN)
    if (RST_CMD_CLK)
      state <= WAIT;
    else
      state <= next_state;
  
always @ (*) begin
    case(state)
        WAIT : if(send_cmd)
                    next_state = SEND;
                else
                    next_state = WAIT;
        SEND : if(cnt == CONF_CMD_SIZE && repeat_cnt==CONF_REPEAT_COUNT)
                    next_state = WAIT;
                else
                    next_state = SEND;
        default : next_state = WAIT;
    endcase
end

always @ (posedge CMD_CLK_IN) begin
    if (RST_CMD_CLK)
        cnt <= 0;
    else if(state != next_state)
        cnt <= 0;
    else if(cnt == CONF_CMD_SIZE)
        cnt <= 1;    
    else
        cnt <= cnt +1;
end

always @ (posedge CMD_CLK_IN) begin
    if (send_cmd || RST_CMD_CLK)
        repeat_cnt <= 1;
    else if(state == SEND && cnt == CONF_CMD_SIZE && repeat_cnt != 32'hffffffff)
        repeat_cnt <= repeat_cnt + 1;
end

always @ (*) begin
    if(state != next_state && next_state == SEND)
        CMD_MEM_ADD = 0;
    else if(state == SEND)
        if(cnt == CONF_CMD_SIZE-1)
            CMD_MEM_ADD = 0;
        else
            CMD_MEM_ADD = (cnt+1)/8;
    else
        CMD_MEM_ADD = 0; //no latch
end

reg [7:0] send_word;

always @ (posedge CMD_CLK_IN) begin
    if(RST_CMD_CLK)
        send_word <= 0;
    else if(state == SEND) begin
        if(next_state == WAIT)
            send_word <= 0; // by default set to output to zero (this is strange -> bug of FEI4?)
        else if(cnt == CONF_CMD_SIZE)
            send_word <= CMD_MEM_DATA;
        else if(cnt %8 == 0)
            send_word <= CMD_MEM_DATA;
        else
            send_word[7:0] <= {send_word[6:0], 1'b0};
    end
end

reg cmd_data_neg;
reg cmd_data_pos;
always @ (negedge CMD_CLK_IN)
cmd_data_neg <= send_word[7];

always @ (posedge CMD_CLK_IN)
cmd_data_pos <= send_word[7];

//assign CMD_DATA =  send_word[7];
assign CMD_DATA = CONF_EN_NEGEDGE_DATA ? cmd_data_neg : cmd_data_pos;

assign CMD_CLK_OUT = CMD_CLK_IN; // TODO: CONF_DIS_CLOCK_GATE
// wire CMD_CLK_INV_IN;
// INV CMD_CLK_INV_INST (
    // .I(CMD_CLK_IN),
    // .O(CMD_CLK_INV_IN)
// );

// OFDDRCPE CMD_CLK_FORWARDING_INST (
    // .CE(1'b1),
    // .CLR(CONF_DIS_CLOCK_GATE),
    // .C0(CMD_CLK_IN),
    // .C1(CMD_CLK_INV_IN),
    // .D0(1'b0),
    // .D1(1'b1),
    // .PRE(1'b0),
    // .Q(CMD_CLK_OUT)
// );

// command start flag
always @ (posedge CMD_CLK_IN)
    if (state == SEND && cnt == 1 && CONF_DIS_CMD_PULSE_CMD_CLK == 1'b0)
        CMD_START_FLAG <= 1'b1;
    else
        CMD_START_FLAG <= 1'b0;

// ready signal
always @ (posedge CMD_CLK_IN)
    if (state == WAIT)
        CMD_READY <= 1'b1;
    else
        CMD_READY <= 1'b0;

// ready readout sync 
three_stage_synchronizer ready_signal_sync (
    .CLK(BUS_CLK),
    .IN(CMD_READY),
    .OUT(CONF_FINISH)
);

endmodule
