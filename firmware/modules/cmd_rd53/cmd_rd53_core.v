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

    input wire                  CMD_CLK,
    output reg					CMD_SERIAL_OUT
//    output reg [7:0]			CMD_DATA_OUT
);

localparam VERSION = 1;
localparam REGSIZE = 16;
localparam BRAM_ABUSWIDTH = 10;
localparam CMD_MEM_SIZE = 2**BRAM_ABUSWIDTH;
//localparam SYNC_CYCLES_INITIALSYNC = 32;

wire [15:0] SYNC_PATTERN;
assign SYNC_PATTERN = 16'b1000000101111110;

reg [7:0] sync_cycle_cnt = 8'h00;
reg [15:0] repeat_cnt = 16'h0000;
reg data_pending = 1'b0;
reg SYNCING = 1'b0;
reg serdes_next_byte = 1'b0;
reg serializer_active = 1'b1;
reg [7:0] CMD_DATA_OUT_SR = 8'h00;

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
cdc_reset_sync rst_reset_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(CMD_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(CMD_CLK), .pulse_out(START_SYNC));


// wire CONF_EN_EXT_START;
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
            BUS_DATA_OUT_REG <= {6'b0, SYNCING, CONF_DONE};
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
        BUS_DATA_OUT_REG <= 8'h00;
end

// wait cycle for bram ???
reg [ABUSWIDTH-1:0] PREV_BUS_ADD = 16'h0000;
always @ (posedge BUS_CLK) begin
    if(BUS_RD)
        PREV_BUS_ADD <= BUS_ADD;
    else
	    PREV_BUS_ADD <= 16'h0000;
end


// Mux: RAM, registers
reg [7:0] OUT_MEM;
reg OUT_SR;
always @(*) begin
    if(PREV_BUS_ADD < REGSIZE)
        BUS_DATA_OUT = BUS_DATA_OUT_REG;
    else if(PREV_BUS_ADD < REGSIZE + CMD_MEM_SIZE)
        BUS_DATA_OUT = OUT_MEM;
    else
        BUS_DATA_OUT = 8'hxx;
end


//DIFFERENT METHOD
reg [BRAM_ABUSWIDTH-1:0] read_address = 0;

// BRAM
wire BUS_MEM_EN;
wire [ABUSWIDTH-1:0] BUS_MEM_ADD;

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
//reg [7:0] OUT_MEM_CMD_CLK;
//always @ (posedge CMD_CLK)
//    OUT_MEM_CMD_CLK <= mem[read_address];

// FSM
reg START_FSM;
localparam STATE_INIT  = 0, STATE_IDLE = 1, STATE_SYNC = 2, STATE_DATA_WRITE = 3;

reg [3:0] state, next_state;


always @ (posedge CMD_CLK) begin
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
    else if(data_pending==0 && serdes_next_byte)
        CONF_DONE <= 1;
    else if((START || state==STATE_DATA_WRITE) && serdes_next_byte)
        CONF_DONE <= 0;


always @ (posedge CMD_CLK) begin
    if (RST_SYNC)
        state <= STATE_INIT;
    else
        state <= next_state;
end


always @ (*) begin
    next_state = state;
    case(state)
        STATE_INIT:
            if(START_FSM)
                next_state = STATE_IDLE;

        STATE_IDLE: begin
			if(data_pending)
                next_state = STATE_DATA_WRITE;
			else
				next_state = STATE_SYNC;
        end

        STATE_SYNC:
            if(data_pending)
	            next_state = STATE_DATA_WRITE;

        STATE_DATA_WRITE:
            if(repeat_cnt >= CONF_REPEAT_COUNT)
	            next_state = STATE_SYNC;

    endcase
end



//SYNC_PATTERN
reg [7:0] sync_halfpattern = 8'h00;
always @ (posedge CMD_CLK) begin
    if(state==STATE_SYNC) begin
        if (sync_cycle_cnt[0])
            sync_halfpattern <= SYNC_PATTERN[7:0];
        else
            sync_halfpattern <= SYNC_PATTERN[15:8];
        if(serdes_next_byte)
        	sync_cycle_cnt <= sync_cycle_cnt + 1;
        end
    if(state!=STATE_SYNC || next_state!=STATE_SYNC)
        sync_cycle_cnt <= 8'h00;
end


//MUX
always @ (posedge CMD_CLK) begin
    if(state==STATE_SYNC) begin
//	    CMD_DATA_OUT = sync_halfpattern;
        CMD_DATA_OUT_SR = sync_halfpattern;
	    CMD_SERIAL_OUT <= OUT_SR;
	    end
    else if(state==STATE_DATA_WRITE) begin
//	    CMD_DATA_OUT = mem[read_address];
        CMD_DATA_OUT_SR = mem[read_address];
        CMD_SERIAL_OUT <= OUT_SR;
	    end
    else if(state==STATE_IDLE) begin
//	    CMD_DATA_OUT = 8'h00;
        CMD_DATA_OUT_SR = 8'h00;
	    CMD_SERIAL_OUT <= OUT_SR;
	    end
end


//data_pending flag
always @ (posedge BUS_CLK) begin
	if(START && CONF_CMD_SIZE)
    	data_pending <= 1;
	else if(state==STATE_DATA_WRITE && next_state!=STATE_DATA_WRITE) //
       	data_pending <= 0;
end


always @ (posedge BUS_CLK) begin
	if(state==STATE_INIT)
		serializer_active <= 1'b0;
	else
		serializer_active <= 1'b1;
end


//SERIALIZER (LSB first)
reg [7:0] serializer_shift_register;
reg [2:0] serdes_cnt = 3'b000;
always @ (posedge CMD_CLK) begin
	if(serializer_active) begin
		serializer_shift_register <= {1'b0, serializer_shift_register [7:1]};	//MSB first: "[6:0], 1'b0"
		if(serdes_cnt == 3'b111) begin
			serdes_next_byte <= 1;
			serializer_shift_register <= CMD_DATA_OUT_SR;
			serdes_cnt <= 3'b000;
		end
		else begin
			serdes_cnt <= serdes_cnt + 1;	//MSB first: "- 1"
			serdes_next_byte <= 0;
		end

		OUT_SR <= serializer_shift_register[0];	//MSB first: "[7]"
	end
	else
		serdes_cnt <= 3'b000;

end


//DATA_WRITE
always @ (posedge CMD_CLK) begin
    if(state==STATE_DATA_WRITE) begin
    	if(serdes_next_byte) begin
	        if(read_address < CONF_CMD_SIZE-1)
           		read_address <= read_address + 1;
	        else begin
	            read_address <= 10'b0;
		        if(repeat_cnt == CONF_REPEAT_COUNT)
			        repeat_cnt <= 16'h0000;
		        else
			        repeat_cnt <= repeat_cnt + 1;
	        end
    	end
    else
	    repeat_cnt <= 16'h0000;
    end
end

endmodule
