

module fast_spi_rx
(
    input SCLK,
    input SDI,
    input SEN,
     
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
  
 parameter IDENTYFIER = 4'b0001;
//output format #ID (as parameter IDENTYFIER + 12 id-frame + 16 bit data) 
  
wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 

reg CONF_EN;
  
always @(posedge BUS_CLK) begin
    if(RST) begin
        CONF_EN <= 0;
    end
    else if(BUS_WR) begin
        if(BUS_ADD == 2)
            CONF_EN <= BUS_DATA_IN[0];
    end
end

reg [7:0] LOST_DATA_CNT;

always @(posedge BUS_CLK) begin
    if(BUS_ADD == 2)
        BUS_DATA_OUT <= {6'b0, CONF_EN};
    else if(BUS_ADD == 3)
        BUS_DATA_OUT <= LOST_DATA_CNT;
    else
        BUS_DATA_OUT <= 0;
end

wire RST_SYNC;
wire RST_SOFT_SYNC;
pulse_sync rst_pulse_sync (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(SCLK), .pulse_out(RST_SOFT_SYNC));
assign RST_SYNC = RST_SOFT_SYNC || BUS_RST;

wire CONF_EN_SYNC;
assign CONF_EN_SYNC  = CONF_EN;

reg [7:0] sync_cnt;
    always@(posedge BUS_CLK) begin
        if(RST)
            sync_cnt <= 120;
        else if(sync_cnt != 100)
            sync_cnt <= sync_cnt +1;
    end 
    
wire RST_LONG;
assign RST_LONG = sync_cnt[7];

reg [11:0] frame_cnt;
wire SEN_START, SEN_FINISH;
reg SEN_DLY;
always@(posedge SCLK) begin
    SEN_DLY <= SEN;
end
assign SEN_START = (SEN_DLY ==0 && SEN == 1);
assign SEN_FINISH = (SEN_DLY ==1 && SEN == 0);

always@(posedge SCLK) begin
    if(RST_SYNC)
        frame_cnt <= 0;
    else if(SEN_FINISH && CONF_EN_SYNC)
        frame_cnt <= frame_cnt + 1;
end

wire cdc_fifo_write;

reg [4:0] bit_cnt;
always@(posedge SCLK) begin
    if(RST_SYNC | SEN_START)
        bit_cnt <= 0;
    else if(cdc_fifo_write)
        bit_cnt <= 0;
    else if(SEN)
        bit_cnt <= bit_cnt + 1;
end

assign cdc_fifo_write = ( (bit_cnt == 15) || SEN_FINISH ) && CONF_EN_SYNC;

reg [15:0] spi_data;
always@(posedge SCLK) begin
    if(RST_SYNC | SEN_FINISH)
        spi_data <= 0;
    else if(cdc_fifo_write)
        spi_data <= {15'b0, SDI};
    else if(SEN)
        spi_data <= {spi_data[14:0], SDI};
end

wire fifo_full,cdc_fifo_empty;

wire wfull;
always@(posedge SCLK) begin
    if(RST_SYNC)
        LOST_DATA_CNT <= 0;
    else if (wfull && cdc_fifo_write && LOST_DATA_CNT != -1)
        LOST_DATA_CNT <= LOST_DATA_CNT +1;
end

wire [31:0] cdc_data;
assign cdc_data = {IDENTYFIER, frame_cnt[11:0], spi_data};

wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write), .wclk(SCLK), .wrst(RST_LONG),
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

//assign FIFO_DATA[31:30]  = 0;

endmodule
