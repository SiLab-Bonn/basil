/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $:
 *  $Date::                      $:
 */
 
// WARNING! THIS MODULE IS WORK IN PROGRESS! NOT TESTED!
/*
Possible extra options:
- delay block that allow trigger in past (enabled by parameter - for speed needed applications a simple memory circular buffer)
- trigger selections as pulse or as gate/enable
- multi window recording (sorted with but multiple times)
*/

module seq_rec_core
#(
    parameter MEM_BYTES = 8*1024,
    parameter ABUSWIDTH = 16,
    parameter IN_BITS = 8 //4,8,16,32
    
)(
    BUS_CLK,
    BUS_RST,
    BUS_ADD,
    BUS_DATA_IN,
    BUS_RD,
    BUS_WR,
    BUS_DATA_OUT,

    SEQ_CLK,
    SEQ_IN,
    TRIGGER
); 

input                       BUS_CLK;
input                       BUS_RST;
input      [ABUSWIDTH-1:0]  BUS_ADD;
input      [7:0]            BUS_DATA_IN;
input                       BUS_RD;
input                       BUS_WR;
output reg [7:0]            BUS_DATA_OUT;

input SEQ_CLK;
input [IN_BITS-1:0] SEQ_IN;
input TRIGGER;

`include "../includes/log2func.v"

localparam ADDR_SIZEA = `CLOG2(MEM_BYTES);
localparam ADDR_SIZEB = (IN_BITS > 8) ? `CLOG2(MEM_BYTES/(IN_BITS/8)) : `CLOG2(MEM_BYTES*(8/IN_BITS));

reg [7:0] status_regs [15:0];

wire RST;
wire SOFT_RST;

assign RST = BUS_RST || SOFT_RST;

localparam DEF_BIT_OUT = MEM_BYTES;

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 1;
        status_regs[3] <= DEF_BIT_OUT[7:0]; //bits
        status_regs[4] <= DEF_BIT_OUT[15:8]; //bits
    end
    else if(BUS_WR && BUS_ADD < 16)
        status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
end

reg [7:0] BUS_IN_MEM;
reg [7:0] BUS_OUT_MEM;

// 1 - finished

wire START;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

wire [15:0] CONF_COUNT;
assign CONF_COUNT = {status_regs[4], status_regs[3]};

wire [7:0] CONF_EN_TRIGGER;
assign CONF_CLK_DIV = status_regs[2][0];
reg CONF_DONE;

wire [7:0] BUS_STATUS_OUT;
assign BUS_STATUS_OUT = status_regs[BUS_ADD[3:0]];

always @ (negedge BUS_CLK) begin
    if(BUS_RD) begin
    if(BUS_ADD == 1)
        BUS_DATA_OUT <= {7'b0,CONF_DONE};
    else if(BUS_ADD == 3)
        BUS_DATA_OUT <= CONF_COUNT[7:0];
    else if(BUS_ADD == 4)
        BUS_DATA_OUT <= CONF_COUNT[15:8];
    else if(BUS_ADD < 16)
        BUS_DATA_OUT <= BUS_STATUS_OUT;
    else if(BUS_ADD < 16 + MEM_BYTES)
        BUS_DATA_OUT <= BUS_IN_MEM;
    end
end

reg [ABUSWIDTH-1:0] out_bit_cnt;

wire [ADDR_SIZEB-1:0] memout_addrb;
assign memout_addrb = out_bit_cnt-1;

wire [ADDR_SIZEA-1:0] memout_addra;
wire [ABUSWIDTH-1:0] BUS_ADD_MEM;
assign BUS_ADD_MEM = BUS_ADD-16;

generate
    if (IN_BITS<=8) begin
        assign memout_addra = BUS_ADD_MEM; 
    end else begin
        assign memout_addra = {BUS_ADD_MEM[ABUSWIDTH-1:IN_BITS/8-1], {(IN_BITS/8-1){1'b0}}} + (IN_BITS/8-1) - (BUS_ADD_MEM % (IN_BITS/8)); //Byte order
    end
endgenerate

reg [IN_BITS-1:0] SEQ_IN_MEM;

wire WEA;
assign WEA = BUS_WR && BUS_ADD >=16 && BUS_ADD < 16+MEM_BYTES;
wire WEB;

generate
    if (IN_BITS==8) begin
        (* RAM_STYLE="{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
        reg [7:0] mem [(2**ADDR_SIZEA)-1:0];
        
        
        // synthesis translate_off
        //to make simulator happy (no X propagation)
        integer i;
        initial 
            for(i = 0; i < (2**ADDR_SIZEA); i = i + 1)
                mem[i] = 0; 
        // synthesis translate_on
        
        always @(posedge BUS_CLK) begin
            if (WEA)
                mem[memout_addra] <= BUS_DATA_IN;
            BUS_IN_MEM <= mem[memout_addra];
        end
            
        always @(posedge SEQ_CLK)
            if(WEB)
                mem[memout_addrb] <= SEQ_IN;
                                         
    end else begin
	     wire [7:0] douta;
		  
        seq_rec_blk_mem memout(
            .clka(BUS_CLK), .clkb(SEQ_CLK), .douta(douta), .doutb(), 
            .wea(WEA), .web(WEB), .addra(memout_addra), .addrb(memout_addrb), 
            .dina(BUS_DATA_IN), .dinb(SEQ_IN)
        );
        always@(*) begin
            BUS_IN_MEM = douta;
        end
		  
    end
endgenerate

assign WEB = out_bit_cnt != 0;

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(SEQ_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(SEQ_CLK), .pulse_out(START_SYNC));

wire [ADDR_SIZEB:0] STOP_BIT;
assign STOP_BIT = CONF_COUNT;

wire START_SYNC_OR_TRIG;
assign START_SYNC_OR_TRIG = START_SYNC || (CONF_EN_TRIGGER && TRIGGER);

always @ (posedge SEQ_CLK)
    if (RST_SYNC)
        out_bit_cnt <= 0;
    else if(START_SYNC_OR_TRIG)
        out_bit_cnt <= 1;
    else if(out_bit_cnt == STOP_BIT)
        out_bit_cnt <= out_bit_cnt;
    else if(out_bit_cnt != 0)
        out_bit_cnt <= out_bit_cnt + 1;

reg DONE;
always @(posedge SEQ_CLK)
    if(RST_SYNC | START_SYNC_OR_TRIG)
        DONE <= 0;
    else if(out_bit_cnt == STOP_BIT)
        DONE <= 1;

wire DONE_SYNC;
cdc_pulse_sync done_pulse_sync (.clk_in(SEQ_CLK), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));

always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(START)
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;

endmodule