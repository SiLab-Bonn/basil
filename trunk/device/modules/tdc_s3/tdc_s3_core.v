/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SILAB , Physics Institute of Bonn University , All Right 
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $:
 *  $Date::                      $:
 */
 
module tdc_s3_core
#(
    parameter IDENTYFIER = 4'b0001
)(
    input CLK320,
    input CLK160,
    input CLK40,
    input TDC_IN,

    input FIFO_READ,
    output FIFO_EMPTY,
    output [31:0] FIFO_DATA,

    input BUS_CLK,
    input [15:0] BUS_ADD,
    input [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input BUS_RST,
    input BUS_WR,
    input BUS_RD
); 

//output format #ID (as parameter IDENTYFIER + 16 event counter + 12 TDC bit data) 

wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 

reg CONF_EN; //ENABLE BUS_ADD==2 BIT==0
reg [7:0] LOST_DATA_CNT; //BUS_ADD==3

always @(posedge BUS_CLK) begin
    if(RST) begin
        CONF_EN <= 0;
    end
    else if(BUS_WR) begin
        if(BUS_ADD == 2)
            CONF_EN <= BUS_DATA_IN[0];
    end
end



always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if(BUS_ADD == 2)
            BUS_DATA_OUT <= {7'b0, CONF_EN};
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= LOST_DATA_CNT;
    end
end

////
wire [1:0] DDRQ;
IFDDRRSE IFDDRRSE_inst (
.Q0(DDRQ[1]), // Posedge data output
.Q1(DDRQ[0]), // Negedge data output
.C0(CLK320), // 0 degree clock input
.C1(~CLK320), // 180 degree clock input
.CE(1'b1), // Clock enable input
.D(TDC_IN), // Data input (connect directly to top-level port)
.R(1'b0), // Synchronous reset input
.S(1'b0) // Synchronous preset input
);

reg [1:0] DDRQ_DLY;

always@(posedge CLK320)
    DDRQ_DLY[1:0] <= DDRQ[1:0];

reg [3:0] DDRQ_DATA;
always@(posedge CLK320)
    DDRQ_DATA[3:0] <= {DDRQ_DLY[1:0], DDRQ[1:0]};

reg [3:0] DATA_IN;
always@(posedge CLK160)
    DATA_IN[3:0] <= {DDRQ_DATA[3:0]};

reg [15:0] DATA_IN_SR;
always@(posedge CLK160)
    DATA_IN_SR[15:0] <= {DATA_IN_SR[11:0],DATA_IN[3:0]};
    
reg [15:0] DATA;
always@(posedge CLK40)
    DATA <= DATA_IN_SR;
    
wire ONE_DETECTED;
assign ONE_DETECTED = |DATA;   

wire ZERO_DETECTED;
assign ZERO_DETECTED = |(~DATA);   

wire RST_SYNC;
flag_domain_crossing cmd_rst_flag_domain_crossing (
    .CLK_A(BUS_CLK),
    .CLK_B(CLK40),
    .FLAG_IN_CLK_A(RST),
    .FLAG_OUT_CLK_B(RST_SYNC)
);


reg state, next_state;
localparam      WAIT  = 0,
                COUNT = 1;

always @ (posedge CLK40)
    if (RST_SYNC)
      state <= WAIT;
    else
      state <= next_state;

always @ (*) begin 
    case(state)        
        WAIT:
            if (ONE_DETECTED && CONF_EN)
                next_state = COUNT;
            else
                next_state = WAIT;

        COUNT:
            if (ZERO_DETECTED)
                next_state = WAIT;
            else
                next_state = COUNT;
        default : next_state = WAIT;
    endcase
end 



wire FINISH;
assign FINISH = (state == COUNT && next_state == WAIT);
wire START;
assign START = (state == WAIT && next_state == COUNT);

integer i;
reg [4:0] ONES;
always@(*) begin 
    ONES = 0;
    for(i=1;i<=16;i=i+1) begin
        ONES = ONES + DATA[i];
    end
end

reg [11:0] TDC_PRE;
always @ (posedge CLK40)
    if(RST_SYNC)
        TDC_PRE <= 0;
    else if(START)
        TDC_PRE <= ONES;
    else if(state == COUNT)
        TDC_PRE <= TDC_PRE + ONES;

wire [11:0] TDC_VAL;
assign TDC_VAL = TDC_PRE + ONES;


reg [15:0] EVENT_CNT;
always @ (posedge CLK40)
    if(RST_SYNC)
        EVENT_CNT <= 0;
    else if (FINISH)
        EVENT_CNT <= EVENT_CNT +1;
    
///
wire wfull;
wire cdc_fifo_write;
assign cdc_fifo_write = !wfull && FINISH;

wire [31:0] cdc_data;
assign cdc_data = {IDENTYFIER, EVENT_CNT, TDC_VAL};

always@(posedge CLK40) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && cdc_fifo_write && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT +1;
end

wire fifo_full, cdc_fifo_empty;

wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write), .wclk(CLK40), .wrst(RST_LONG),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(RST_LONG)
);

gerneric_fifo #(.DATA_SIZE(32), .DEPTH(1024))  fifo_i
( .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
    .write(!cdc_fifo_empty),
    .read(FIFO_READ), 
    .data_in(cdc_data_out), 
    .full(fifo_full), 
    .empty(FIFO_EMPTY), 
    .data_out(FIFO_DATA[31:0]), .size() 
);

endmodule
