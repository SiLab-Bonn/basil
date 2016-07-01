/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module tlu_controller_fsm
#(
    parameter                   DIVISOR = 8,
    parameter                   TLU_TRIGGER_MAX_CLOCK_CYCLES = 17
) (
    input wire                  RESET,
    input wire                  TRIGGER_CLK,

    output reg                  TRIGGER_DATA_WRITE,
    output reg [31:0]           TRIGGER_DATA,

    output reg                  FIFO_PREEMPT_REQ,
    input wire                  FIFO_ACKNOWLEDGE,

    output reg [31:0]           TIMESTAMP,
    output reg [31:0]           TIMESTAMP_DATA,
    output reg [31:0]           TLU_TRIGGER_NUMBER_DATA,

    output reg [31:0]           TRIGGER_COUNTER_DATA,
    input wire                  TRIGGER_COUNTER_SET,
    input wire [31:0]           TRIGGER_COUNTER_SET_VALUE,

    input wire [1:0]            TRIGGER_MODE,
    input wire [7:0]            TRIGGER_THRESHOLD,

    input wire                  TRIGGER,
    input wire                  TRIGGER_VETO,
    input wire                  TRIGGER_ENABLE,
    input wire                  TRIGGER_ACKNOWLEDGE,
    output reg                  TRIGGER_ACCEPTED_FLAG,

    input wire [7:0]            TLU_TRIGGER_LOW_TIME_OUT,
//    input wire [4:0]            TLU_TRIGGER_CLOCK_CYCLES,
    input wire [3:0]            TLU_TRIGGER_DATA_DELAY,
    input wire                  TLU_TRIGGER_DATA_MSB_FIRST,
    input wire                  TLU_ENABLE_VETO,
    input wire                  TLU_RESET_FLAG,

    input wire [1:0]            CONF_DATA_FORMAT,

    output reg                  TLU_BUSY,
    output reg                  TLU_CLOCK_ENABLE,
    output reg                  TLU_ASSERT_VETO,

    input wire [7:0]            TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES,
    input wire [7:0]            TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES,

    output wire                 TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG, // error flag
    output wire                 TLU_TRIGGER_ACCEPT_ERROR_FLAG // error flag
);

//assign TRIGGER_DATA[31:0] = (WRITE_TIMESTAMP==1'b1) ? {1'b1, TIMESTAMP_DATA[30:0]} : ((TRIGGER_MODE==2'b11) ? {1'b1, TLU_TRIGGER_NUMBER_DATA[30:0]} : ({1'b1, TRIGGER_COUNTER_DATA[30:0]}));

always@(*)
begin
    if(TRIGGER_MODE == 2'b11) // TLU trigger number
        TRIGGER_DATA[31:0] = {1'b1, TLU_TRIGGER_NUMBER_DATA[30:0]};
    else // internally generated trigger number
        TRIGGER_DATA[31:0] = {1'b1, TRIGGER_COUNTER_DATA[30:0]};

    if(CONF_DATA_FORMAT == 2'b01) // time stamp only
        TRIGGER_DATA[31:0] = {1'b1, TIMESTAMP_DATA[30:0]};
    else if(CONF_DATA_FORMAT == 2'b10) // combined
        TRIGGER_DATA[31:16] = {1'b1, TIMESTAMP_DATA[14:0]};
end

// shift register, serial to parallel, length of TLU_TRIGGER_MAX_CLOCK_CYCLES
reg [((TLU_TRIGGER_MAX_CLOCK_CYCLES+1)*DIVISOR)-1:0] tlu_data_sr;
always @ (posedge TRIGGER_CLK)
begin
    if (RESET | TRIGGER_ACCEPTED_FLAG)
        tlu_data_sr <= 0;
    else
        tlu_data_sr[((TLU_TRIGGER_MAX_CLOCK_CYCLES)*DIVISOR)-1:0] <= {tlu_data_sr[((TLU_TRIGGER_MAX_CLOCK_CYCLES)*DIVISOR)-2:0], TRIGGER};
end

// Trigger flag
reg TRIGGER_FF;
always @ (posedge TRIGGER_CLK)
    TRIGGER_FF <= TRIGGER;

wire TRIGGER_FLAG;
assign TRIGGER_FLAG = ~TRIGGER_FF & TRIGGER;

// Trigger enable flag
reg TRIGGER_ENABLE_FF;
always @ (posedge TRIGGER_CLK)
    TRIGGER_ENABLE_FF <= TRIGGER_ENABLE;

wire TRIGGER_ENABLE_FLAG;
assign TRIGGER_ENABLE_FLAG = ~TRIGGER_ENABLE_FF & TRIGGER_ENABLE;

// FSM
// workaround for TLU bug where short szintillator pulses lead to glitches on TLU trigger
reg TRIGGER_ACCEPT;
reg TLU_TRIGGER_HANDSHAKE_ACCEPT;
reg [7:0] counter_trigger_high;
// additional wait cycles for TLU veto after TLU handshake
reg [7:0] counter_tlu_handshake_veto;
// other
reg [7:0] counter_trigger_low_time_out;
integer counter_tlu_clock;
integer counter_sr_wait_cycles;
integer n; // for for-loop
reg TRIGGER_ACKNOWLEDGED, FIFO_ACKNOWLEDGED;
reg [31:0] TRIGGER_COUNTER;
reg TLU_TRIGGER_LOW_TIMEOUT_ERROR;
reg TLU_TRIGGER_ACCEPT_ERROR;

reg TLU_TRIGGER_LOW_TIMEOUT_ERROR_FF;
always @ (posedge TRIGGER_CLK)
    TLU_TRIGGER_LOW_TIMEOUT_ERROR_FF <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;

assign TLU_TRIGGER_LOW_TIMEOUT_ERROR_FLAG = ~TLU_TRIGGER_LOW_TIMEOUT_ERROR_FF & TLU_TRIGGER_LOW_TIMEOUT_ERROR;

reg TLU_TRIGGER_ACCEPT_ERROR_FF;
always @ (posedge TRIGGER_CLK)
    TLU_TRIGGER_ACCEPT_ERROR_FF <= TLU_TRIGGER_ACCEPT_ERROR;

assign TLU_TRIGGER_ACCEPT_ERROR_FLAG = ~TLU_TRIGGER_ACCEPT_ERROR_FF & TLU_TRIGGER_ACCEPT_ERROR;

// standard state encoding
reg     [2:0]   state;
reg     [2:0]   next;

parameter   [2:0]
    IDLE                                = 3'b000,
    SEND_COMMAND                        = 3'b001,
    SEND_COMMAND_WAIT_FOR_TRIGGER_LOW   = 3'b010,
    SEND_TLU_CLOCK                      = 3'b011,
    WAIT_BEFORE_LATCH                   = 3'b100,
    LATCH_DATA                          = 3'b101,
    WAIT_FOR_TLU_DATA_SAVED_CMD_READY   = 3'b110;


// sequential always block, non-blocking assignments
always @ (posedge TRIGGER_CLK)
begin
    if (RESET)  state <= IDLE; // get D-FF for state
    else        state <= next;
end

// combinational always block, blocking assignments
always @ (state or TRIGGER_ACKNOWLEDGE or TRIGGER_ACKNOWLEDGED or FIFO_ACKNOWLEDGE or FIFO_ACKNOWLEDGED or TRIGGER_ENABLE or TRIGGER_ENABLE_FLAG or TRIGGER_FLAG or TRIGGER or TRIGGER_MODE or TLU_TRIGGER_LOW_TIMEOUT_ERROR or counter_tlu_clock /*or TLU_TRIGGER_CLOCK_CYCLES*/ or counter_sr_wait_cycles or TLU_TRIGGER_DATA_DELAY or TRIGGER_VETO or TRIGGER_ACCEPT or TLU_TRIGGER_HANDSHAKE_ACCEPT or TRIGGER_THRESHOLD or TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES or TLU_TRIGGER_MAX_CLOCK_CYCLES or DIVISOR)
begin
    case (state)

        IDLE:
        begin
            if ((TRIGGER_MODE == 2'b00 || TRIGGER_MODE == 2'b01)
                && (TRIGGER_ACKNOWLEDGE == 1'b0)
                && (FIFO_ACKNOWLEDGE == 1'b0)
                && (TRIGGER_ENABLE == 1'b1)
                && (TRIGGER_VETO == 1'b0)
                && ((TRIGGER_FLAG == 1'b1 && TRIGGER_THRESHOLD == 0) // trigger threshold disabled
                    || (TRIGGER_ACCEPT == 1'b1 && TRIGGER_THRESHOLD != 0) // trigger threshold enabled
                )
            )
                next = SEND_COMMAND;
            else if ((TRIGGER_MODE == 2'b10 || TRIGGER_MODE == 2'b11)
                     && (TRIGGER_ACKNOWLEDGE == 1'b0)
                     && (FIFO_ACKNOWLEDGE == 1'b0)
                     && (TRIGGER_ENABLE == 1'b1)
                     && ((TRIGGER == 1'b1 && TRIGGER_ENABLE_FLAG == 1'b1) // workaround TLU trigger high when FSM enabled
                         || (TRIGGER_FLAG == 1'b1 && TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES == 0) // trigger accept counter disabled
                         || (TLU_TRIGGER_HANDSHAKE_ACCEPT == 1'b1 && TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES != 0) // trigger accept counter enabled
                     )
            )
                next = SEND_COMMAND_WAIT_FOR_TRIGGER_LOW;
            else
                next = IDLE;
        end

        SEND_COMMAND:
        begin
            next = LATCH_DATA; // do not wait for trigger becoming low
        end

        SEND_COMMAND_WAIT_FOR_TRIGGER_LOW:
        begin
            if (TRIGGER_MODE == 2'b10 && (TRIGGER == 1'b0 || TLU_TRIGGER_LOW_TIMEOUT_ERROR == 1'b1))
                next = LATCH_DATA; // wait for trigger low
            else if (TRIGGER_MODE == 2'b11 && (TRIGGER == 1'b0 || TLU_TRIGGER_LOW_TIMEOUT_ERROR == 1'b1))
                next = SEND_TLU_CLOCK; // wait for trigger low
            else
                next = SEND_COMMAND_WAIT_FOR_TRIGGER_LOW;
        end

        SEND_TLU_CLOCK:
        begin
            //if (TLU_TRIGGER_CLOCK_CYCLES == 5'b0) // send 32 clock cycles
            if (counter_tlu_clock >= TLU_TRIGGER_MAX_CLOCK_CYCLES * DIVISOR)
                next = WAIT_BEFORE_LATCH;
            else
                next = SEND_TLU_CLOCK;
            /*
            else
                if (counter_tlu_clock == TLU_TRIGGER_CLOCK_CYCLES * DIVISOR)
                    next = WAIT_BEFORE_LATCH;
                else
                    next = SEND_TLU_CLOCK;
            */
        end

        WAIT_BEFORE_LATCH:
        begin
            if (counter_sr_wait_cycles == TLU_TRIGGER_DATA_DELAY + 5) // wait at least 3 (2 + next state) clock cycles for sync of the signal
                next = LATCH_DATA;
            else
                next = WAIT_BEFORE_LATCH;
        end

        LATCH_DATA:
        begin
            next = WAIT_FOR_TLU_DATA_SAVED_CMD_READY;
        end

        WAIT_FOR_TLU_DATA_SAVED_CMD_READY:
        begin
            if (TRIGGER_ACKNOWLEDGED == 1'b1 && FIFO_ACKNOWLEDGED == 1'b1)
                next = IDLE;
            else
                next = WAIT_FOR_TLU_DATA_SAVED_CMD_READY;
        end

        // inferring FF
        default:
        begin
            next = IDLE;
        end

    endcase
end

// sequential always block, non-blocking assignments, registered outputs
always @ (posedge TRIGGER_CLK)
begin
    if (RESET) // get D-FF
    begin
        FIFO_PREEMPT_REQ <= 1'b0;
        TRIGGER_DATA_WRITE <= 1'b0;
        TLU_TRIGGER_NUMBER_DATA <= 32'b0;
        TIMESTAMP_DATA <= 32'b0;
        TRIGGER_COUNTER_DATA <= 32'b0;
        TLU_ASSERT_VETO <= 1'b0;
        TLU_BUSY <= 1'b0;
        TLU_CLOCK_ENABLE <= 1'b0;
        counter_trigger_high <= 8'b0;
        counter_tlu_handshake_veto <= TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES;
        TRIGGER_ACCEPT <= 1'b0;
        TLU_TRIGGER_HANDSHAKE_ACCEPT <= 1'b0;
        counter_trigger_low_time_out <= 8'b0;
        counter_tlu_clock <= 0;
        counter_sr_wait_cycles <= 0;
        TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
        TLU_TRIGGER_ACCEPT_ERROR <= 1'b0;
        TRIGGER_ACCEPTED_FLAG <= 1'b0;
        TRIGGER_ACKNOWLEDGED <= 1'b0;
        FIFO_ACKNOWLEDGED <= 1'b0;
    end
    else
    begin
        FIFO_PREEMPT_REQ <= 1'b0;
        TRIGGER_DATA_WRITE <= 1'b0;
        TLU_TRIGGER_NUMBER_DATA <= TLU_TRIGGER_NUMBER_DATA;
        TIMESTAMP_DATA <= TIMESTAMP_DATA;
        TRIGGER_COUNTER_DATA <= TRIGGER_COUNTER_DATA;
        TLU_ASSERT_VETO <= 1'b0;
        TLU_BUSY <= 1'b0;
        TLU_CLOCK_ENABLE <= 1'b0;
        counter_trigger_high <= 8'b0;
        counter_tlu_handshake_veto <= TLU_HANDSHAKE_BUSY_VETO_WAIT_CYCLES;
        TRIGGER_ACCEPT <= 1'b0;
        TLU_TRIGGER_HANDSHAKE_ACCEPT <= 1'b0;
        counter_trigger_low_time_out <= 8'b0;
        counter_tlu_clock <= 0;
        counter_sr_wait_cycles <= 0;
        TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
        TLU_TRIGGER_ACCEPT_ERROR <= 1'b0;
        TRIGGER_ACCEPTED_FLAG <= 1'b0;
        TRIGGER_ACKNOWLEDGED <= TRIGGER_ACKNOWLEDGED;
        FIFO_ACKNOWLEDGED <= FIFO_ACKNOWLEDGED;

        case (next)

            IDLE:
            begin
                if (TRIGGER_FLAG)
                    TIMESTAMP_DATA <= TIMESTAMP;
                if (TRIGGER_ENABLE == 1'b1
                    && TRIGGER == 1'b1
                    && (((TRIGGER_MODE == 2'b10 || TRIGGER_MODE == 2'b11) && (counter_trigger_high != 0 && TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES != 0))
                       || ((TRIGGER_MODE == 2'b00 || TRIGGER_MODE == 2'b01) && (counter_trigger_high != 0 && TRIGGER_THRESHOLD != 0))
                    )
                )
                    FIFO_PREEMPT_REQ <= 1'b1;
                else
                    FIFO_PREEMPT_REQ <= 1'b0;
                TRIGGER_DATA_WRITE <= 1'b0;
                if ((TRIGGER_ENABLE == 1'b0 || (TRIGGER_ENABLE == 1'b1 && TRIGGER_VETO == 1'b1 && counter_tlu_handshake_veto == 0)) && TLU_ENABLE_VETO == 1'b1 && (TRIGGER_MODE == 2'b10 || TRIGGER_MODE == 2'b11))
                    TLU_ASSERT_VETO <= 1'b1; // assert only outside Trigger/Busy handshake
                else
                    TLU_ASSERT_VETO <= 1'b0;
                // if (TRIGGER_ENABLE == 1'b0)
                    // TLU_BUSY <= 1'b1; // FIXME: temporary fix for accepting first TLU trigger
                // else
                    // TLU_BUSY <= 1'b0;
                TLU_BUSY <= 1'b0;
                TLU_CLOCK_ENABLE <= 1'b0;
                if (TRIGGER_ENABLE == 1'b1 && counter_trigger_high != 8'b1111_1111 && ((counter_trigger_high > 0 && TRIGGER == 1'b1) || (counter_trigger_high == 0 && TRIGGER_FLAG == 1'b1)))
                    counter_trigger_high <= counter_trigger_high + 1;
                else if (TRIGGER_ENABLE == 1'b1 && counter_trigger_high == 8'b1111_1111 && TRIGGER == 1'b1)
                    counter_trigger_high <= counter_trigger_high;
                else
                    counter_trigger_high <= 8'b0;
                if (TRIGGER_ENABLE == 1'b0)
                    counter_tlu_handshake_veto <= 8'b0;
                else if (counter_tlu_handshake_veto == 8'b0)
                    counter_tlu_handshake_veto <= counter_tlu_handshake_veto;
                else
                    counter_tlu_handshake_veto <= counter_tlu_handshake_veto - 1;
                if (counter_trigger_high >= TRIGGER_THRESHOLD && TRIGGER_THRESHOLD != 0)
                    TRIGGER_ACCEPT <= 1'b1;
                else
                    TRIGGER_ACCEPT <= 1'b0;
                if (counter_trigger_high >= TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES && TLU_TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES != 0)
                    TLU_TRIGGER_HANDSHAKE_ACCEPT <= 1'b1;
                else
                    TLU_TRIGGER_HANDSHAKE_ACCEPT <= 1'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                TRIGGER_ACKNOWLEDGED <= 1'b0;
                FIFO_ACKNOWLEDGED <= 1'b0;
            end

            SEND_COMMAND:
            begin
                // send flag at beginning of state
                FIFO_PREEMPT_REQ <= 1'b1;
                TRIGGER_DATA_WRITE <= 1'b0;
                // get timestamp closest to the trigger
                if (state != next) begin
                //    TIMESTAMP_DATA <= TIMESTAMP;
                    TRIGGER_COUNTER_DATA <= TRIGGER_COUNTER;
                end
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                // send flag at beginning of state
                if (state != next)
                    TRIGGER_ACCEPTED_FLAG <= 1'b1;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    TRIGGER_ACKNOWLEDGED <= 1'b1;
                if (FIFO_ACKNOWLEDGE == 1'b1)
                    FIFO_ACKNOWLEDGED <= 1'b1;
            end

            SEND_COMMAND_WAIT_FOR_TRIGGER_LOW:
            begin
                // send flag at beginning of state
                FIFO_PREEMPT_REQ <= 1'b1;
                TRIGGER_DATA_WRITE <= 1'b0;
                // get timestamp closest to the trigger
                if (state != next) begin
                //    TIMESTAMP_DATA <= TIMESTAMP;
                    TRIGGER_COUNTER_DATA <= TRIGGER_COUNTER;
                end
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= counter_trigger_low_time_out + 1;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                if ((counter_trigger_low_time_out >= TLU_TRIGGER_LOW_TIME_OUT) && (TLU_TRIGGER_LOW_TIME_OUT != 8'b0))
                    TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b1;
                else
                    TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
                if (state != next)
                    TRIGGER_ACCEPTED_FLAG <= 1'b1;
                else
                    TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    TRIGGER_ACKNOWLEDGED <= 1'b1;
                if (FIFO_ACKNOWLEDGE == 1'b1)
                    FIFO_ACKNOWLEDGED <= 1'b1;
            end

            SEND_TLU_CLOCK:
            begin
                FIFO_PREEMPT_REQ <= 1'b1;
                TRIGGER_DATA_WRITE <= 1'b0;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b1;
                counter_tlu_clock <= counter_tlu_clock + 1;
                counter_sr_wait_cycles <= 0;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    TRIGGER_ACKNOWLEDGED <= 1'b1;
                if (FIFO_ACKNOWLEDGE == 1'b1)
                    FIFO_ACKNOWLEDGED <= 1'b1;
                if (state != next && TRIGGER == 1'b0 && counter_trigger_low_time_out < 4) // 4 clocks cycles = 1 for output + 3 for sync
                    TLU_TRIGGER_ACCEPT_ERROR <= 1'b1;
            end

            WAIT_BEFORE_LATCH:
            begin
                FIFO_PREEMPT_REQ <= 1'b1;
                TRIGGER_DATA_WRITE <= 1'b0;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= counter_sr_wait_cycles + 1;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    TRIGGER_ACKNOWLEDGED <= 1'b1;
                if (FIFO_ACKNOWLEDGE == 1'b1)
                    FIFO_ACKNOWLEDGED <= 1'b1;
            end

            LATCH_DATA:
            begin
                FIFO_PREEMPT_REQ <= 1'b1;
                TRIGGER_DATA_WRITE <= 1'b1;
                if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0) begin // reverse bit order
                    for ( n=0 ; n < TLU_TRIGGER_MAX_CLOCK_CYCLES ; n = n+1 ) begin
                        if (n > 31-1)
                            TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                        else
                            TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[((TLU_TRIGGER_MAX_CLOCK_CYCLES-n)*DIVISOR)-1];
                    end
                end
                else begin // do not reverse
                    for ( n=0 ; n < TLU_TRIGGER_MAX_CLOCK_CYCLES ; n = n+1 ) begin
                        if (n > 31-1)
                            TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                        else
                            TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[((n+2)*DIVISOR)-1];
                    end
                end
                /*
                if (TLU_TRIGGER_CLOCK_CYCLES == 5'b0_0000) begin // 0 results in 32 clock cycles -> 31bit trigger number
                    if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0) begin // reverse bit order
                        for ( n=0 ; n < 32 ; n = n+1 ) begin
                            if (n > 31-1)
                                TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                            else
                                TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[((32-n)*DIVISOR)-1];
                        end
                    end
                    else begin // do not reverse
                        for ( n=0 ; n < 32 ; n = n+1 ) begin
                            if (n > 31-1)
                                TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                            else
                                TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[((n+2)*DIVISOR)-1];
                        end
                    end
                end
                else begin // specific number of clock cycles
                    if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0) begin // reverse bit order
                        for ( n=31 ; n >= 0 ; n = n-1 ) begin
                            if (n + 1 > TLU_TRIGGER_CLOCK_CYCLES - 1)
                                TLU_TRIGGER_NUMBER_DATA[n] = 1'b0;
                            else if (n + 1 == TLU_TRIGGER_CLOCK_CYCLES - 1) begin
                                for ( i=0 ; i < 32 ; i = i+1 ) begin
                                    if (i < TLU_TRIGGER_CLOCK_CYCLES-1)
                                        TLU_TRIGGER_NUMBER_DATA[n-i] = tlu_data_sr[((i+2)*DIVISOR)-1];
                                end
                            end
                        end
                    end
                    else begin // do not reverse
                        for ( n=0 ; n < 32 ; n = n+1 ) begin
                            if (n + 1 > TLU_TRIGGER_CLOCK_CYCLES - 1)
                                TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                            else
                                TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[((n+2)*DIVISOR)-1];
                        end
                    end
                end
                */
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    TRIGGER_ACKNOWLEDGED <= 1'b1;
                if (FIFO_ACKNOWLEDGE == 1'b1)
                    FIFO_ACKNOWLEDGED <= 1'b1;
                if (state != next && TRIGGER == 1'b0 && counter_trigger_low_time_out < 4 && TRIGGER_MODE == 2'b10) // 4 clocks cycles = 1 for output + 3 for sync
                    TLU_TRIGGER_ACCEPT_ERROR <= 1'b1;
            end

            WAIT_FOR_TLU_DATA_SAVED_CMD_READY:
            begin
                //if ()
                //    FIFO_PREEMPT_REQ <= 1'b0;
                //else
                //    FIFO_PREEMPT_REQ <= FIFO_PREEMPT_REQ;
                FIFO_PREEMPT_REQ <= 1'b1;
                TRIGGER_DATA_WRITE <= 1'b0;
                // de-assert TLU busy as soon as possible
                //if (TRIGGER_ACKNOWLEDGED == 1'b1 && FIFO_ACKNOWLEDGED == 1'b1)
                //    TLU_BUSY <= 1'b0;
                //else
                TLU_BUSY <= TLU_BUSY;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    TRIGGER_ACKNOWLEDGED <= 1'b1;
                if (FIFO_ACKNOWLEDGE == 1'b1)
                    FIFO_ACKNOWLEDGED <= 1'b1;
            end

        endcase
    end
end

// time stamp
always @ (posedge TRIGGER_CLK)
begin
    if (RESET | TLU_RESET_FLAG)
        TIMESTAMP <= 32'b0;
    else
        TIMESTAMP <= TIMESTAMP + 1;
end

// trigger counter
always @ (posedge TRIGGER_CLK)
begin
    if (RESET)
        TRIGGER_COUNTER <= 32'b0;
    else if(TRIGGER_COUNTER_SET==1'b1)
        TRIGGER_COUNTER <= TRIGGER_COUNTER_SET_VALUE;
    else if(TRIGGER_ACCEPTED_FLAG)
        TRIGGER_COUNTER <= TRIGGER_COUNTER + 1;
end

// Chipscope
`ifdef SYNTHESIS_NOT
//`ifdef SYNTHESIS
wire [35:0] control_bus;
chipscope_icon ichipscope_icon
(
    .CONTROL0(control_bus)
);

chipscope_ila ichipscope_ila
(
    .CONTROL(control_bus),
    .TRIGGER_CLK(TRIGGER_CLK),
    .TRIG0({TRIGGER_ENABLE, TRIGGER_DATA_WRITE, TRIGGER_ACCEPTED_FLAG, TLU_CLOCK_ENABLE, TLU_ASSERT_VETO, TLU_BUSY, TRIGGER_ACKNOWLEDGE, TRIGGER_VETO, TLU_TRIGGER_ACCEPT_ERROR, TLU_TRIGGER_LOW_TIMEOUT_ERROR, TRIGGER_FLAG, TRIGGER, TRIGGER_MODE, state})
    //.TRIGGER_CLK(CLK_160),
    //.TRIG0({FMODE, FSTROBE, FREAD, CMD_BUS_WR, RX_BUS_WR, FIFO_WR, BUS_DATA_IN, FE_RX ,WR_B, RD_B})
);
`endif

endmodule
