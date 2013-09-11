
module gpac_adc_rx
#(
    parameter [1:0] ADC_ID = 0,
    parameter [0:0] HEADER_ID = 0
)
(
    input ADC_CLK,
    input ADC_DCO,
    input ADC_FCO,
    input ADC_IN,
    
    input ADC_SYNC,
    input ADC_TRIGGER,
     
    input FIFO_READ,
    output FIFO_EMPTY,
    output [31:0] FIFO_DATA,

    input BUS_CLK,
    input [15:0] BUS_ADD,
    input [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input BUS_RST,
    input BUS_WR,
    input BUS_RD,
    
    output LOST_ERROR
); 
    
    // 0 - soft reset
    // 1 - start/status
    
    //TODO: 
    // - external trigger /rising falling
    
    wire SOFT_RST;
    assign SOFT_RST = (BUS_ADD==0 && BUS_WR);
    
    wire RST;
    assign RST = BUS_RST | SOFT_RST; 

    reg [7:0] status_regs [15:0];
      
    always @(posedge BUS_CLK) begin
        if(RST) begin
            status_regs[0] <= 0;
            status_regs[1] <= 0;
            status_regs[2] <= 8'b0000_0000; // CONF_START_WITH_SYNC = TRUE
            status_regs[3] <= 0;
            status_regs[4] <= 0;
            status_regs[5] <= 0;
            status_regs[6] <= 1;
            status_regs[7] <= 0;
            status_regs[8] <= 0;
        end
        else if(BUS_WR && BUS_ADD < 16)
            status_regs[BUS_ADD[3:0]] <= BUS_DATA_IN;
    end
    
    wire START;
    assign START = (BUS_ADD==1 && BUS_WR);
    
    wire CONF_START_WITH_SYNC;
    assign CONF_START_WITH_SYNC = status_regs[2][0];
    
    wire CONF_EN_EX_TRIGGER;
    assign CONF_EN_EX_TRIGGER = status_regs[2][1];
    
    wire CONF_SINGLE_DATA;
    assign CONF_SINGLE_DATA = status_regs[2][2];
    
    wire [23:0] CONF_DATA_CNT;
    assign CONF_DATA_CNT = {status_regs[3], status_regs[4], status_regs[5]};
    
    wire [7:0] CONF_SAMPLE_SKIP = status_regs[6];
    wire [7:0] CONF_SAMPEL_DLY = status_regs[7];
    
    reg [7:0] CONF_ERROR_LOST;
    assign LOST_ERROR = CONF_ERROR_LOST!=0;
    
    wire CONF_DONE; 
     
    always @(posedge BUS_CLK) begin
        if(BUS_ADD == 1)
            BUS_DATA_OUT <= {7'b0, CONF_DONE};
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= {6'b0, CONF_EN_EX_TRIGGER, CONF_START_WITH_SYNC}; 
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= CONF_DATA_CNT[23:16];
        else if(BUS_ADD == 4)
            BUS_DATA_OUT <= CONF_DATA_CNT[15:8];
        else if(BUS_ADD == 5)
            BUS_DATA_OUT <= CONF_DATA_CNT[7:0];
        else if(BUS_ADD == 6)
            BUS_DATA_OUT <= CONF_SAMPLE_SKIP; 
        else if(BUS_ADD == 7)
            BUS_DATA_OUT <= CONF_SAMPEL_DLY;        
        else if(BUS_ADD == 15)
            BUS_DATA_OUT <= CONF_ERROR_LOST;
        else
            BUS_DATA_OUT <= 0;           
    end
    
    reg ADC_IN_BUF;
    always@(posedge ADC_CLK)
        ADC_IN_BUF <= ADC_IN;

    reg [13:0] adc_des;
    always@(posedge ADC_CLK) begin
        adc_des <= {adc_des[12:0],ADC_IN_BUF};
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

    wire rst_adc_sync;
    cdc_pulse_sync_cnt isync_rst (.clk_in(BUS_CLK), .pulse_in(RST), .clk_out(ADC_CLK), .pulse_out(rst_adc_sync));

    wire start_adc_sync;
    cdc_pulse_sync_cnt istart_rst (.clk_in(BUS_CLK), .pulse_in(START), .clk_out(ADC_CLK), .pulse_out(start_adc_sync));

    wire adc_sync_pulse;
    pulse_gen_rising pulse_adc_sync (.clk_in(ADC_CLK), .in(ADC_SYNC), .out(adc_sync_pulse));
   
    //long reset is needed
    reg [7:0] sync_cnt;
    always@(posedge BUS_CLK) begin
        if(RST)
            sync_cnt <= 120;
        else if(sync_cnt != 100)
            sync_cnt <= sync_cnt +1;
    end  
    wire RST_LONG;
    assign RST_LONG = sync_cnt[7];

    reg [7:0] align_cnt;
    always@(posedge ADC_CLK) begin
        if(adc_sync_pulse) //sync and load?
            align_cnt <= 0;
        else if(align_cnt == (CONF_SAMPLE_SKIP - 1) && adc_load)
            align_cnt <= 0;
        else if (adc_load)
            align_cnt <= align_cnt + 1; 
    end
    
    wire adc_load_skip = adc_load && align_cnt == CONF_SAMPEL_DLY;
    
    reg adc_sync_wait;
    always@(posedge ADC_CLK) begin
        if(RST)
            adc_sync_wait <= 0;
        else if(start_adc_sync)
            adc_sync_wait <= 1;        
        else if (adc_sync_pulse)
            adc_sync_wait <= 0; 
    end
    
    
    wire start_data_count;
    assign start_data_count = CONF_START_WITH_SYNC ? (adc_sync_wait && adc_sync_pulse) : start_adc_sync;

    reg [23:0] rec_cnt;
    always@(posedge ADC_CLK) begin
        if(rst_adc_sync)
            rec_cnt <= 0;
        else if(start_data_count)
            rec_cnt <= 1;
        else if(rec_cnt != -1 && rec_cnt>0 && adc_load_skip && CONF_DATA_CNT!=0 )
            rec_cnt <= rec_cnt + 1;
    end
    
    assign CONF_DONE  = rec_cnt > CONF_DATA_CNT;

    

    
    reg cdc_fifo_write_single;

    always@(*) begin
        if(CONF_DATA_CNT==0 && rec_cnt>=1) //forever
            cdc_fifo_write_single = adc_load_skip;
        else if(rec_cnt>=1 && rec_cnt <= CONF_DATA_CNT) //to CONF_DATA_CNT
            cdc_fifo_write_single = adc_load_skip;
        else
            cdc_fifo_write_single = 0;
    end

    reg [13:0] prev_data;
    reg prev_sync;
    reg prev_ready;
    
    always@(posedge ADC_CLK) begin
        if(rst_adc_sync || start_adc_sync)
            prev_ready <= 0;
        else if(cdc_fifo_write_single)
            prev_ready <= !prev_ready;
    end
    
    always@(posedge ADC_CLK) begin
        if(cdc_fifo_write_single) begin
            prev_data <= adc_des;
            prev_sync <= ADC_SYNC;
        end
    end
    

    wire fifo_full, cdc_fifo_empty, cdc_fifo_write_double;
    assign cdc_fifo_write_double = cdc_fifo_write_single && prev_ready; //write every second
    
    wire wfull;
    reg cdc_fifo_write;
    
    always@(posedge ADC_CLK) begin
        if(RST)
            CONF_ERROR_LOST <= 0;
        else if (CONF_ERROR_LOST!=8'hff && wfull && cdc_fifo_write)
            CONF_ERROR_LOST <= CONF_ERROR_LOST +1;
    end

    reg [31:0] data_to_fifo;
    always@(*) begin
        if(CONF_SINGLE_DATA)
            data_to_fifo = {HEADER_ID, ADC_ID, ADC_SYNC, 14'b0, adc_des};
        else
            data_to_fifo = {HEADER_ID, ADC_ID, prev_sync, prev_data, adc_des};
            
        if(CONF_SINGLE_DATA)
            cdc_fifo_write = cdc_fifo_write_single;
        else
            cdc_fifo_write = cdc_fifo_write_double;

    end
    
    wire [31:0] cdc_data_out;
    cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) cdc_syncfifo_i
    (
        .rdata(cdc_data_out),
        .wfull(wfull),
        .rempty(cdc_fifo_empty),
        .wdata(data_to_fifo), //.wdata({ADC_SYNC,2'd0,ADC_SYNC,14'd0,adc_des}),
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
                    .data_out(FIFO_DATA[31:0]), .size());

    //assign FIFO_DATA[31:30]  = 0;

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
        .TRIG0({adc_des, wfull, cdc_fifo_write, adc_load, ADC_OUT1, ADC_FCO,rst_adc_sync})
    ); 
    `endif

    
endmodule
