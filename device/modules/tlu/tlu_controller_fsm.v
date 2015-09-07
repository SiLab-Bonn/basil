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
    parameter                   DIVISOR = 8
) (
    input wire                  RESET,
    input wire                  TRIGGER_CLK,
    
    output reg                  TRIGGER_DATA_WRITE,
    output wire     [31:0]      TRIGGER_DATA,
    
    output reg                  FIFO_PREEMPT_REQ_FLAG,
    
    output reg      [31:0]      TIMESTAMP,
    output reg      [31:0]      TIMESTAMP_DATA,
    output reg      [31:0]      TLU_TRIGGER_NUMBER_DATA,
    
    output reg      [31:0]      TRIGGER_COUNTER_DATA,
    input wire                  TRIGGER_COUNTER_SET,
    input wire      [31:0]      TRIGGER_COUNTER_SET_VALUE,
    
    input wire                  TRIGGER,
    input wire                  TRIGGER_FLAG,
    input wire                  TRIGGER_VETO,
    input wire                  TRIGGER_ENABLE,
    input wire                  TRIGGER_ACKNOWLEDGE,
    output reg                  TRIGGER_ACCEPTED_FLAG,
    
    input wire      [1:0]       TLU_MODE,
    input wire      [7:0]       TLU_TRIGGER_LOW_TIME_OUT,
    input wire      [4:0]       TLU_TRIGGER_CLOCK_CYCLES,
    input wire      [3:0]       TLU_TRIGGER_DATA_DELAY,
    input wire                  TLU_TRIGGER_DATA_MSB_FIRST,
    input wire                  TLU_ENABLE_VETO,
    input wire                  TLU_RESET_FLAG,

    input wire                  WRITE_TIMESTAMP,

    output reg                  TLU_BUSY,
    output reg                  TLU_CLOCK_ENABLE,
    output reg                  TLU_ASSERT_VETO,

    output reg                  TLU_TRIGGER_LOW_TIMEOUT_ERROR,
    output reg                  TLU_TRIGGER_ACCEPT_ERROR
);

// Workaround for TLU bug where short szintillator trigger pulses lead to glitches on TLU trigger
localparam TLU_WAIT_CYCLES = 5;

// reg TLU_TRIGGER_ACCEPT_ERROR;
// reg TLU_TRIGGER_LOW_TIMEOUT_ERROR;
assign TRIGGER_DATA[31:0] = (WRITE_TIMESTAMP==1'b1) ? {1'b1, TIMESTAMP_DATA[30:0]} : ((TLU_MODE==2'b11) ? {1'b1, TLU_TRIGGER_NUMBER_DATA[30:0]} : ({1'b1, TRIGGER_COUNTER_DATA[30:0]}));

// shift register, serial to parallel, 32 FF
reg [(32*DIVISOR)-1:0] tlu_data_sr;
always @ (posedge TRIGGER_CLK)
begin
    tlu_data_sr[(32*DIVISOR)-1:0] <= {tlu_data_sr[(32*DIVISOR)-2:0], TRIGGER};
end

// FSM
reg [7:0] counter_trigger_low_time_out;
integer counter_tlu_clock;
integer counter_sr_wait_cycles;
integer n; // for for-loop
reg ACKNOWLEDGED;
reg [31:0] TRIGGER_COUNTER;

// standard state encoding
reg     [2:0]   state;
reg     [2:0]   next;

parameter   [2:0]
    IDLE                                = 3'b000,
    SEND_COMMAND_WAIT_FOR_TRIGGER_LOW   = 3'b001,
    SEND_TLU_CLOCK                      = 3'b010,
    WAIT_BEFORE_LATCH                   = 3'b011,
    LATCH_DATA                          = 3'b100,
    WAIT_FOR_TLU_DATA_SAVED_CMD_READY   = 3'b101;


// sequential always block, non-blocking assignments
always @ (posedge TRIGGER_CLK)
begin
    if (RESET)  state <= IDLE; // get D-FF for state
    else        state <= next;
end

// combinational always block, blocking assignments
always @ (state or TRIGGER_ACKNOWLEDGE or ACKNOWLEDGED or TRIGGER_ENABLE or TRIGGER_FLAG or TRIGGER or TLU_MODE or TLU_TRIGGER_LOW_TIMEOUT_ERROR or counter_tlu_clock or TLU_TRIGGER_CLOCK_CYCLES or counter_sr_wait_cycles or TLU_TRIGGER_DATA_DELAY or TRIGGER_VETO or counter_trigger_low_time_out) //or TLU_TRIGGER_BUSY)
begin
    case (state)
    
        IDLE:
        begin
            if ((TRIGGER_ACKNOWLEDGE == 1'b0) && (TRIGGER_ENABLE == 1'b1) && (TRIGGER_FLAG == 1'b1 || (TRIGGER == 1'b1 && (TLU_MODE == 2'b11 || TLU_MODE == 2'b10))) && (TRIGGER_VETO == 1'b0 || TLU_MODE == 2'b11 || TLU_MODE == 2'b10)) next = SEND_COMMAND_WAIT_FOR_TRIGGER_LOW;
            else next = IDLE;
        end
        
        SEND_COMMAND_WAIT_FOR_TRIGGER_LOW:
        begin
            if (TLU_MODE == 2'b00 || TLU_MODE == 2'b01) next = LATCH_DATA; // do not wait for trigger becoming low
            else if (TLU_MODE == 2'b10 && (TRIGGER == 1'b0 || TLU_TRIGGER_LOW_TIMEOUT_ERROR == 1'b1) && (counter_trigger_low_time_out >= TLU_WAIT_CYCLES)) next = LATCH_DATA; // wait for trigger low
            else if (TLU_MODE == 2'b11 && (TRIGGER == 1'b0 || TLU_TRIGGER_LOW_TIMEOUT_ERROR == 1'b1) && (counter_trigger_low_time_out >= TLU_WAIT_CYCLES)) next = SEND_TLU_CLOCK; // wait for trigger low, TLU clock
            else next = SEND_COMMAND_WAIT_FOR_TRIGGER_LOW;
        end
        
        SEND_TLU_CLOCK:
        begin
            if (TLU_TRIGGER_CLOCK_CYCLES == 5'b0) // send 32 clock cycles
                if (counter_tlu_clock == 32 * DIVISOR) next = WAIT_BEFORE_LATCH;
                else next = SEND_TLU_CLOCK;
            else
                if (counter_tlu_clock == TLU_TRIGGER_CLOCK_CYCLES * DIVISOR) next = WAIT_BEFORE_LATCH;
                else next = SEND_TLU_CLOCK;
        end
        
        WAIT_BEFORE_LATCH:
        begin
            if (counter_sr_wait_cycles == TLU_TRIGGER_DATA_DELAY+3) next = LATCH_DATA; // 3 clock cycles is minimum delay for sync
            else next = WAIT_BEFORE_LATCH;
        end
        
        LATCH_DATA:
        begin
            next = WAIT_FOR_TLU_DATA_SAVED_CMD_READY;
        end
        
        WAIT_FOR_TLU_DATA_SAVED_CMD_READY:
        begin
            if (TRIGGER_ACKNOWLEDGE == 1'b1 || ACKNOWLEDGED == 1'b1) next = IDLE;
            else next = WAIT_FOR_TLU_DATA_SAVED_CMD_READY;
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
        FIFO_PREEMPT_REQ_FLAG <= 1'b0;
        TRIGGER_DATA_WRITE <= 1'b0;
        TLU_TRIGGER_NUMBER_DATA <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        TIMESTAMP_DATA <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        TRIGGER_COUNTER_DATA <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        TLU_ASSERT_VETO <= 1'b0;
        TLU_BUSY <= 1'b0;
        TLU_CLOCK_ENABLE <= 1'b0;
        counter_trigger_low_time_out <= 8'b0;
        counter_tlu_clock <= 0;
        counter_sr_wait_cycles <= 0;
        TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
        TLU_TRIGGER_ACCEPT_ERROR <= 1'b0;
        TRIGGER_ACCEPTED_FLAG <= 1'b0;
        ACKNOWLEDGED <= 1'b0;
    end
    else
    begin
        FIFO_PREEMPT_REQ_FLAG <= 1'b0;
        TRIGGER_DATA_WRITE <= 1'b0;
        TLU_TRIGGER_NUMBER_DATA <= TLU_TRIGGER_NUMBER_DATA;
        TIMESTAMP_DATA <= TIMESTAMP_DATA;
        TRIGGER_COUNTER_DATA <= TRIGGER_COUNTER_DATA;
        TLU_ASSERT_VETO <= 1'b0;
        TLU_BUSY <= 1'b0;
        TLU_CLOCK_ENABLE <= 1'b0;
        counter_trigger_low_time_out <= 8'b0;
        counter_tlu_clock <= 0;
        counter_sr_wait_cycles <= 0;
        TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
        TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
        TRIGGER_ACCEPTED_FLAG <= 1'b0;
        ACKNOWLEDGED <= ACKNOWLEDGED;

        case (next)

            IDLE:
            begin
                FIFO_PREEMPT_REQ_FLAG <= 1'b0;
                TRIGGER_DATA_WRITE <= 1'b0;
                if ((TRIGGER_ENABLE == 1'b0) || (TRIGGER_VETO == 1'b1 && TLU_ENABLE_VETO == 1'b1))
                    TLU_ASSERT_VETO <= 1'b1;
                else
                    TLU_ASSERT_VETO <= 1'b0;
                // if (TRIGGER_ENABLE == 1'b0)
                    // TLU_BUSY <= 1'b1; // FIXME: temporary fix for accepting first TLU trigger
                // else
                    // TLU_BUSY <= 1'b0;
                TLU_BUSY <= 1'b0;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
                if (TRIGGER == 1'b1 && TRIGGER_ENABLE == 1'b1)
                    TLU_TRIGGER_ACCEPT_ERROR <= 1'b1;
                else
                    TLU_TRIGGER_ACCEPT_ERROR <= 1'b0;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                ACKNOWLEDGED <= 1'b0;
            end
            
            SEND_COMMAND_WAIT_FOR_TRIGGER_LOW:
            begin
                // send flag at beginning of state
                if (state != next)
                    FIFO_PREEMPT_REQ_FLAG <= 1'b1;
                else
                    FIFO_PREEMPT_REQ_FLAG <= 1'b0;
                TRIGGER_DATA_WRITE <= 1'b0;
                // get timestamp closest to the trigger
                if (state != next) begin
                    TIMESTAMP_DATA <= TIMESTAMP;
                    TRIGGER_COUNTER_DATA <= TRIGGER_COUNTER;
                end
                TLU_ASSERT_VETO <= TLU_ASSERT_VETO;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= counter_trigger_low_time_out + 1;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                if ((counter_trigger_low_time_out >= TLU_TRIGGER_LOW_TIME_OUT) && (TLU_TRIGGER_LOW_TIME_OUT != 8'b0))
                    TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b1;
                else
                    TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                // send flag at beginning of state
                if (state != next)
                    TRIGGER_ACCEPTED_FLAG <= 1'b1;
                else
                    TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    ACKNOWLEDGED <= 1'b1;
            end

            SEND_TLU_CLOCK:
            begin
                FIFO_PREEMPT_REQ_FLAG <= 1'b0;
                TRIGGER_DATA_WRITE <= 1'b0;
                TLU_ASSERT_VETO <= TLU_ASSERT_VETO;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b1;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= counter_tlu_clock + 1;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    ACKNOWLEDGED <= 1'b1;
            end

            WAIT_BEFORE_LATCH:
            begin
                FIFO_PREEMPT_REQ_FLAG <= 1'b0;
                TRIGGER_DATA_WRITE <= 1'b0;
                TLU_ASSERT_VETO <= TLU_ASSERT_VETO;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= counter_sr_wait_cycles + 1;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    ACKNOWLEDGED <= 1'b1;
            end

            LATCH_DATA:
            begin
                FIFO_PREEMPT_REQ_FLAG <= 1'b0;
                TRIGGER_DATA_WRITE <= 1'b1;
                if (TLU_TRIGGER_CLOCK_CYCLES == 5'b0_0000) // 0 results in 32 clock cycles
                begin
                    if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0)  // reverse bit order
                    begin
                        for ( n=0 ; n < 32 ; n = n+1 )
                        begin
                            if (n > 31-1)
                                TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                            else
                                TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[(32*DIVISOR)-1-(n*DIVISOR)-DIVISOR];
                        end
                    end
                    else // do not reverse
                    begin
                        for ( n=0 ; n < 32 ; n = n+1 )
                        begin
                            if (n > 31-1)
                                TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                            else
                                TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[(n*DIVISOR)+DIVISOR-1];
                        end
                    end
                end
                else // specific number of clock cycles
                begin
                    if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0)  // reverse bit order
                    begin
                        for ( n=0 ; n < 32 ; n = n+1 )
                        begin
                            if (n > TLU_TRIGGER_CLOCK_CYCLES-1-1)
                                TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                            else
                                TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[(32*DIVISOR)-1-(TLU_TRIGGER_CLOCK_CYCLES*DIVISOR)-(n*DIVISOR)-DIVISOR]; // reverse bit order
                        end
                    end
                    else // do not reverse
                    begin
                        for ( n=0 ; n < 32 ; n = n+1 )
                        begin
                            if (n > TLU_TRIGGER_CLOCK_CYCLES-1-1)
                                TLU_TRIGGER_NUMBER_DATA[n] <= 1'b0;
                            else
                                TLU_TRIGGER_NUMBER_DATA[n] <= tlu_data_sr[(n*DIVISOR)+DIVISOR-1];
                        end
                    end
                end
                TLU_ASSERT_VETO <= TLU_ASSERT_VETO;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    ACKNOWLEDGED <= 1'b1;
            end

            WAIT_FOR_TLU_DATA_SAVED_CMD_READY:
            begin
                FIFO_PREEMPT_REQ_FLAG <= 1'b0;
                TRIGGER_DATA_WRITE <= 1'b0;
                TLU_ASSERT_VETO <= TLU_ASSERT_VETO;
                // de-assert TLU busy as soon as possible
                if (TRIGGER_ACKNOWLEDGE == 1'b1 || ACKNOWLEDGED == 1'b1)
                    TLU_BUSY <= 1'b0;
                else
                    TLU_BUSY <= TLU_BUSY;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                TRIGGER_ACCEPTED_FLAG <= 1'b0;
                if (TRIGGER_ACKNOWLEDGE == 1'b1)
                    ACKNOWLEDGED <= 1'b1;
            end

        endcase
    end
end

// time stamp
always @ (posedge TRIGGER_CLK)
begin
    if (TLU_RESET_FLAG)
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
    else if(TRIGGER_ACCEPTED_FLAG) // state==IDLE && next==SEND_COMMAND_WAIT_FOR_TRIGGER_LOW)
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
    .TRIG0({TRIGGER_ENABLE, TRIGGER_DATA_WRITE, TRIGGER_ACCEPTED_FLAG, TLU_CLOCK_ENABLE, TLU_ASSERT_VETO, TLU_BUSY, TRIGGER_ACKNOWLEDGE, TRIGGER_VETO, TLU_TRIGGER_ACCEPT_ERROR, TLU_TRIGGER_LOW_TIMEOUT_ERROR, TRIGGER_FLAG, TRIGGER, TLU_MODE, state})
    //.TRIGGER_CLK(CLK_160),
    //.TRIG0({FMODE, FSTROBE, FREAD, CMD_BUS_WR, RX_BUS_WR, FIFO_WR, BUS_DATA_IN, FE_RX ,WR_B, RD_B})
);
`endif

endmodule
