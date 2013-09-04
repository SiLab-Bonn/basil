

module gpac_adc_rx
(
    input ADC_CLK,
    input ADC_FCO,
    input [3:0] ADC_IN,
    input ADC_SYNC,
    input ADC_PRS,
     
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

  // 0 - soft reset
  // 1 - start/status
  // 2 - reserved
  // 2-4 data_to_take

  
wire SOFT_RST;
assign SOFT_RST = (BUS_ADD==0 && BUS_WR);

wire RST;
assign RST = BUS_RST | SOFT_RST; 

wire START;
assign START = (BUS_ADD==1 && BUS_WR);

reg [7:0] status_regs [7:0];
  
always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 0;
        status_regs[1] <= 0;
        status_regs[2] <= 0;
        status_regs[3] <= 0;
        status_regs[4] <= 0;
        status_regs[5] <= 1;
        status_regs[6] <= 0;
        status_regs[7] <= 55;
    end
    else if(BUS_WR && BUS_ADD < 8)
        status_regs[BUS_ADD[2:0]] <= BUS_DATA_IN;
end
  
wire [23:0] CONF_DATA_CNT;
assign CONF_DATA_CNT = {status_regs[3], status_regs[4], status_regs[5]};

always @(posedge BUS_CLK) begin
    if(BUS_ADD == 1)
        BUS_DATA_OUT = {7'b0};
    else if(BUS_ADD == 2)
        BUS_DATA_OUT = {7'b0}; //TODO: enable channel/mode?
    else if(BUS_ADD == 3)
        BUS_DATA_OUT = CONF_DATA_CNT[23:16];
    else if(BUS_ADD == 4)
        BUS_DATA_OUT = CONF_DATA_CNT[15:8];
    else if(BUS_ADD == 5)
        BUS_DATA_OUT = CONF_DATA_CNT[7:0];
    else
        BUS_DATA_OUT = 0;  //TODO: error readback?
end
  

  
reg ADC_OUT1;
always@(posedge ADC_CLK)
    ADC_OUT1 <= ADC_IN[0];

reg [13:0] adc_des;
always@(posedge ADC_CLK) begin
    adc_des <= {adc_des[12:0],ADC_OUT1};
end

reg [1:0] fco_sync;
always@(posedge ADC_CLK) begin
    fco_sync <= {fco_sync[0],ADC_FCO};
end

wire adc_des_rst;
assign adc_des_rst = fco_sync[0] & !fco_sync[1] ;

reg [3:0] adc_des_cnt;
always@(posedge ADC_CLK) begin
    if(adc_des_rst)
        adc_des_cnt <= 0;
    else
        adc_des_cnt <= adc_des_cnt +1;
end

wire adc_load;
assign adc_load = (adc_des_cnt==13);

reg [13:0] adc_1_data;
always@(posedge ADC_CLK) begin
    if(adc_load)
        adc_1_data <= adc_des;
end

wire RST_ADC_SYNC;
pulse_sync_cnt isync_rst (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(ADC_CLK), .pulse_out(RST_ADC_SYNC));

wire START_ADC_SYNC;
pulse_sync_cnt istart_rst (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(ADC_CLK), .pulse_out(START_ADC_SYNC));

reg [7:0] sync_cnt;
    always@(posedge BUS_CLK) begin
        if(RST)
            sync_cnt <= 120;
        else if(sync_cnt != 100)
            sync_cnt <= sync_cnt +1;
    end  
wire RST_LONG;
assign RST_LONG = sync_cnt[7];

reg [23:0] rec_cnt;
always@(posedge ADC_CLK) begin
    if(RST_ADC_SYNC)
        rec_cnt <= 0;
    else if(START_ADC_SYNC)
        rec_cnt <= 1;
    else if(rec_cnt != -1 && rec_cnt>0 && adc_load)
        rec_cnt <= rec_cnt + 1;
end

reg cdc_fifo_write;

always@(*) begin
    if(CONF_DATA_CNT==0 && rec_cnt>=1)
        cdc_fifo_write = adc_load;
    else if(rec_cnt>=1 && rec_cnt <= CONF_DATA_CNT)
        cdc_fifo_write = adc_load;
    else
        cdc_fifo_write = 0;
end

wire fifo_full,cdc_fifo_empty;


//TODO: count data loss/done status
wire wfull;
wire [15:0] fifo_size;

`ifdef SYNTHESIS_
wire [35:0] control_bus;
chipscope_icon ichipscope_icon
(
    .CONTROL0(control_bus)
); 

chipscope_ila ichipscope_ila 
(
    .CONTROL(control_bus),
    .CLK(ADC_CLK), 
    .TRIG0({adc_des, wfull, cdc_fifo_write, adc_load, ADC_OUT1, ADC_FCO,RST_ADC_SYNC})

); 
`endif

`ifdef SYNTHESIS_
wire [35:0] control_bus;
chipscope_icon ichipscope_icon
(
    .CONTROL0(control_bus)
); 

chipscope_ila ichipscope_ila 
(
    .CONTROL(control_bus),
    .CLK(BUS_CLK), 
    .TRIG0({fifo_size, cdc_fifo_empty, fifo_full, FIFO_EMPTY, FIFO_READ, START, RST_LONG, RST})

); 
`endif


wire [31:0] cdc_data_out;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
(
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata({1'b0,ADC_SYNC,2'b0,14'b0,adc_des}), //.wdata({ADC_SYNC,2'd0,ADC_SYNC,14'd0,adc_des}),
    .winc(cdc_fifo_write), .wclk(ADC_CLK), .wrst(RST_LONG),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(RST_LONG)
);


gerneric_fifo #(.DATA_SIZE(32), .DEPTH(1024))  fifo_i
              ( .clk(BUS_CLK), .reset(RST_LONG | BUS_RST), 
                .write(!cdc_fifo_empty),
                .read(FIFO_READ), 
                .data_in(cdc_data_out), 
                .full(fifo_full), 
                .empty(FIFO_EMPTY), 
                .data_out(FIFO_DATA[31:0]), .size(fifo_size));

//assign FIFO_DATA[31:30]  = 0;

endmodule
