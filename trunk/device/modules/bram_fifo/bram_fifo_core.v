/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University 
 * ------------------------------------------------------------
 */
 
module bram_fifo_core
#(
    parameter                   DEPTH = 32'h8000,
    parameter                   FIFO_ALMOST_FULL_THRESHOLD = 95, // in percent
    parameter                   FIFO_ALMOST_EMPTY_THRESHOLD = 5, // in percent
    parameter                   ABUSWIDTH = 32
) (
    input wire                  BUS_CLK,
    input wire                  BUS_RST,
    input wire [ABUSWIDTH-1:0]  BUS_ADD,
    input wire [7:0]            BUS_DATA_IN,
    input wire                  BUS_RD,
    input wire                  BUS_WR,
    output reg [7:0]            BUS_DATA_OUT,
    
    input wire                  BUS_RD_DATA,
    output reg [31:0]           BUS_DATA_OUT_DATA,
    input wire                  BUS_WR_DATA,
    input wire [31:0]           BUS_DATA_IN_DATA,    

    
    output wire                 FIFO_READ_NEXT_OUT,
    input wire                  FIFO_EMPTY_IN,
    input wire [31:0]           FIFO_DATA,
    
    output wire                 FIFO_NOT_EMPTY,
    output wire                 FIFO_FULL,
    output reg                  FIFO_NEAR_FULL,
    output wire                 FIFO_READ_ERROR
);

/////
wire SOFT_RST; //0
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);  

wire RST;
assign RST = BUS_RST | SOFT_RST;

reg [7:0] status_regs[7:0];

// reg 0 for SOFT_RST
wire [7:0] FIFO_ALMOST_FULL_VALUE;
assign FIFO_ALMOST_FULL_VALUE = status_regs[1];
wire [7:0] FIFO_ALMOST_EMPTY_VALUE;
assign FIFO_ALMOST_EMPTY_VALUE = status_regs[2];

always @(posedge BUS_CLK)
begin
    if(RST)
    begin
        status_regs[0] <= 0;
        status_regs[1] <= 255*FIFO_ALMOST_FULL_THRESHOLD/100;
        status_regs[2] <= 255*FIFO_ALMOST_EMPTY_THRESHOLD/100;
        status_regs[3] <= 8'b0;
        status_regs[4] <= 8'b0;
        status_regs[5] <= 8'b0;
        status_regs[6] <= 8'b0;
        status_regs[7] <= 8'b0;
    end
    else if(BUS_WR && BUS_ADD < 8)
    begin
        status_regs[BUS_ADD[2:0]] <= BUS_DATA_IN;
    end
end

// read reg
wire [31:0] CONF_SIZE, CONF_SIZE_BYTE; // write data count, 1 - 2 - 3, in units of two bytes (16 bits)
reg [7:0] CONF_READ_ERROR; // read error count (read attempts when FIFO is empty), 4
assign CONF_SIZE_BYTE = CONF_SIZE * 4;

always @ (posedge BUS_CLK) begin //(*) begin
    if(BUS_RD) begin
        if(BUS_ADD == 1)
            BUS_DATA_OUT <= CONF_SIZE_BYTE[7:0]; // in units of two bytes (8 bits)
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= CONF_SIZE_BYTE[15:8];
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= CONF_SIZE_BYTE[23:16]; 
        else if(BUS_ADD == 4)
            BUS_DATA_OUT <= CONF_READ_ERROR;
    end
end

///
//reg                   FIFO_READ_NEXT_OUT_BUF;
wire                  FIFO_EMPTY_IN_BUF;
wire [31:0]           FIFO_DATA_BUF;
wire FULL_BUF;

assign FIFO_READ_NEXT_OUT = !FULL_BUF;

    
gerneric_fifo #(.DATA_SIZE(32), .DEPTH(DEPTH))  i_buf_fifo
( .clk(BUS_CLK), .reset(RST), 
    .write(!FIFO_EMPTY_IN || BUS_WR_DATA),
    .read(BUS_RD_DATA), 
    .data_in(BUS_WR_DATA ? BUS_DATA_IN_DATA : FIFO_DATA), 
    .full(FULL_BUF), 
    .empty(FIFO_EMPTY_IN_BUF), 
    .data_out(FIFO_DATA_BUF[31:0]), .size(CONF_SIZE)
);

always@(posedge BUS_CLK)
    BUS_DATA_OUT_DATA <= FIFO_DATA_BUF;
        

assign FIFO_NOT_EMPTY = !FIFO_EMPTY_IN_BUF;
assign FIFO_FULL = FULL_BUF;
assign FIFO_READ_ERROR = (CONF_READ_ERROR != 0);

always@(posedge BUS_CLK) begin
    if(RST)
        CONF_READ_ERROR <= 0;
    else if(FIFO_EMPTY_IN_BUF && BUS_RD_DATA && CONF_READ_ERROR != 8'hff)
        CONF_READ_ERROR <= CONF_READ_ERROR +1;
end  

always @(posedge BUS_CLK) begin
    if(RST)
        FIFO_NEAR_FULL <= 1'b0;
    else if (((((FIFO_ALMOST_FULL_VALUE+1)*DEPTH)>>8) <= CONF_SIZE) || (FIFO_ALMOST_FULL_VALUE == 8'b0 && CONF_SIZE >= 0))
        FIFO_NEAR_FULL <= 1'b1;
    else if (((((FIFO_ALMOST_EMPTY_VALUE+1)*DEPTH)>>8) >= CONF_SIZE && FIFO_ALMOST_EMPTY_VALUE != 8'b0) || CONF_SIZE == 0)
        FIFO_NEAR_FULL <= 1'b0;
end

endmodule
