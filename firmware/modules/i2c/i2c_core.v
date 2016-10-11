/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module i2c_core #(
    parameter ABUSWIDTH = 16,
    parameter MEM_BYTES = 1
)(
    input wire BUS_CLK,
    input wire BUS_RST,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    input wire BUS_RD,
    input wire BUS_WR,
    output reg [7:0] BUS_DATA_OUT,
    
    input wire I2C_CLK,
    inout wire I2C_SDA,
    inout wire I2C_SCL

);

localparam VERSION = 1;

reg [7:0] status_regs [7:0];

wire RST;
wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign RST = BUS_RST || SOFT_RST;

wire START;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);


always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0; //rst/version
        status_regs[1] <= 0; //status
        status_regs[2] <= 0; //addr
        status_regs[3] <= MEM_BYTES[7:0]; //size
        status_regs[4] <= MEM_BYTES[15:8]; //size
        status_regs[5] <= 0; //size2
        status_regs[6] <= 0;
        status_regs[7] <= 0;
    end
    else if(BUS_WR && BUS_ADD < 8)
        status_regs[BUS_ADD[2:0]] <= BUS_DATA_IN; 
end

wire [7:0] I2C_ADD;
assign I2C_ADD = status_regs[2];

reg SDA_READBACK;

wire [15:0] CONF_SIZE;
assign CONF_SIZE = {status_regs[4], status_regs[3]};


wire [7:0] BUS_STATUS_OUT;
assign BUS_STATUS_OUT = status_regs[BUS_ADD[3:0]];

reg CONF_DONE;
reg CONF_NO_ACK;

reg [7:0] BUS_DATA_OUT_REG;
always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT_REG <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT_REG <= {6'b0, CONF_NO_ACK, CONF_DONE};
        else if(BUS_ADD == 6)
            BUS_DATA_OUT_REG <= MEM_BYTES[7:0];
        else if(BUS_ADD == 7)
            BUS_DATA_OUT_REG <= MEM_BYTES[15:8];
        else if(BUS_ADD < 8)
            BUS_DATA_OUT_REG <= BUS_STATUS_OUT;
    end
end

reg [ABUSWIDTH-1:0]  PREV_BUS_ADD;
always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        PREV_BUS_ADD <= BUS_ADD;
    end
end

reg [7:0] OUT_MEM;    
always @(*) begin
    if(PREV_BUS_ADD < 8)
        BUS_DATA_OUT = BUS_DATA_OUT_REG;
    else if(PREV_BUS_ADD < 8 + MEM_BYTES )
        BUS_DATA_OUT = OUT_MEM;
    else
        BUS_DATA_OUT = 8'hxx;
end

wire BUS_MEM_EN;
wire [ABUSWIDTH-1:0] BUS_MEM_ADD; 

assign BUS_MEM_EN = (BUS_WR | BUS_RD) & BUS_ADD >= 8;
assign BUS_MEM_ADD = BUS_ADD-8;

(* RAM_STYLE="{BLOCK_POWER2}" *)
reg [7:0] mem [MEM_BYTES-1:0];

always @(posedge BUS_CLK)
    if (BUS_MEM_EN) begin
        if (BUS_WR)
            mem[BUS_MEM_ADD] <= BUS_DATA_IN;
        OUT_MEM <= mem[BUS_MEM_ADD];
    end

wire EN_MEM_I2C;
wire WE_MEM_I2C;

reg [2:0] bit_count;
reg [15:0] byte_count;
wire [15:0] MEM_I2_WR; 
reg [1:0] div_cnt;

reg [7:0] DATA_BYTE;
reg [7:0] DATA_BYTE_READBCK;

assign MEM_I2_WR = WE_MEM_I2C ? byte_count-1: byte_count;

always @(posedge I2C_CLK)
    if (EN_MEM_I2C) begin
        if (WE_MEM_I2C)
            mem[MEM_I2_WR] <= DATA_BYTE_READBCK;
        DATA_BYTE <= mem[MEM_I2_WR];
    end

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(I2C_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(I2C_CLK), .pulse_out(START_SYNC));


reg START_FSM;

localparam STATE_IDLE  = 0, STATE_START = 1, STATE_ADDR = 2, STATE_RW = 3, STATE_AACK = 4, STATE_DATA_W = 5, STATE_DATA_R = 6, STATE_DACK_W = 7, STATE_DACK_R = 8, STATE_DACK_LAST = 9, STATE_STOP = 10;

always @ (posedge I2C_CLK) begin
    if (RST_SYNC)
        START_FSM <= 0;
    else if(START_SYNC)
        START_FSM <= 1;
    else if(div_cnt == 3 && START_FSM)
        START_FSM <= 0;
end

reg [3:0] state, next_state;

always @ (posedge I2C_CLK) begin
    if (RST_SYNC)
        state <= STATE_IDLE;
    else if(div_cnt==3)
        state <= next_state;
end

wire CONF_MODE;
assign CONF_MODE = I2C_ADD[0];

always @ (*) begin
    next_state = state; //default
    case(state)
        STATE_IDLE: 
            if(START_FSM)
                next_state = STATE_START;
        STATE_START:
                next_state = STATE_ADDR;
        STATE_ADDR:
            if(bit_count==7) 
                next_state = STATE_AACK;
        STATE_AACK:
            if(SDA_READBACK==0) begin
                if(CONF_MODE)
                    next_state = STATE_DATA_R;
                else
                    next_state = STATE_DATA_W;
            end
            else
                next_state = STATE_IDLE;
        STATE_DATA_R:
            if(bit_count==7)
                next_state = STATE_DACK_R;
        STATE_DATA_W:
            if(bit_count==7)
                next_state = STATE_DACK_W;
        STATE_DACK_W:
            begin
                if(byte_count == CONF_SIZE) begin
                    if(SDA_READBACK==0)
                        next_state = STATE_STOP;
                    else
                        next_state = STATE_IDLE;
                end
                else
                    next_state = STATE_DATA_W;
            end
        STATE_DACK_R:
            if(byte_count == CONF_SIZE)
                next_state = STATE_STOP;
            else
                next_state = STATE_DATA_R;
        STATE_STOP:
            next_state = STATE_IDLE;
    endcase
end

always @ (posedge I2C_CLK) begin
    if (state == STATE_AACK | state == STATE_START | state == STATE_DACK_W | state == STATE_DACK_R)
        bit_count <= 0;
    else if(div_cnt==3)
        bit_count <= bit_count + 1;
end

always @ (posedge I2C_CLK) begin
    if (state == STATE_IDLE)
        byte_count <= 0;
    else if((next_state == STATE_DACK_W | next_state == STATE_DACK_R) & div_cnt==3)
        byte_count <= byte_count + 1;
end

always @ (posedge I2C_CLK) begin
    if (RST_SYNC)
        div_cnt <= 0;
    else
        div_cnt <= div_cnt + 1;
end

assign WE_MEM_I2C = (state == STATE_DACK_R  & div_cnt==2);
assign EN_MEM_I2C = WE_MEM_I2C | ((state == STATE_DACK_W | state == STATE_AACK) & div_cnt==2);

reg SDA_D0;
reg SCL_D0;

always @ (*) begin
    SDA_D0 = 1;
    SCL_D0 = 1;
    
    case(state)
        STATE_START:
            begin
                SDA_D0 = 0;
                SCL_D0 = 0;
            end
        STATE_ADDR:
            begin
                SCL_D0 = 0;
                SDA_D0 = I2C_ADD[7-bit_count];
            end
        STATE_AACK:
            SCL_D0 = 0;
        STATE_DATA_R:
            SCL_D0 = 0;
        STATE_DATA_W:
            begin
                SCL_D0 = 0;
                SDA_D0 = DATA_BYTE[7-bit_count];
            end
        STATE_DACK_W:
                SCL_D0 = 0;
        STATE_DACK_R:
            begin
                SCL_D0 = 0;
                if(byte_count != CONF_SIZE)
                    SDA_D0 = 0;
            end
        STATE_STOP:
            begin
                SDA_D0 = 0;
            end
    endcase
end

wire SLAVE_ACK;

wire NO_ACK;
assign NO_ACK = ((state == STATE_AACK & SDA_READBACK) | (state == STATE_DACK_W & SDA_READBACK)) & div_cnt == 3;  

reg SDA;
always@(posedge I2C_CLK)
    if(div_cnt == 0)
        SDA <= SDA_D0;

assign I2C_SDA = SDA ? 1'bz : 1'b0;

reg SCL;
always@(posedge I2C_CLK)
    if(div_cnt == 3)
        SCL <= SCL_D0;
    else if(div_cnt == 1)
        SCL <= 1;

assign I2C_SCL = SCL ? 1'bz : 1'b0;

always@(posedge I2C_CLK)
    if(div_cnt == 1)
        SDA_READBACK <= I2C_SDA;
        
always@(posedge I2C_CLK)
    if(div_cnt == 3)
        DATA_BYTE_READBCK[7-bit_count] <= I2C_SDA;
   
wire DONE;
assign DONE = (state == STATE_STOP);

wire DONE_SYNC;
cdc_pulse_sync done_pulse_sync (.clk_in(I2C_CLK), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));


always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(START)
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;

wire NO_ACK_SYNC;
cdc_pulse_sync ack_pulse_sync (.clk_in(I2C_CLK), .pulse_in(NO_ACK), .clk_out(BUS_CLK), .pulse_out(NO_ACK_SYNC));        
        
always @(posedge BUS_CLK)
    if(RST)
        CONF_NO_ACK <= 0;
    else if(START)
        CONF_NO_ACK <= 0;
    else if(NO_ACK_SYNC)
        CONF_NO_ACK <= 1;
        
        
endmodule
