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
 
 

module pulse_gen_core
(
    input                       BUS_CLK,
    input                       BUS_RST,
    input      [15:0]           BUS_ADD,
    input      [7:0]            BUS_DATA_IN,
    input                       BUS_RD,
    input                       BUS_WR,
    output     reg [7:0]        BUS_DATA_OUT,
    
    input PULSE_CLK,
    input EXT_START,
    output reg PULSE
); 



/////
wire SOFT_RST; 
wire START;
reg CONF_EN;
reg [15:0] CONF_DELAY; 
reg [15:0] CONF_WIDTH;
reg [7:0] CONF_REPEAT;
reg CONF_DONE;

always@(posedge BUS_CLK) begin
    if(BUS_ADD == 1)
        BUS_DATA_OUT <= {7'b0, CONF_DONE};
    else if(BUS_ADD == 2)
        BUS_DATA_OUT <= {7'b0, CONF_EN};
    else if(BUS_ADD == 3)
        BUS_DATA_OUT <= CONF_DELAY[15:8];
    else if(BUS_ADD == 4)
        BUS_DATA_OUT <= CONF_DELAY[7:0];
    else if(BUS_ADD == 5)
        BUS_DATA_OUT <= CONF_WIDTH[15:8];
    else if(BUS_ADD == 6)
        BUS_DATA_OUT <= CONF_WIDTH[7:0];
    else if(BUS_ADD == 7)
        BUS_DATA_OUT <= CONF_REPEAT[7:0];
end

assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
assign START = (BUS_ADD==1 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST;

always @(posedge BUS_CLK) begin
    if(RST) begin
        CONF_EN <= 0;
        CONF_DELAY <= 0;
        CONF_WIDTH <= 0;
        CONF_REPEAT <= 1;
    end
    else if(BUS_WR) begin
        if(BUS_ADD == 2)
            CONF_EN <= BUS_DATA_IN[0];
        else if(BUS_ADD == 3)
            CONF_DELAY[15:8] <= BUS_DATA_IN;
        else if(BUS_ADD == 4)
            CONF_DELAY[7:0] <= BUS_DATA_IN;
        else if(BUS_ADD == 5)
            CONF_WIDTH[15:8] <= BUS_DATA_IN;
        else if(BUS_ADD == 6)
            CONF_WIDTH[7:0] <= BUS_DATA_IN;
        else if(BUS_ADD == 7)
            CONF_REPEAT[7:0] <= BUS_DATA_IN;
    end
end

wire RST_SYNC;
wire RST_SOFT_SYNC;
cdc_pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(PULSE_CLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;


wire START_SYNC;
cdc_pulse_sync start_pulse_sync (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(PULSE_CLK), .pulse_out(START_SYNC));

wire EXT_START_SYNC;
reg [2:0] EXT_START_FF;
always @(posedge PULSE_CLK) // first stage
begin
    EXT_START_FF[0] <= EXT_START;
    EXT_START_FF[1] <= EXT_START_FF[0];
    EXT_START_FF[2] <= EXT_START_FF[1];
end

assign EXT_START_SYNC = !EXT_START_FF[2] & EXT_START_FF[1];

reg [15:0] CNT;

wire [16:0] LAST_CNT;
assign LAST_CNT = CONF_DELAY + CONF_WIDTH;

reg [7:0] REAPAT_CNT;

always @ (posedge PULSE_CLK) begin
    if (RST_SYNC)
        REAPAT_CNT <= 0; 
    else if(START_SYNC || (EXT_START_SYNC && CONF_EN))
        REAPAT_CNT <= CONF_REPEAT; 
    else if(REAPAT_CNT != 0 && CNT == 1)
        REAPAT_CNT <= REAPAT_CNT - 1;
end

always @ (posedge PULSE_CLK) begin
    if (RST_SYNC)
        CNT <= 0; //IS THIS RIGHT?
    else if(START_SYNC || (EXT_START_SYNC && CONF_EN))
        CNT <= 1;
    else if(CNT == LAST_CNT && REAPAT_CNT != 0)
        CNT <= 1;
    else if(CNT == LAST_CNT && REAPAT_CNT == 0)
        CNT <= 0;
    else if(CNT != 0)
        CNT <= CNT + 1;
end

always @ (posedge PULSE_CLK) begin
    if(RST_SYNC || START_SYNC || (EXT_START_SYNC && CONF_EN))
        PULSE <= 0;
    else if(CNT == CONF_DELAY && CNT > 0)
        PULSE <= 1;
    else if(CNT == LAST_CNT)
        PULSE <= 0;
end

wire DONE;
assign DONE = (CNT == 0);

wire DONE_SYNC;
cdc_pulse_sync done_pulse_sync (.clk_in(PULSE_CLK), .pulse_in(DONE), .clk_out(BUS_CLK), .pulse_out(DONE_SYNC));

wire EXT_START_SYNC_BUS;
cdc_pulse_sync ex_start_pulse_sync (.clk_in(PULSE_CLK), .pulse_in(EXT_START && CONF_EN), .clk_out(BUS_CLK), .pulse_out(EXT_START_SYNC_BUS));

always @(posedge BUS_CLK)
    if(RST)
        CONF_DONE <= 1;
    else if(START || EXT_START_SYNC_BUS)
        CONF_DONE <= 0;
    else if(DONE_SYNC)
        CONF_DONE <= 1;
        

endmodule
