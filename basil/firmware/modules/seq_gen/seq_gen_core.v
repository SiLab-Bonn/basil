/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module seq_gen_core
#(
    parameter ABUSWIDTH = 16,
    parameter MEM_BYTES = 16384,
    parameter OUT_BITS = 16 //4,8,16,32
)(
    BUS_CLK,
    BUS_RST,
    BUS_ADD,
    BUS_DATA_IN,
    BUS_RD,
    BUS_WR,
    BUS_DATA_OUT,

    SEQ_EXT_START,
    SEQ_CLK,
    SEQ_OUT
);

localparam VERSION = 2;

input wire                  BUS_CLK;
input wire                  BUS_RST;
input wire [ABUSWIDTH-1:0]  BUS_ADD;
input wire [7:0]            BUS_DATA_IN;
input wire                  BUS_RD;
input wire                  BUS_WR;
output reg [7:0]            BUS_DATA_OUT;

input wire SEQ_EXT_START;
input wire SEQ_CLK;
output reg [OUT_BITS-1:0] SEQ_OUT;

`include "../includes/log2func.v"

localparam ADDR_SIZEA = `CLOG2(MEM_BYTES);
localparam ADDR_SIZEB = (OUT_BITS > 8) ? `CLOG2(MEM_BYTES/(OUT_BITS/8)) : `CLOG2(MEM_BYTES*(8/OUT_BITS));

reg [7:0] status_regs [31:0];

wire RST;
wire SOFT_RST;

assign RST = BUS_RST || SOFT_RST;

localparam DEF_BIT_OUT = MEM_BYTES;

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 0;
        
        status_regs[3] <= 1;
        
        status_regs[4] <= DEF_BIT_OUT[7:0]; //bits
        status_regs[5] <= DEF_BIT_OUT[15:8]; //bits
        
        status_regs[6] <= 0; //wait
        status_regs[7] <= 0; //wait
        status_regs[8] <= 0; // 7  repeat
        status_regs[9] <= 0; // 7  repeat
        status_regs[10] <= 0; //repeat start
        status_regs[11] <= 0; //repeat start
        status_regs[12] <= 0; // nested loop start
        status_regs[13] <= 0; // -||-
        status_regs[14] <= 0; // nested loop stop
        status_regs[15] <= 0; // -||-
        status_regs[16] <= 0; // nested loop repat count
        status_regs[17] <= 0; // -||-
    end
    else if(BUS_WR && BUS_ADD < 32)
        status_regs[BUS_ADD[4:0]] <= BUS_DATA_IN;
end

reg [7:0] BUS_IN_MEM;
reg [7:0] BUS_OUT_MEM;

// 1 - finished

wire START;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

wire CONF_EN_EXT_START;
assign CONF_EN_EXT_START = status_regs[2][0];

wire [7:0] CONF_CLK_DIV;
assign CONF_CLK_DIV = status_regs[3] - 1;
reg CONF_DONE;

wire [15:0] CONF_COUNT;
assign CONF_COUNT = {status_regs[5], status_regs[4]};

wire [15:0] CONF_WAIT;
assign CONF_WAIT = {status_regs[7], status_regs[6]};

wire [15:0] CONF_REPEAT;
assign CONF_REPEAT = {status_regs[9], status_regs[8]};

wire [15:0] CONF_REP_START;
assign CONF_REP_START = {status_regs[11], status_regs[10]};

wire [15:0] CONF_NESTED_START;
assign CONF_NESTED_START = {status_regs[13], status_regs[12]};

wire [15:0] CONF_NESTED_STOP;
assign CONF_NESTED_STOP = {status_regs[15], status_regs[14]};

wire [15:0] CONF_NESTED_REPEAT;
assign CONF_NESTED_REPEAT = {status_regs[17], status_regs[16]};

wire [7:0] BUS_STATUS_OUT;
assign BUS_STATUS_OUT = status_regs[BUS_ADD[4:0]];

reg [7:0] BUS_DATA_OUT_REG;
always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 0)
            BUS_DATA_OUT_REG <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT_REG <= {7'b0, CONF_DONE};
        else if(BUS_ADD == 18)
            BUS_DATA_OUT_REG <= DEF_BIT_OUT[7:0];
        else if(BUS_ADD == 19)
            BUS_DATA_OUT_REG <= DEF_BIT_OUT[15:8];
        else if(BUS_ADD < 32)
            BUS_DATA_OUT_REG <= BUS_STATUS_OUT;
    end
end

// if one has a synchronous memory need this to give data on next clock after read
// limitation: this module still needs to be addressed
reg [ABUSWIDTH-1:0]  PREV_BUS_ADD;
always @ (posedge BUS_CLK) begin
    if(BUS_RD) begin
        PREV_BUS_ADD <= BUS_ADD;
    end
end
    
always @(*) begin
    if(PREV_BUS_ADD < 32)
        BUS_DATA_OUT = BUS_DATA_OUT_REG;
    else if(PREV_BUS_ADD < 32 + MEM_BYTES )
        BUS_DATA_OUT = BUS_IN_MEM;
    else
        BUS_DATA_OUT = 8'hxx;
end

reg [15:0] out_bit_cnt;

wire [ADDR_SIZEB-1:0] memout_addrb;
//assign memout_addrb = out_bit_cnt-1; 
assign memout_addrb = out_bit_cnt < CONF_COUNT ? out_bit_cnt-1 : CONF_COUNT-1; //do not change during wait

wire [ADDR_SIZEA-1:0] memout_addra;
wire [ABUSWIDTH-1:0] BUS_ADD_MEM;
assign BUS_ADD_MEM = BUS_ADD-32;

generate
    if (OUT_BITS<=8) begin
        assign memout_addra = BUS_ADD_MEM; 
    end else begin
        assign memout_addra = {BUS_ADD_MEM[ABUSWIDTH-1:OUT_BITS/8-1], {(OUT_BITS/8-1){1'b0}}} + (OUT_BITS/8-1) - (BUS_ADD_MEM % (OUT_BITS/8)); //Byte order
    end
endgenerate

reg [OUT_BITS-1:0] SEQ_OUT_MEM;

wire WEA;
assign WEA = BUS_WR && BUS_ADD >=32 && BUS_ADD < 32+MEM_BYTES;

generate
    if (OUT_BITS==8) begin
        reg [7:0] mem [(2**ADDR_SIZEA)-1:0];
        
        // synthesis translate_off
        //to make simulator happy (no X propagation)
        integer i;
        initial begin 
            for(i = 0; i<(2**ADDR_SIZEA); i = i + 1)
                mem[i] = 0; 
        end
        // synthesis translate_on
        
        always @(posedge BUS_CLK) begin
            if (WEA)
                mem[memout_addra] <= BUS_DATA_IN;
            BUS_IN_MEM <= mem[memout_addra];
        end
            
        always @(posedge SEQ_CLK)
                SEQ_OUT_MEM <= mem[memout_addrb];
                                         
    end else begin
        wire [7:0] douta;
        wire [OUT_BITS-1:0] doutb;
          seq_gen_blk_mem memout(
            .clka(BUS_CLK), .clkb(SEQ_CLK), .douta(douta), .doutb(doutb), 
            .wea(WEA), .web(1'b0), .addra(memout_addra), .addrb(memout_addrb), 
            .dina(BUS_DATA_IN), .dinb({OUT_BITS{1'b0}})
        );
          
        always@(*) begin
            BUS_IN_MEM = douta;
            SEQ_OUT_MEM = doutb;
        end
    end
endgenerate


wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(SEQ_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire  START_SYNC_CDC;
wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(SEQ_CLK), .pulse_out(START_SYNC_CDC));

reg DONE;
wire START_SYNC_PRE;
assign START_SYNC_PRE = (START_SYNC_CDC | (SEQ_EXT_START & CONF_EN_EXT_START));
assign START_SYNC =  START_SYNC_PRE & DONE; //no START if previous not finished    

wire [15:0] STOP_BIT;
assign STOP_BIT = CONF_COUNT + CONF_WAIT;
reg [15:0] REPEAT_COUNT;
reg [15:0] REPEAT_NESTED_COUNT;

reg [7:0] dev_cnt;


wire REP_START;
assign REP_START = (out_bit_cnt == STOP_BIT && dev_cnt == CONF_CLK_DIV && (CONF_REPEAT==0 || REPEAT_COUNT < CONF_REPEAT));

wire REP_NESTED_START;
assign REP_NESTED_START = (out_bit_cnt == CONF_NESTED_STOP && dev_cnt == CONF_CLK_DIV && (REPEAT_NESTED_COUNT < CONF_NESTED_REPEAT));


always @ (posedge SEQ_CLK)
    if (RST_SYNC)
        out_bit_cnt <= 0;
    else if(START_SYNC)
        out_bit_cnt <= 1;
    else if(REP_START)
        out_bit_cnt <= CONF_REP_START+1;
    else if(REP_NESTED_START)
        out_bit_cnt <= CONF_NESTED_START+1;
    else if(out_bit_cnt == STOP_BIT && dev_cnt == CONF_CLK_DIV)
        out_bit_cnt <= out_bit_cnt;
    else if(out_bit_cnt != 0 && dev_cnt == CONF_CLK_DIV)
        out_bit_cnt <= out_bit_cnt + 1;

always @ (posedge SEQ_CLK)
    if (RST_SYNC | START_SYNC | REP_START)
        dev_cnt <= 0;
    else if(out_bit_cnt != 0 && dev_cnt == CONF_CLK_DIV)
        dev_cnt <= 0;
    else if(out_bit_cnt != 0)
        dev_cnt <= dev_cnt + 1;
        
always @ (posedge SEQ_CLK)
    if (RST_SYNC | START_SYNC)
        REPEAT_COUNT <= 1;
    else if(out_bit_cnt == STOP_BIT && dev_cnt == CONF_CLK_DIV && REPEAT_COUNT <= CONF_REPEAT)
        REPEAT_COUNT <= REPEAT_COUNT + 1;

always @ (posedge SEQ_CLK)
    if (RST_SYNC | START_SYNC | REP_START)
        REPEAT_NESTED_COUNT <= 1;
    else if(REP_NESTED_START)
        REPEAT_NESTED_COUNT <= REPEAT_NESTED_COUNT + 1;


always @(posedge SEQ_CLK)
    if(RST_SYNC)
        DONE <= 1;
    else if(START_SYNC_PRE)
        DONE <= 0;
    else if(REPEAT_COUNT > CONF_REPEAT)
        DONE <= 1;

always @(posedge SEQ_CLK)
    SEQ_OUT <= SEQ_OUT_MEM;

wire DONE_SYNC;
cdc_pulse_sync done_pulse_sync (.clk_in(SEQ_CLK), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));

wire EXT_START_SYNC;
cdc_pulse_sync ext_start_pulse_sync (.clk_in(SEQ_CLK), .pulse_in(SEQ_EXT_START), .clk_out(BUS_CLK), .pulse_out(EXT_START_SYNC));

always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(START | (CONF_EN_EXT_START & EXT_START_SYNC))
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;


endmodule