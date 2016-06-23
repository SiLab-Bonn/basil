/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps

module cmd_rd53_core
#(
    parameter                   ABUSWIDTH = 16
) (
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire [ABUSWIDTH-1:0]  BUS_ADD,
    input wire [7:0]            BUS_DATA_IN,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    output reg [7:0]            BUS_DATA_OUT,

    input wire                  CMD_CLK_IN,
    output reg [7:0]			CMD_DATA_OUT
);


localparam VERSION = 1;
localparam REGSIZE = 16;
localparam BRAM_ABUSWIDTH = 10;
localparam CMD_MEM_SIZE = 2**BRAM_ABUSWIDTH;
localparam SYNC_CYCLES_INITIALSYNC = 8;
localparam SYNC_CYCLES_RESYNC = 1;
localparam SYNC_TIMEOUT_PRESET = 32;

localparam SYNC_AUTOMATICALLY = 0;	//1: Interrupt data transmission for sync pattern after timout, defined by SYNC_TIMEOUT_PRESET

wire [15:0] SYNC_PATTERN;
assign SYNC_PATTERN = 16'b1000000101111110;

reg [7:0] sync_cycle_cnt = 8'h00;
reg [7:0] sync_cycles;
reg [7:0] sync_timeout_cnt;
reg [15:0] repeat_cnt = 16'h0000;
reg data_pending = 1'b0;
reg SYNCING = 1'b0;

// flags
wire RST;
wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign RST = BUS_RST || SOFT_RST;

wire START;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);


// CDC
wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_reset_sync rst_reset_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(CMD_CLK_IN), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(CMD_CLK_IN), .pulse_out(START_SYNC));


wire CONF_EN_EXT_START;
reg CONF_DONE;

//Registers
reg [7:0] status_regs [15:0];
always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 8'b0000_0000;	// general flags and cmds
        status_regs[3] <= 0;    // CMD size
        status_regs[4] <= 0;
        status_regs[5] <= 8'd1; // CONF_REPEAT_COUNT, repeat once by default
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

//assign CONF_EN_EXT_START = status_regs[1][0];
//assign CONF_DONE = status_regs[1][1];
wire SYNC_AUTOMODE;// = 1;
assign SYNC_AUTOMODE = status_regs[2][0];
wire [15:0] CONF_CMD_SIZE;// = CMD_MEM_SIZE;     // Reg 3+4
assign CONF_CMD_SIZE = {status_regs[4], status_regs[3]};
wire [15:0] CONF_REPEAT_COUNT; // Reg 5+6
assign CONF_REPEAT_COUNT = {status_regs[6], status_regs[5]};

wire [7:0] BUS_STATUS_OUT;
assign BUS_STATUS_OUT = status_regs[BUS_ADD[3:0]];


// Map address space
reg [7:0] BUS_DATA_OUT_REG;
always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT_REG <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT_REG <= {CONF_EN_EXT_START, 4'b0, SYNC_AUTOMODE, SYNCING, CONF_DONE};
        else if(BUS_ADD == 3)
	        BUS_DATA_OUT_REG <= CONF_CMD_SIZE[7:0];
        else if(BUS_ADD == 4)
	        BUS_DATA_OUT_REG <= CONF_CMD_SIZE[15:8];
        else if(BUS_ADD == 6)
            BUS_DATA_OUT_REG <= CMD_MEM_SIZE[7:0];
        else if(BUS_ADD == 7)
            BUS_DATA_OUT_REG <= CMD_MEM_SIZE[15:8];
        else if(BUS_ADD < 8)
            BUS_DATA_OUT_REG <= BUS_STATUS_OUT;
        end
    else
        BUS_DATA_OUT_REG <= 7'h00;
end

// wait cycle for bram ???
reg [ABUSWIDTH-1:0]  PREV_BUS_ADD;
always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        PREV_BUS_ADD <= BUS_ADD;
    end
end


// Mux: RAM, registers
reg [7:0] OUT_MEM;
always @(*) begin
    if(PREV_BUS_ADD < REGSIZE)
        BUS_DATA_OUT = BUS_DATA_OUT_REG;
    else if(PREV_BUS_ADD < REGSIZE + CMD_MEM_SIZE)
        BUS_DATA_OUT = OUT_MEM;
    else
        BUS_DATA_OUT = 8'hxx;
end


reg [7:0] OUT_MEM_CMD_CLK;

//DIFFERENT METHOD
reg [BRAM_ABUSWIDTH-1:0] read_address_reg, read_address = 0;

// BRAM
wire BUS_MEM_EN;
wire [ABUSWIDTH-1:0] BUS_MEM_ADD, BUS_MEM_ADD_CMD_CLK;

assign BUS_MEM_EN = (BUS_WR | BUS_RD) & BUS_ADD >= REGSIZE;
assign BUS_MEM_ADD = BUS_ADD[BRAM_ABUSWIDTH-1:0]-REGSIZE;

(* RAM_STYLE="{BLOCK_POWER2}" *)
reg [7:0] mem [CMD_MEM_SIZE-1:0];

always @(posedge BUS_CLK)
    if (BUS_MEM_EN) begin
        if (BUS_WR)
            mem[BUS_MEM_ADD] <= BUS_DATA_IN;
        OUT_MEM <= mem[BUS_MEM_ADD];
    end
always @ (posedge CMD_CLK_IN)
    OUT_MEM_CMD_CLK <= mem[read_address];

// FSM
reg START_FSM;
localparam STATE_INIT  = 0, STATE_IDLE = 1, STATE_SYNC = 2, STATE_DATA_WRITE = 3;//, STATE_STOP = 4;

reg [3:0] state, next_state;


always @ (posedge CMD_CLK_IN) begin
    if (RST_SYNC)
        START_FSM <= 0;
    else if(START_SYNC)
        START_FSM <= 1;
    else if(START_FSM)
        START_FSM <= 0;
end

always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(SYNC_AUTOMODE==0 && state==STATE_SYNC && next_state!=STATE_SYNC && data_pending==0)
        CONF_DONE <= 1;
    else if(state==STATE_IDLE && next_state==STATE_IDLE)
        CONF_DONE <= 1;
    else if(SYNC_AUTOMODE==0 && data_pending==0)
	    CONF_DONE <= 1;
    else if(START || state==STATE_DATA_WRITE)
        CONF_DONE <= 0;

always @ (posedge CMD_CLK_IN) begin
    if (RST_SYNC)
        state <= STATE_INIT;
    else
        state <= next_state;
end

// SYNC timout
always @ (posedge CMD_CLK_IN) begin
    if(state==STATE_SYNC) begin
        sync_timeout_cnt <= 8'h00;
	    SYNCING <= 1; end
    else begin
        sync_timeout_cnt <= sync_timeout_cnt + 1;
	    SYNCING <= 0; end
end


always @ (*) begin
    next_state = state;
    case(state)
        STATE_INIT:
            if(START_FSM) begin
                sync_cycles <= SYNC_CYCLES_INITIALSYNC;
                next_state = STATE_SYNC;
            end

        STATE_IDLE: begin
            if(sync_timeout_cnt >= SYNC_TIMEOUT_PRESET) begin
                sync_cycles <= SYNC_CYCLES_RESYNC;
                next_state = STATE_SYNC;
                end
            else
			if(data_pending)
                next_state = STATE_DATA_WRITE;
        end

        STATE_SYNC:
            if(sync_cycle_cnt >= 2*sync_cycles-1)
	            if(data_pending)
		            next_state = STATE_DATA_WRITE;
	            else
		            if(SYNC_AUTOMODE)
		            	next_state = STATE_IDLE;

        STATE_DATA_WRITE:
            if(repeat_cnt >= CONF_REPEAT_COUNT) begin
	            if(SYNC_AUTOMODE)
                	next_state = STATE_IDLE;
	            else
		            next_state = STATE_SYNC;
	        	end
            else if(sync_timeout_cnt >= SYNC_TIMEOUT_PRESET && 	SYNC_AUTOMATICALLY) begin
                sync_cycles <= SYNC_CYCLES_RESYNC;
                next_state = STATE_SYNC;
                end
    endcase
end



//Split SYNC_PATTERN
reg [7:0] sync_halfpattern;
always @ (posedge CMD_CLK_IN) begin
    if(state==STATE_SYNC) begin
        if (sync_cycle_cnt[0])
            sync_halfpattern <= SYNC_PATTERN[15:8];
        else
            sync_halfpattern <= SYNC_PATTERN[7:0];
        sync_cycle_cnt <= sync_cycle_cnt + 1;
        end
    if(state!=STATE_SYNC || next_state!=STATE_SYNC)
        sync_cycle_cnt <= 8'h00;
end


//MUX
always @ (posedge CMD_CLK_IN) begin
    if(state==STATE_SYNC)
        CMD_DATA_OUT = sync_halfpattern;
    else if(state==STATE_DATA_WRITE)
        CMD_DATA_OUT = OUT_MEM_CMD_CLK;
    else if(state==STATE_IDLE)
        CMD_DATA_OUT = 8'h00;
end


//data_pending flag
always @ (posedge BUS_CLK) begin
	if(START && CONF_CMD_SIZE)// && next_state!=STATE_IDLE)
    	data_pending <= 1;
    else if(repeat_cnt >= CONF_REPEAT_COUNT || state==STATE_IDLE && next_state==STATE_IDLE)
       	data_pending <= 0;
end


//DATA_WRITE
always @ (posedge BUS_CLK) begin
    if(next_state==STATE_DATA_WRITE) begin
        if(read_address < CONF_CMD_SIZE-1)
            read_address <= read_address + 1;
        else begin
            read_address <= 10'b0;
            repeat_cnt <= repeat_cnt + 1;
        	end
      	if(repeat_cnt >= CONF_REPEAT_COUNT) begin
	        repeat_cnt <= 16'h0000;
        	read_address <= 10'b0;
      	end
    end
    if(state==STATE_DATA_WRITE) begin
	    if(repeat_cnt >= CONF_REPEAT_COUNT) begin
			repeat_cnt <= 16'h0000;
        	read_address <= 10'b0;
	    end
    end

end

endmodule