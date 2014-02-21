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

// controller FSM for TLU communication

`timescale 1 ps / 1ps
`default_nettype none

module tlu_controller_fsm
#(
    parameter                   DIVISOR = 12
) (
    input wire                  RESET,
    input wire                  CLK,
    
    input wire                  FIFO_READ,
    output reg                  FIFO_EMPTY,
    output wire     [31:0]      FIFO_DATA,
    
    output reg                  FIFO_PREEMPT_REQ,
    
    output reg      [31:0]      TLU_DATA,
    output reg                  TLU_DATA_READY_FLAG,
    
    input wire                  CMD_READY,
    output reg                  CMD_EXT_START_FLAG,
    input wire                  CMD_EXT_START_ENABLE,
    
    input wire                  TLU_TRIGGER,
    input wire                  TLU_TRIGGER_FLAG,
    
    input wire      [1:0]       TLU_MODE,
    input wire      [7:0]       TLU_TRIGGER_LOW_TIME_OUT,
    input wire      [4:0]       TLU_TRIGGER_CLOCK_CYCLES,
    input wire      [3:0]       TLU_TRIGGER_DATA_DELAY,
    input wire                  TLU_TRIGGER_DATA_MSB_FIRST,
    input wire                  TLU_DISABLE_VETO,
    input wire                  EXT_VETO,

    output reg                  TLU_BUSY,
    output reg                  TLU_CLOCK_ENABLE,
    output reg                  TLU_ASSERT_VETO,

    output reg                  TLU_TRIGGER_LOW_TIMEOUT_ERROR,
    output reg                  TLU_TRIGGER_ACCEPT_ERROR,

    input wire                  WRITE_TIMESTAMP,
    
    input wire                  FIFO_NEAR_FULL
);

// reg TLU_TRIGGER_ACCEPT_ERROR;
// reg TLU_TRIGGER_LOW_TIMEOUT_ERROR;
reg [30:0] TIMESTAMP_DATA;
assign FIFO_DATA[31:0] = (TLU_MODE==2'b11) ? {1'b1, TLU_DATA[30:0]} : {1'b1, TIMESTAMP_DATA};

// shift register, serial to parallel, 32 FF
reg     [(32*DIVISOR)-1:0]      tlu_data_sr;
always @ (posedge CLK)
begin
    tlu_data_sr[(32*DIVISOR)-1:0] <= {tlu_data_sr[(32*DIVISOR)-2:0], TLU_TRIGGER};
end

// timestamp
reg [30:0] TIMESTAMP;
always @ (posedge CLK)
begin
    if (RESET) TIMESTAMP <= 31'b0;
    else TIMESTAMP <= TIMESTAMP + 1;
end

// FSM
reg [7:0] counter_trigger_low_time_out;
integer counter_tlu_clock;
integer counter_sr_wait_cycles;
integer n; // for for-loop
reg CMD_WAS_BUSY;

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
always @ (posedge CLK)
begin
    if (RESET)  state <= IDLE; // get D-FF for state
    else        state <= next;
end

// combinational always block, blocking assignments
always @ (state or CMD_READY or CMD_WAS_BUSY or CMD_EXT_START_ENABLE or TLU_TRIGGER_FLAG or TLU_TRIGGER or TLU_MODE or WRITE_TIMESTAMP or TLU_TRIGGER_LOW_TIMEOUT_ERROR or counter_tlu_clock or TLU_TRIGGER_CLOCK_CYCLES or counter_sr_wait_cycles or TLU_TRIGGER_DATA_DELAY or FIFO_EMPTY or EXT_VETO) //or TLU_TRIGGER_BUSY)
begin
    case (state)
    
        IDLE:
        begin
            if ((CMD_READY == 1'b1) && (CMD_EXT_START_ENABLE == 1'b1) && (TLU_TRIGGER_FLAG == 1'b1 || (TLU_TRIGGER == 1'b1 && (TLU_MODE == 2'b11 || TLU_MODE == 2'b10))) && EXT_VETO == 1'b0) next = SEND_COMMAND_WAIT_FOR_TRIGGER_LOW;
            else next = IDLE;
        end
        
        SEND_COMMAND_WAIT_FOR_TRIGGER_LOW:
        begin
            if (WRITE_TIMESTAMP == 1'b0 && (TLU_MODE == 2'b00 || TLU_MODE == 2'b01)) next = WAIT_FOR_TLU_DATA_SAVED_CMD_READY; // do not wait for trigger low
            else if (WRITE_TIMESTAMP == 1'b1 && (TLU_MODE == 2'b00 || TLU_MODE == 2'b01)) next = LATCH_DATA; // do not wait for trigger low
            else if (WRITE_TIMESTAMP == 1'b0 && TLU_MODE == 2'b10 && (TLU_TRIGGER == 1'b0 || TLU_TRIGGER_LOW_TIMEOUT_ERROR == 1'b1)) next = WAIT_FOR_TLU_DATA_SAVED_CMD_READY;
            else if (WRITE_TIMESTAMP == 1'b1 && TLU_MODE == 2'b10 && (TLU_TRIGGER == 1'b0 || TLU_TRIGGER_LOW_TIMEOUT_ERROR == 1'b1)) next = LATCH_DATA;
            else if (TLU_MODE == 2'b11 && (TLU_TRIGGER == 1'b0 || TLU_TRIGGER_LOW_TIMEOUT_ERROR == 1'b1)) next = SEND_TLU_CLOCK;
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
            if (FIFO_EMPTY == 1'b1 && CMD_READY == 1'b1 && CMD_WAS_BUSY == 1'b1) next = IDLE;
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
always @ (posedge CLK)
begin
    if (RESET) // get D-FF
    begin
        FIFO_PREEMPT_REQ <= 1'b0;
        FIFO_EMPTY <= 1'b1;
        TLU_DATA <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        TIMESTAMP_DATA <= 31'b000_0000_0000_0000_0000_0000_0000_0000;
        TLU_ASSERT_VETO <= 1'b0;
        TLU_BUSY <= 1'b0;
        TLU_CLOCK_ENABLE <= 1'b0;
        counter_trigger_low_time_out <= 8'b0;
        counter_tlu_clock <= 0;
        counter_sr_wait_cycles <= 0;
        TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
        TLU_TRIGGER_ACCEPT_ERROR <= 1'b0;
        CMD_EXT_START_FLAG <= 1'b0;
        CMD_WAS_BUSY <= 1'b0;
    end
    else
    begin
        FIFO_PREEMPT_REQ <= 1'b0;
        FIFO_EMPTY <= 1'b1;
        TLU_DATA <= TLU_DATA;
        TIMESTAMP_DATA <= TIMESTAMP_DATA;
        TLU_DATA_READY_FLAG <= 1'b0;
        TLU_ASSERT_VETO <= 1'b0;
        TLU_BUSY <= 1'b0;
        TLU_CLOCK_ENABLE <= 1'b0;
        counter_trigger_low_time_out <= 8'b0;
        counter_tlu_clock <= 0;
        counter_sr_wait_cycles <= 0;
        TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
        TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
        CMD_EXT_START_FLAG <= 1'b0;
        CMD_WAS_BUSY <= 1'b0;

        case (next)

            IDLE:
            begin
                FIFO_PREEMPT_REQ <= 1'b0;
                FIFO_EMPTY <= 1'b1;
                TLU_DATA_READY_FLAG <= 1'b0;
                if ((CMD_EXT_START_ENABLE == 1'b0) || (FIFO_NEAR_FULL == 1'b1 && TLU_DISABLE_VETO == 1'b0))
                    TLU_ASSERT_VETO <= 1'b1;
                else
                    TLU_ASSERT_VETO <= 1'b0;
                // if (CMD_EXT_START_ENABLE == 1'b0)
                    // TLU_BUSY <= 1'b1; // FIXME: temporary fix for accepting first TLU trigger
                // else
                    // TLU_BUSY <= 1'b0;
                TLU_BUSY <= 1'b0;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= 1'b0;
                if (TLU_TRIGGER == 1'b1 && CMD_EXT_START_ENABLE == 1'b1)
                    TLU_TRIGGER_ACCEPT_ERROR <= 1'b1;
                else
                    TLU_TRIGGER_ACCEPT_ERROR <= 1'b0;
                CMD_EXT_START_FLAG <= 1'b0;
                CMD_WAS_BUSY <= 1'b0;
            end
            
            SEND_COMMAND_WAIT_FOR_TRIGGER_LOW:
            begin
                if (TLU_MODE == 2'b11 || WRITE_TIMESTAMP == 1'b1)
                    FIFO_PREEMPT_REQ <= 1'b1;
                else
                    FIFO_PREEMPT_REQ <= 1'b0;
                FIFO_EMPTY <= 1'b1;
                // get timestamp closest to the trigger
                if (state != next)
                    TIMESTAMP_DATA <= TIMESTAMP;
                TLU_DATA_READY_FLAG <= 1'b0;
                TLU_ASSERT_VETO <= 1'b0;
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
                    CMD_EXT_START_FLAG <= 1'b1;
                else
                    CMD_EXT_START_FLAG <= 1'b0;
                if (CMD_READY == 1'b0)
                    CMD_WAS_BUSY <= 1'b1;
                else
                    CMD_WAS_BUSY <= CMD_WAS_BUSY;
            end

            SEND_TLU_CLOCK:
            begin
                FIFO_PREEMPT_REQ <= FIFO_PREEMPT_REQ;
                FIFO_EMPTY <= 1'b1;
                TLU_DATA_READY_FLAG <= 1'b0;
                TLU_ASSERT_VETO <= 1'b0;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b1;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= counter_tlu_clock + 1;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                CMD_EXT_START_FLAG <= 1'b0;
                if (CMD_READY == 1'b0)
                    CMD_WAS_BUSY <= 1'b1;
                else
                    CMD_WAS_BUSY <= CMD_WAS_BUSY;
            end

            WAIT_BEFORE_LATCH:
            begin
                FIFO_PREEMPT_REQ <= FIFO_PREEMPT_REQ;
                FIFO_EMPTY <= 1'b1;
                TLU_DATA_READY_FLAG <= 1'b0;
                TLU_ASSERT_VETO <= 1'b0;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= counter_sr_wait_cycles + 1;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                CMD_EXT_START_FLAG <= 1'b0;
                if (CMD_READY == 1'b0)
                    CMD_WAS_BUSY <= 1'b1;
                else
                    CMD_WAS_BUSY <= CMD_WAS_BUSY;
            end

            LATCH_DATA:
            begin
                FIFO_PREEMPT_REQ <= FIFO_PREEMPT_REQ;
                FIFO_EMPTY <= 1'b0;
                // if (TLU_TRIGGER_CLOCK_CYCLES == 5'b0_0000) // 0 results in 32 clock cycles
                // begin
                    // if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0)  // reverse bit order
                    // begin
                        // for ( n=0 ; n < 32 ; n = n+1 )
                        // begin
                            // if (n > 31-1)
                                // TLU_DATA[n] <= 1'b0;
                            // else
                                // TLU_DATA[n] <= tlu_data_sr[31-n-1];
                        // end
                    // end
                    // else // do not reverse
                    // begin
                        // TLU_DATA[31:0] <= {1'b0, tlu_data_sr[30:0]};
                    // end
                // end
                // else // specific number of clock cycles
                // begin
                    // if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0)  // reverse bit order
                    // begin
                        // for ( n=0 ; n < 32 ; n = n+1 )
                        // begin
                            // if (n > TLU_TRIGGER_CLOCK_CYCLES-1-1)
                                // TLU_DATA[n] <= 1'b0;
                            // else
                                // TLU_DATA[n] <= tlu_data_sr[31-TLU_TRIGGER_CLOCK_CYCLES-n-1]; // reverse bit order
                        // end
                    // end
                    // else // do not reverse
                    // begin
                        // for ( n=0 ; n < 32 ; n = n+1 )
                        // begin
                            // if (n > TLU_TRIGGER_CLOCK_CYCLES-1-1)
                                // TLU_DATA[n] <= 1'b0;
                            // else
                                // TLU_DATA[n] <= tlu_data_sr[n];
                        // end
                    // end
                // end
                if (TLU_TRIGGER_CLOCK_CYCLES == 5'b0_0000) // 0 results in 32 clock cycles
                begin
                    if (TLU_TRIGGER_DATA_MSB_FIRST == 1'b0)  // reverse bit order
                    begin
                        for ( n=0 ; n < 32 ; n = n+1 )
                        begin
                            if (n > 31-1)
                                TLU_DATA[n] <= 1'b0;
                            else
                                TLU_DATA[n] <= tlu_data_sr[(32*DIVISOR)-1-(n*DIVISOR)-DIVISOR];
                        end
                    end
                    else // do not reverse
                    begin
                        for ( n=0 ; n < 32 ; n = n+1 )
                        begin
                            if (n > 31-1)
                                TLU_DATA[n] <= 1'b0;
                            else
                                TLU_DATA[n] <= tlu_data_sr[(n*DIVISOR)+DIVISOR-1];
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
                                TLU_DATA[n] <= 1'b0;
                            else
                                TLU_DATA[n] <= tlu_data_sr[(32*DIVISOR)-1-(TLU_TRIGGER_CLOCK_CYCLES*DIVISOR)-(n*DIVISOR)-DIVISOR]; // reverse bit order
                        end
                    end
                    else // do not reverse
                    begin
                        for ( n=0 ; n < 32 ; n = n+1 )
                        begin
                            if (n > TLU_TRIGGER_CLOCK_CYCLES-1-1)
                                TLU_DATA[n] <= 1'b0;
                            else
                                TLU_DATA[n] <= tlu_data_sr[(n*DIVISOR)+DIVISOR-1];
                        end
                    end
                end
                TLU_DATA_READY_FLAG <= 1'b1;
                if (FIFO_NEAR_FULL == 1'b1 && TLU_DISABLE_VETO == 1'b0)
                    TLU_ASSERT_VETO <= 1'b1;
                else
                    TLU_ASSERT_VETO <= 1'b0;
                TLU_BUSY <= 1'b1;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                CMD_EXT_START_FLAG <= 1'b0;
                if (CMD_READY == 1'b0)
                    CMD_WAS_BUSY <= 1'b1;
                else
                    CMD_WAS_BUSY <= CMD_WAS_BUSY;
            end

            WAIT_FOR_TLU_DATA_SAVED_CMD_READY:
            begin
                if (FIFO_READ == 1'b1)
                    FIFO_PREEMPT_REQ <= 1'b0;
                else
                    FIFO_PREEMPT_REQ <= FIFO_PREEMPT_REQ;
                if (FIFO_READ == 1'b1)
                    FIFO_EMPTY <= 1'b1;
                else
                    FIFO_EMPTY <= FIFO_EMPTY;
                TLU_DATA_READY_FLAG <= 1'b0;
                if (FIFO_NEAR_FULL == 1'b1 && TLU_DISABLE_VETO == 1'b0)
                    TLU_ASSERT_VETO <= 1'b1;
                else // de-assert TLU VETO here
                    TLU_ASSERT_VETO <= 1'b0;
                // de-assert TLU busy as soon as possible
                if ((FIFO_READ == 1'b1 || (WRITE_TIMESTAMP == 1'b0 && TLU_MODE != 2'b11)) && CMD_READY == 1'b1 && CMD_WAS_BUSY == 1'b1)
                    TLU_BUSY <= 1'b0;
                else
                    TLU_BUSY <= TLU_BUSY;
                TLU_CLOCK_ENABLE <= 1'b0;
                counter_trigger_low_time_out <= 8'b0;
                counter_tlu_clock <= 0;
                counter_sr_wait_cycles <= 0;
                TLU_TRIGGER_LOW_TIMEOUT_ERROR <= TLU_TRIGGER_LOW_TIMEOUT_ERROR;
                TLU_TRIGGER_ACCEPT_ERROR <= TLU_TRIGGER_ACCEPT_ERROR;
                CMD_EXT_START_FLAG <= 1'b0;
                if (CMD_READY == 1'b0)
                    CMD_WAS_BUSY <= 1'b1;
                else
                    CMD_WAS_BUSY <= CMD_WAS_BUSY;
            end

        endcase
    end
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
    .CLK(CLK),
    .TRIG0({CMD_EXT_START_ENABLE, TLU_DATA_READY_FLAG, CMD_EXT_START_FLAG, TLU_CLOCK_ENABLE, TLU_ASSERT_VETO, TLU_BUSY, CMD_READY, FIFO_NEAR_FULL, TLU_TRIGGER_ACCEPT_ERROR, TLU_TRIGGER_LOW_TIMEOUT_ERROR, TLU_TRIGGER_FLAG, TLU_TRIGGER, TLU_MODE, state})
    //.CLK(CLK_160),
    //.TRIG0({FMODE, FSTROBE, FREAD, CMD_BUS_WR, RX_BUS_WR, FIFO_WR, BUS_DATA_IN, FE_RX ,WR_B, RD_B})
);
`endif

endmodule
