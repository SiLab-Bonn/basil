module controller (
	input wire CLK,
	input wire rst,
	input wire [1:0] hit_status,
	input wire cdc_fifo_full,
	input wire arm_flag,
	input wire en,
	input wire en_arm_mode,
	input wire counter_overflow,

	output reg counter_count,
	output reg counter_reset,
	output reg [state_bits-1:0] tdc_state,
	output reg [7:0] miss_cnt,
	output reg [31:0] event_cnt
	output reg [mux_bits-1:0] mux_addr
);

parameter state_bits = 4;
parameter mux_bits =2;

// 2 bit flag to store hit and miss information of the group of
// samples. This needs to be in sync with the sample deser
localparam TDL_IDLE = 0;
localparam TDL_HIT = 1;
localparam TDL_MISSED = 2;

// Input Mux addresses
// These need to be in sync with the tdc core.
localparam TRIG_IN = 0;
localparam SIG_IN = 1;
localparam SIG_IN_B = 2;
localparam CALIB_OSC = 3;

// TDC states
// These need to be in sync with the word broker.
localparam IDLE = 0;
localparam TRIGGERED = 1;
localparam RIS_EDGE = 2;
localparam FAL_EDGE = 3;
localparam COUNTER_OVERFLOW = 4;
localparam FIFO_FULL = 5;
localparam MISSED = 6;
localparam CALIB = 7;
localparam CALIB_HIT = 8;
localparam ARMED = 9;
localparam RESET = 10;

reg [state_bits-1:0] state = 0;
reg [state_bits-1:0] previous_state = 0;
always @(posedge CLK) begin
	previous_state <= state;
end


always @(posedge CLK) begin
	// State dependent control outputs
	case(state)
		RESET: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_counte <= 0;
			miss_cnt <= 0;
			event_cnt <= 0;
		IDLE: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
			if(previous_state == FAL_EDGE)
				event_cnt <= event_cnt + 1; // This is really a multicycle path: Only every 4 cycles can this occur.
		end
		ARMED: begin
			mux_addr <= TRIG_IN;
			counter_count <= 0;
			counter_reset <= 0;
		end
		TRIGGERED: begin
			mux_addr <= SIG_IN;
			counter_reset <= 0;
			counter_count <= 1;
		end
		RIS_EDGE: begin
			mux_addr <= SIG_IN_B;
			counter_reset <= 0;
			counter_count <= 1;
		end
		FAL_EDGE: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
		end
		CALIB: begin
			mux_addr <= CALIB_OSC;
			counter_reset <= 1;
			counter_count <= 0;
		end
		CALIB_HIT: begin
			mux_addr <= CALIB_OSC;
			counter_reset <= 1;
			counter_count <= 0;
		end
		COUNTER_OVERFLOW: begin
			counter_reset <= 1;
			counter_count <= 0;
			mux_addr <= TRIG_IN;
		end
		MISSED: begin
			counter_reset <= 1;
			counter_count <= 0;
			mux_addr <= TRIG_IN;
			miss_cnt = miss_cnt + 1; //TODO: reset
		end
		default: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
		end
	endcase

	// State transitions
	if(rst) begin
		state <= RESET;
	end else if (~en) begin
		state <= IDLE;
	end else if(cdc_fifo_full) begin
		state <= FIFO_FULL;
	end else if(counter_overflow) begin
		state <= COUNTER_OVERFLOW;
	end else if(hit_status == TDL_MISSED) begin
		state <= MISSED;
	end else begin
		case(state)
			IDLE: begin
				if (~en_arm_mode) begin 
					if (hit_status == TDL_HIT)
						state <= TRIGGERED;
				end else if (arm_flag) begin
					state <= ARMED;
				end else begin
					state <= state;
				end
			end
			ARMED: begin
				if (~en_arm_mode) begin
					state <= IDLE;
				end else if (hit_status == TDL_HIT) begin
					state <= TRIGGERED;
				end else begin
					state <= state;
				end
			TRIGGERED: begin
				if (hit_status == TDL_HIT)
					state <= RIS_EDGE;
				else
					state <= state;
			end
			RIS_EDGE: begin
				if (hit_status == TDL_HIT)
					state <= FAL_EDGE;
				else
					state <= state;
			end
			FAL_EDGE: begin
				if (hit_status == TDL_HIT)
					state <= IDLE;
				else
					state <= state;
			end
			CALIB: begin
				if (hit_status == TDL_HIT)
					state <= CALIB_HIT;
				else if (~calib_mode)
					state <= IDLE;
				else
					state <= CALIB
			end
			CALIB_HIT: state <= CALIB;
			FIFO_FULL: state <= IDLE;
			COUNTER_OVERFLOW: state <= IDLE;
			MISSED: state <= IDLE;
		endcase
	end
end

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
    .CLK_B(CLK_SLOW),
    .FLAG_IN_CLK_A(ARM_TDC_FLAG_CLK160),
    .FLAG_OUT_CLK_B(ARM_TDC_FLAG_DV_CLK)
);


