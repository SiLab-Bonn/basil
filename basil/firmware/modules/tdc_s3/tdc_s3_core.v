/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module tdc_s3_core #(
    parameter DATA_IDENTIFIER = 4'b0100,
    parameter CLKDV = 4, // factor of CLK160 to DV_CLK, minimal divider of 2
    parameter ABUSWIDTH = 16,
    parameter FAST_TDC = 1,
    parameter FAST_TRIGGER = 1,
    parameter BROADCAST = 0  // set this in order to receive the TDC trigger via FAST_TRIGGER_IN (640 MHz sampled TDC trigger signal is shared with other TDC modules)
) (
    input wire CLK320,
    input wire CLK160,
    input wire DV_CLK,
    input wire TDC_IN, // pulse need to be longer than one cycle of CLK320, distance of pulses needs to be longer than one cycle of DV_CLK
    output wire TDC_OUT, // sampled with 320MHz, kept high for at least DV_CLK
    input wire TRIG_IN,
    output wire TRIG_OUT,

    // input/output trigger signals for broadcasting mode
    input wire [CLKDV*4-1:0] FAST_TRIGGER_IN, // input for effective 640MHz sampled trigger signal, set BROADCAST in order to use this as FAST TRIGGER signal (broadcast)
    output wire [CLKDV*4-1:0] FAST_TRIGGER_OUT, // outgoing effective 640MHz sampled trigger signal, can be used to share it with other TDC module (broadcast)

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    input wire BUS_CLK,
    input wire [ABUSWIDTH-1:0] BUS_ADD,
    input wire [7:0] BUS_DATA_IN,
    output reg [7:0] BUS_DATA_OUT,
    input wire BUS_RST,
    input wire BUS_WR,
    input wire BUS_RD,

    input wire ARM_TDC, // enable TDC for single measurement, assuming signal slower than DV_CLK
    input wire EXT_EN, // enable TDC for a fixed time period (signal needs to be asserted to enable TDC) e.g. for occupancy measurements, assuming signal slower than DV_CLK

    input wire [15:0] TIMESTAMP
);

localparam VERSION = 2;

// output format: 4-bit DATA_IDENTIFIER (parameter) + 16 bit event counter + 12 bit TDC data
// the TDC counter has a overflow bin: TDC value is 0 when an overflow occurs

// writing to register 0 asserts soft reset
wire SOFT_RST;
assign SOFT_RST = (BUS_ADD == 0 && BUS_WR);

// reset sync
reg SOFT_RST_FF, SOFT_RST_FF2, BUS_RST_FF, BUS_RST_FF2;
always @(posedge BUS_CLK) begin
    SOFT_RST_FF <= SOFT_RST;
    SOFT_RST_FF2 <= SOFT_RST_FF;
    BUS_RST_FF <= BUS_RST;
    BUS_RST_FF2 <= BUS_RST_FF;
end

wire SOFT_RST_FLAG;
assign SOFT_RST_FLAG = ~SOFT_RST_FF2 & SOFT_RST_FF;
wire BUS_RST_FLAG;
assign BUS_RST_FLAG = BUS_RST_FF2 & ~BUS_RST_FF; // trailing edge
wire RST;
assign RST = BUS_RST_FLAG | SOFT_RST_FLAG;

wire RST_DV_CLK;
flag_domain_crossing rst_flag_domain_crossing_dv_clk (
    .CLK_A(BUS_CLK),
    .CLK_B(DV_CLK),
    .FLAG_IN_CLK_A(RST),
    .FLAG_OUT_CLK_B(RST_DV_CLK)
);

// registers
reg [7:0] status_regs[1:0];

wire CONF_EN; // ENABLE BUS_ADD==1 BIT==0
assign CONF_EN = status_regs[1][0];
wire CONF_EN_EXT; // ENABLE EXTERN BUS_ADD==1 BIT==1
assign CONF_EN_EXT = status_regs[1][1];
wire CONF_EN_ARM_TDC; // BUS_ADD==1 BIT==2
assign CONF_EN_ARM_TDC = status_regs[1][2];
wire CONF_EN_WRITE_TS; // BUS_ADD==1 BIT==3
assign CONF_EN_WRITE_TS = status_regs[1][3];
wire CONF_EN_TRIG_DIST; // BUS_ADD==1 BIT==4
assign CONF_EN_TRIG_DIST = status_regs[1][4];
wire CONF_EN_NO_WRITE_TRIG_ERR; // BUS_ADD==1 BIT==5
assign CONF_EN_NO_WRITE_TRIG_ERR = status_regs[1][5];
wire CONF_EN_INVERT_TDC; // BUS_ADD==1 BIT==6
assign CONF_EN_INVERT_TDC = status_regs[1][6];
wire CONF_EN_INVERT_TRIGGER; // BUS_ADD==1 BIT==7
assign CONF_EN_INVERT_TRIGGER = status_regs[1][7];
reg [31:0] event_cnt_buf; // BUS_ADD==2
reg [23:0] event_cnt_buf_read; // BUS_ADD==3 - 5
reg [7:0] lost_data_cnt_bus_clk; // BUS_ADD==6

always @(posedge BUS_CLK) begin
    if(RST) begin
        status_regs[0] <= 8'b0;
        status_regs[1] <= 8'b0;
    end
    else if(BUS_WR && BUS_ADD < 2)
        status_regs[BUS_ADD[0]] <= BUS_DATA_IN;
end

always @(posedge BUS_CLK) begin
    if(BUS_RD) begin
        if (BUS_ADD == 0)
            BUS_DATA_OUT <= VERSION;
        else if(BUS_ADD == 1)
            BUS_DATA_OUT <= status_regs[1];
        else if(BUS_ADD == 2)
            BUS_DATA_OUT <= event_cnt_buf[7:0];
        else if(BUS_ADD == 3)
            BUS_DATA_OUT <= event_cnt_buf_read[7:0];
        else if(BUS_ADD == 4)
            BUS_DATA_OUT <= event_cnt_buf_read[15:8];
        else if(BUS_ADD == 5)
            BUS_DATA_OUT <= event_cnt_buf_read[23:16];
        else if(BUS_ADD == 6)
            BUS_DATA_OUT <= lost_data_cnt_bus_clk;
        else
            BUS_DATA_OUT <= 0;
    end
end

wire CONF_EN_DV_CLK;
three_stage_synchronizer conf_en_three_stage_synchronizer_dv_clk (
    .CLK(DV_CLK),
    .IN(CONF_EN | (CONF_EN_EXT & EXT_EN)),
    .OUT(CONF_EN_DV_CLK)
);

wire ARM_TDC_CLK160;
three_stage_synchronizer three_stage_arm_tdc_synchronizer_clk_160 (
    .CLK(CLK160),
    .IN(ARM_TDC),
    .OUT(ARM_TDC_CLK160)
);

reg ARM_TDC_CLK160_FF;
always @(posedge CLK160) begin
    ARM_TDC_CLK160_FF <= ARM_TDC_CLK160;
end

wire ARM_TDC_FLAG_CLK160;
assign ARM_TDC_FLAG_CLK160 = ~ARM_TDC_CLK160_FF & ARM_TDC_CLK160;

wire ARM_TDC_FLAG_DV_CLK;
flag_domain_crossing arm_tdc_flag_domain_crossing (
    .CLK_A(CLK160),
    .CLK_B(DV_CLK),
    .FLAG_IN_CLK_A(ARM_TDC_FLAG_CLK160),
    .FLAG_OUT_CLK_B(ARM_TDC_FLAG_DV_CLK)
);

wire CONF_EN_ARM_TDC_DV_CLK;
three_stage_synchronizer conf_en_arm_conf_en_synchronizer_dv_clk (
    .CLK(DV_CLK),
    .IN(CONF_EN_ARM_TDC),
    .OUT(CONF_EN_ARM_TDC_DV_CLK)
);

wire CONF_EN_WRITE_TS_DV_CLK;
three_stage_synchronizer conf_en_write_ts_synchronizer_dv_clk (
    .CLK(DV_CLK),
    .IN(CONF_EN_WRITE_TS),
    .OUT(CONF_EN_WRITE_TS_DV_CLK)
);

wire CONF_EN_TRIG_DIST_DV_CLK;
three_stage_synchronizer conf_en_trig_dist_synchronizer_dv_clk (
    .CLK(DV_CLK),
    .IN(CONF_EN_TRIG_DIST),
    .OUT(CONF_EN_TRIG_DIST_DV_CLK)
);

wire CONF_EN_NO_WRITE_TRIG_ERR_DV_CLK;
three_stage_synchronizer conf_en_no_write_trig_err_synchronizer_dv_clk (
    .CLK(DV_CLK),
    .IN(CONF_EN_NO_WRITE_TRIG_ERR),
    .OUT(CONF_EN_NO_WRITE_TRIG_ERR_DV_CLK)
);

wire CONF_EN_INVERT_TDC_DV_CLK;
three_stage_synchronizer conf_en_invert_tdc_synchronizer_dv_clk (
    .CLK(DV_CLK),
    .IN(CONF_EN_INVERT_TDC),
    .OUT(CONF_EN_INVERT_TDC_DV_CLK)
);

wire CONF_EN_INVERT_TRIGGER_DV_CLK;
three_stage_synchronizer conf_en_invert_trigger_synchronizer_dv_clk (
    .CLK(DV_CLK),
    .IN(CONF_EN_INVERT_TRIGGER),
    .OUT(CONF_EN_INVERT_TRIGGER_DV_CLK)
);


// de-serialize
wire [CLKDV*4-1:0] TDC, TDC_DES;

generate
    if (FAST_TDC==1) begin
        wire [1:0] TDC_FAST;
        ddr_des #(.CLKDV(CLKDV)) iddr_des_tdc(.CLK2X(CLK320), .CLK(CLK160), .WCLK(DV_CLK), .IN(TDC_IN), .OUT(TDC), .OUT_FAST(TDC_FAST));
        // assigning TDC output, getting effective 2x CLK320 (640MHz) sampling of leading edge
        assign TDC_OUT = CONF_EN_INVERT_TDC_DV_CLK ? &TDC_FAST : |TDC_FAST;
    end
    else begin
        reg [1:0] TDC_DDRQ_DLY;
        always @(posedge CLK320)
            TDC_DDRQ_DLY[1:0] <= {TDC_IN, TDC_IN};

        reg [3:0] TDC_DDRQ_DATA;
        always @(posedge CLK320)
            TDC_DDRQ_DATA[3:0] <= {TDC_DDRQ_DLY[1:0], {TDC_IN, TDC_IN}};

         reg [3:0] TDC_DDRQ_DATA_BUF;
        always @(posedge CLK320)
            TDC_DDRQ_DATA_BUF[3:0] <= TDC_DDRQ_DATA[3:0];

        reg [3:0] TDC_DATA_IN;
        always @(posedge CLK160)
            TDC_DATA_IN[3:0] <= TDC_DDRQ_DATA_BUF[3:0];

        reg [CLKDV*4-1:0] TDC_DATA_IN_SR;
        always @(posedge CLK160)
            TDC_DATA_IN_SR <= {TDC_DATA_IN_SR[CLKDV*4-5:0],TDC_DATA_IN[3:0]};

        reg [CLKDV*4-1:0] TDC_DES_OUT;
        always @(posedge DV_CLK)
            TDC_DES_OUT <= TDC_DATA_IN_SR;

        assign TDC = TDC_DES_OUT;

        // assigning TDC output
        assign TDC_OUT = TDC_IN;
    end
endgenerate

assign TDC_DES = CONF_EN_INVERT_TDC_DV_CLK ? ~TDC : TDC;

wire ZERO_DETECTED_TDC;
assign ZERO_DETECTED_TDC = |(~TDC_DES); // asserted when one or more 0 occur

reg TDC_DES_BUF_0;
always @(posedge DV_CLK)
    TDC_DES_BUF_0 <= TDC_DES[0];

// fix width for for loop
reg [CLKDV*4+1:0] TDC_DES_WFIX;
integer h;
always @(*) begin
    TDC_DES_WFIX[CLKDV*4] = TDC_DES_BUF_0;
    TDC_DES_WFIX[CLKDV*4+1] = 0;
    for(h=0; h<CLKDV*4; h=h+1) begin
        TDC_DES_WFIX[h] = TDC_DES[h];
    end
end

/*
 * ALL_ONES_TDC:
 *  - Counting all ones
 * ONES_TDC:
 *  - Counting ones from LSB upwards until edge detected
 * LENGTH_TDC
 *  - Position of the detected edge
 *
 * TDC value:
 *  - Default: 0
 *  - Error: 0 (ambiguities)
 *  - Overflow: 0xFFF
 */
reg [4:0] ALL_ONES_TDC, ONES_TDC, LENGTH_TDC;
reg FOUND_TDC_EDGE;
integer i;
always @(*) begin
    ALL_ONES_TDC = 0;
    ONES_TDC = 0;
    LENGTH_TDC = 0;
    FOUND_TDC_EDGE = 0;
    i = 0;
    for (i=0; i<CLKDV*4; i=i+1) begin
        ALL_ONES_TDC = ALL_ONES_TDC + TDC_DES_WFIX[i];
        if (!FOUND_TDC_EDGE) begin
            ONES_TDC = ONES_TDC + TDC_DES_WFIX[i];
        end
        if ((TDC_DES_WFIX[i] == 1) && (TDC_DES_WFIX[i+1]==0) && !FOUND_TDC_EDGE) begin
            LENGTH_TDC = i + 1;
            FOUND_TDC_EDGE = 1; // exit the loop
        end
    end
end

reg NEW_TDC;
always @(*) begin
    NEW_TDC = 0;
    if (FOUND_TDC_EDGE)
        NEW_TDC = 1;
end


reg [1:0] state, next_state;
localparam      IDLE  = 2'b00,
                ARMED = 2'b01,
                COUNT = 2'b10;

always @(posedge DV_CLK)
    if (RST_DV_CLK)
      state <= IDLE;
    else
      state <= next_state;

always @(*) begin
    case(state)
        IDLE:
            if (NEW_TDC && CONF_EN_DV_CLK && !CONF_EN_ARM_TDC_DV_CLK)
                next_state = COUNT;
            else if (ARM_TDC_FLAG_DV_CLK && CONF_EN_DV_CLK && CONF_EN_ARM_TDC_DV_CLK)
                next_state = ARMED;
            else
                next_state = IDLE;

        ARMED:
            if (NEW_TDC)
                next_state = COUNT;
            else if (!CONF_EN_DV_CLK) // return to idle when disabled
                next_state = IDLE;
            else
                next_state = ARMED;

        COUNT:
            if (ZERO_DETECTED_TDC) // TODO
                next_state = IDLE;
            else if (!CONF_EN_DV_CLK)
                next_state = IDLE;
            else
                next_state = COUNT;
        default : next_state = IDLE;
    endcase
end

wire FINISH;
assign FINISH = (state == COUNT && next_state == IDLE);

wire START;
assign START = ((state == IDLE && next_state == COUNT) || (state == ARMED && next_state == COUNT));

reg [15:0] CURR_TIMESTAMP;
always @(posedge DV_CLK)
    if (RST_DV_CLK)
        CURR_TIMESTAMP <= 16'b0;
    else if (START)
        CURR_TIMESTAMP <= TIMESTAMP;

reg TDC_ERR;
always @(*)
    if(ALL_ONES_TDC!=ONES_TDC)
        TDC_ERR <= 1;
    else
        TDC_ERR <= 0;

reg [12:0] TDC_PRE; // overflow bit
initial TDC_PRE = 0;
always @(posedge DV_CLK)
    if(RST_DV_CLK || FINISH)
        TDC_PRE <= 0;
    else if(START)
        if (TDC_ERR)
            TDC_PRE <= 0; // ERROR!
        else
            TDC_PRE <= ONES_TDC;
    else if(state==COUNT) // && TDC_PRE!=0)
        if (TDC_ERR)// || NEW_TDC)
            TDC_PRE <= 0;
        else if (TDC_PRE+ONES_TDC>13'b0_1111_1111_1111)
            TDC_PRE <= 13'b0_1111_1111_1111; // OVERFLOW!
        else
            TDC_PRE <= TDC_PRE+ONES_TDC;

wire [11:0] TDC_VAL;
assign TDC_VAL = (TDC_ERR || TDC_PRE==0) ? 0 : (TDC_PRE+ONES_TDC>13'b0_1111_1111_1111) ? 13'b0_1111_1111_1111 : (NEW_TDC) ? TDC_PRE : TDC_PRE+ONES_TDC;

reg [31:0] EVENT_CNT;
initial EVENT_CNT = 0;
always @(posedge DV_CLK)
    if(RST_DV_CLK)
        EVENT_CNT <= 0;
    else if (FINISH)
        EVENT_CNT <= EVENT_CNT + 1;

reg [31:0] event_cnt_gray;
always @(posedge DV_CLK)
    event_cnt_gray <=  (EVENT_CNT>>1) ^ EVENT_CNT;

reg [31:0] event_cnt_cdc0, event_cnt_cdc1, event_cnt_bus_clk;
always @(posedge BUS_CLK) begin
    event_cnt_cdc0 <= event_cnt_gray;
    event_cnt_cdc1 <= event_cnt_cdc0;
end

integer gbi_event_cnt;
always @(*) begin
    event_cnt_bus_clk[31] = event_cnt_cdc1[31];
    for(gbi_event_cnt = 30; gbi_event_cnt >= 0; gbi_event_cnt = gbi_event_cnt - 1) begin
        event_cnt_bus_clk[gbi_event_cnt] = event_cnt_cdc1[gbi_event_cnt] ^ event_cnt_bus_clk[gbi_event_cnt + 1];
    end
end

always @(posedge BUS_CLK)
begin
    event_cnt_buf <= event_cnt_bus_clk;
    if (BUS_ADD == 2 && BUS_RD)
        event_cnt_buf_read[23:0] <= event_cnt_buf[31:8];
end


/*
 * TRIGGEL DISTANCE CALCULATOR
*/

// de-serialize
wire [CLKDV*4-1:0] TRIG, TRIG_DES;

generate
    if (FAST_TRIGGER==1) begin
        if (BROADCAST==0) begin
            wire [1:0] TRIG_FAST;
            ddr_des #(.CLKDV(CLKDV)) iddr_des_trig(.CLK2X(CLK320), .CLK(CLK160), .WCLK(DV_CLK), .IN(TRIG_IN), .OUT(TRIG), .OUT_FAST(TRIG_FAST));
            // assigning TRIG output, getting effective 2x CLK320 (640MHz) sampling of leading edge
            assign TRIG_OUT = CONF_EN_INVERT_TRIGGER_DV_CLK ? &TRIG_FAST : |TRIG_FAST;
            // set output wires from ddr deserializer in order to fed them out for broadcasting to other TDC modules
            assign FAST_TRIGGER_OUT = TRIG;
         end
         else begin
             // use inputs from broadcasting
             assign TRIG = FAST_TRIGGER_IN;
             assign FAST_TRIGGER_OUT = FAST_TRIGGER_IN;
             assign TRIG_OUT = 0;
        end
    end
    else begin
        reg [1:0] TRIGGER_DDRQ_DLY;
        always @(posedge CLK320)
            TRIGGER_DDRQ_DLY[1:0] <= {TRIG_IN, TRIG_IN};

        reg [3:0] TRIGGER_DDRQ_DATA;
        always @(posedge CLK320)
            TRIGGER_DDRQ_DATA[3:0] <= {TRIGGER_DDRQ_DLY[1:0], {TRIG_IN, TRIG_IN}};

         reg [3:0] TRIGGER_DDRQ_DATA_BUF;
        always @(posedge CLK320)
            TRIGGER_DDRQ_DATA_BUF[3:0] <= TRIGGER_DDRQ_DATA[3:0];

        reg [3:0] TRIGGER_DATA_IN;
        always @(posedge CLK160)
            TRIGGER_DATA_IN[3:0] <= TRIGGER_DDRQ_DATA_BUF[3:0];

        reg [CLKDV*4-1:0] TRIGGER_DATA_IN_SR;
        always @(posedge CLK160)
            TRIGGER_DATA_IN_SR <= {TRIGGER_DATA_IN_SR[CLKDV*4-5:0],TRIGGER_DATA_IN[3:0]};

        reg [CLKDV*4-1:0] TRIG_DES_OUT;
        always @(posedge DV_CLK)
            TRIG_DES_OUT <= TRIGGER_DATA_IN_SR;

        assign TRIG = TRIG_DES_OUT;

        // assigning TRIG output
        assign TRIG_OUT = TRIG_IN;
        assign FAST_TRIGGER_OUT = TRIG_DES_OUT;
    end
endgenerate

assign TRIG_DES = CONF_EN_INVERT_TRIGGER_DV_CLK ? ~TRIG : TRIG;

reg TRIG_DES_BUF_0;
always @(posedge DV_CLK)
    TRIG_DES_BUF_0 <= TRIG_DES[0];

// fix width for for loop
reg [CLKDV*4+1:0] TRIG_DES_WFIX;
integer j;
always @(*) begin
    TRIG_DES_WFIX[CLKDV*4] = TRIG_DES_BUF_0;
    TRIG_DES_WFIX[CLKDV*4+1] = 0;
    for(j=0; j<CLKDV*4; j=j+1) begin
        TRIG_DES_WFIX[j] = TRIG_DES[j];
    end
end

/*
 * ALL_ONES_TRIG:
 *  - Counting all ones
 * ONES_TRIG:
 *  - Counting ones from LSB upwards until edge detected
 * LENGTH_TRIG
 *  - Position of the detected edge
 *
 * Trigger distance:
 *  - Default: 255
 *  - Error: 255 (no trigger, ambiguities, TDC Error)
 *  - Overflow: 254
 */
reg [4:0] ALL_ONES_TRIG, ONES_TRIG, LENGTH_TRIG;
reg FOUND_TRIG_EDGE;
integer k;
always @(*) begin
    ALL_ONES_TRIG = 0;
    ONES_TRIG = 0;
    LENGTH_TRIG = 0;
    FOUND_TRIG_EDGE = 0;
    k = 0;
    for (k=0; k<CLKDV*4; k=k+1) begin
        ALL_ONES_TRIG = ALL_ONES_TRIG + TRIG_DES_WFIX[k];
        if (!FOUND_TRIG_EDGE) begin
            ONES_TRIG = ONES_TRIG + TRIG_DES_WFIX[k];
        end
        if ((TRIG_DES_WFIX[k] == 1) && (TRIG_DES_WFIX[k+1]==0) && !FOUND_TRIG_EDGE) begin
            LENGTH_TRIG = k + 1;
            FOUND_TRIG_EDGE = 1; // exit the loop
        end
    end
end

reg NEW_TRIG;
always @(*) begin
    NEW_TRIG = 0;
    if (FOUND_TRIG_EDGE)
        NEW_TRIG = 1;
end

reg TRIG_ERR;
always @(*)
    if(ALL_ONES_TRIG!=ONES_TRIG || (LENGTH_TDC>LENGTH_TRIG && NEW_TRIG && NEW_TDC) || (state==COUNT && NEW_TRIG))
        TRIG_ERR <= 1;
    else
        TRIG_ERR <= 0;

reg CNT_TRIG;
initial CNT_TRIG = 0;
always @(posedge DV_CLK)
    if (RST_DV_CLK)
      CNT_TRIG <= 0;
    else if (NEW_TDC==1)
      CNT_TRIG <= 0;
    else if (NEW_TRIG==1 && NEW_TDC==0 && TDC_ERR==0 && TRIG_ERR==0)
      CNT_TRIG <= 1;

reg [7:0] TRIG_CNT;
initial TRIG_CNT = 0;
always @(*) begin
    if (CNT_TRIG==0 && NEW_TRIG==1 && NEW_TDC==1)
        TRIG_CNT = LENGTH_TRIG - LENGTH_TDC;
    else if (CNT_TRIG==0 && NEW_TRIG==1 && NEW_TDC==0)
        TRIG_CNT = LENGTH_TRIG;
    else if (CNT_TRIG==1 && NEW_TDC)
        TRIG_CNT = CLKDV*4 - LENGTH_TDC;
    else if (CNT_TRIG==1)
        TRIG_CNT = CLKDV*4;
    else
        TRIG_CNT = 0;
end

reg [8:0] TRIG_DIST; // overflow bit
initial TRIG_DIST = 255;
always @(posedge DV_CLK) begin
    if (RST_DV_CLK || (FINISH/* && !NEW_TRIG*/))
        TRIG_DIST <= 255;
    else if (NEW_TRIG)
        if (TRIG_ERR || CNT_TRIG==1 || TDC_ERR)
            TRIG_DIST <= 255; // ERROR!
        else
            TRIG_DIST <= TRIG_CNT;
    else if (CNT_TRIG==1 && TRIG_DIST!=255) begin
        if (TDC_ERR)
            TRIG_DIST <= 255;
        else if(TRIG_DIST + TRIG_CNT > 254)
            TRIG_DIST <= 254; // OVERFLOW!
        else
            TRIG_DIST <= TRIG_DIST + TRIG_CNT;
    end
end
/*
 *
*/

wire wfull;
wire cdc_fifo_write;
assign cdc_fifo_write = !wfull && FINISH==1 && !(CONF_EN_TRIG_DIST_DV_CLK==1 && CONF_EN_NO_WRITE_TRIG_ERR_DV_CLK==1 && TRIG_DIST==255);

reg [31:0] cdc_data;
always @(*) begin
    if(CONF_EN_WRITE_TS_DV_CLK)
        cdc_data = {DATA_IDENTIFIER, CURR_TIMESTAMP, TDC_VAL};
    else
        cdc_data = {DATA_IDENTIFIER, EVENT_CNT[15:0], TDC_VAL};
    if(CONF_EN_TRIG_DIST_DV_CLK)
        cdc_data[27:20] = TRIG_DIST[7:0];
end

// generate long reset
reg [3:0] rst_cnt;
reg RST_LONG;
always @(posedge BUS_CLK) begin
    if (RST)
        rst_cnt <= 4'b1111; // start value
    else if (rst_cnt != 0)
        rst_cnt <= rst_cnt - 1;
    RST_LONG <= |rst_cnt;
end

reg [3:0] rst_cnt_dv_clk;
reg RST_LONG_DV_CLK;
always @(posedge DV_CLK) begin
    if (RST_DV_CLK)
        rst_cnt_dv_clk <= 4'b1111; // start value
    else if (rst_cnt_dv_clk != 0)
        rst_cnt_dv_clk <= rst_cnt_dv_clk - 1;
    RST_LONG_DV_CLK <= |rst_cnt_dv_clk;
end

wire fifo_full, cdc_fifo_empty;
wire [31:0] cdc_data_out;
cdc_syncfifo #(
    .DSIZE(32),
    .ASIZE(2)
) cdc_syncfifo_i (
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(cdc_data),
    .winc(cdc_fifo_write),
    .wclk(DV_CLK),
    .wrst(RST_LONG_DV_CLK),
    .rinc(!fifo_full),
    .rclk(BUS_CLK),
    .rrst(RST_LONG)
);

gerneric_fifo #(
    .DATA_SIZE(32),
    .DEPTH(512)
) fifo_i (
    .clk(BUS_CLK),
    .reset(RST_LONG),
    .write(!cdc_fifo_empty),
    .read(FIFO_READ),
    .data_in(cdc_data_out),
    .full(fifo_full),
    .empty(FIFO_EMPTY),
    .data_out(FIFO_DATA[31:0]),
    .size()
);

reg [7:0] LOST_DATA_CNT;
always @(posedge DV_CLK) begin
    if (RST_DV_CLK)
        LOST_DATA_CNT <= 0;
    else
        if (wfull && FINISH && LOST_DATA_CNT != 8'b1111_1111)
            LOST_DATA_CNT <= LOST_DATA_CNT + 1;
end

reg [7:0] lost_data_cnt_gray;
always @(posedge DV_CLK)
    lost_data_cnt_gray <=  (LOST_DATA_CNT>>1) ^ LOST_DATA_CNT;

reg [7:0] lost_data_cnt_cdc0, lost_data_cnt_cdc1;
always @(posedge BUS_CLK) begin
    lost_data_cnt_cdc0 <= lost_data_cnt_gray;
    lost_data_cnt_cdc1 <= lost_data_cnt_cdc0;
end

integer gbi_lost_data_cnt;
always @(*) begin
    lost_data_cnt_bus_clk[7] = lost_data_cnt_cdc1[7];
    for(gbi_lost_data_cnt = 6; gbi_lost_data_cnt >= 0; gbi_lost_data_cnt = gbi_lost_data_cnt - 1) begin
        lost_data_cnt_bus_clk[gbi_lost_data_cnt] = lost_data_cnt_cdc1[gbi_lost_data_cnt] ^ lost_data_cnt_bus_clk[gbi_lost_data_cnt + 1];
    end
end


endmodule
