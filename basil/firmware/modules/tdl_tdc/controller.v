// Main state machine of the tdc. Contains the logic for switching the
// multiplexer, controling the corse counter, arming, calibration 
// states and the trigger distance mode. Furthermore counts successful events
// and tdl misses.
module controller #(
	parameter state_bits = 4,
	parameter mux_bits =2
)(
	input wire CLK,
	input wire rst,
	input wire [1:0] hit_status,
	input wire tdl_status,
	input wire arm_flag,
	input wire en,
	input wire en_arm_mode,
	input wire en_calib_mode,
	input wire en_write_trigger_distance,

	output reg counter_count,
	output reg counter_reset,
	output wire [state_bits-1:0] tdc_state,
	output reg [7:0] miss_cnt,
	output reg [31:0] event_cnt,
	output reg [mux_bits-1:0] mux_addr
);


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

// function [state_bits-1:0] int_to_gray;
// 	input [state_bits-1:0] int;
// 	begin
// 		int_to_gray = int ^ (int >> 1);
// 	end
// endfunction
// TDC states
// These need to be in sync with the word broker.
localparam [state_bits-1:0] IDLE = 0;
localparam [state_bits-1:0] IDLE_TRIG = 1;
localparam [state_bits-1:0] TRIGGERED = 2;
localparam [state_bits-1:0] RIS_EDGE = 3;
localparam [state_bits-1:0] FAL_EDGE = 4;
localparam [state_bits-1:0] MISSED = 6;
localparam [state_bits-1:0] CALIB = 7;
localparam [state_bits-1:0] CALIB_HIT = 8;
localparam [state_bits-1:0] RESET = 9;


reg [state_bits-1:0] state = 0;
reg [state_bits-1:0] previous_state = 0;
always @(posedge CLK) begin
	previous_state <= state;
end

assign tdc_state = state;
wire hit;
// Here we safeguard against really short (narrow) pulses triggering the
// sampling. Only if a hit was detected and on the next cycle the input is
// still a solid 1 do we count a hit.
assign hit = (hit_status == TDL_HIT) && tdl_status;




always @(state, en_write_trigger_distance) begin
	// State dependent control outputs
	case(state)
		RESET: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
		end
		IDLE: begin
			mux_addr <= SIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
		end
		IDLE_TRIG: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
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
			if (en_write_trigger_distance)
				mux_addr <= TRIG_IN;
			else 
				mux_addr <= SIG_IN;
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
		MISSED: begin
			counter_reset <= 1;
			counter_count <= 0;
			mux_addr <= TRIG_IN;
		end
		default: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
		end
	endcase
end

always @(posedge CLK) begin
	// State dependent counting of events
	case(state)
		RESET: begin
			event_cnt <= 0;
			miss_cnt <= 0;
		end
		IDLE: begin
			if (previous_state == FAL_EDGE)
				event_cnt <= event_cnt + 1; // This is really a multicycle path: Only every 4 cycles can this occur.
		end
		IDLE_TRIG: begin
			if (previous_state == FAL_EDGE)
				event_cnt <= event_cnt + 1; // This is really a multicycle path: Only every 4 cycles can this occur.
		end
		MISSED:
			miss_cnt <= miss_cnt + 1; 
	endcase
end

wire armed;
reg arm_flag_latch;
assign armed = en_arm_mode?arm_flag_latch:1;

// State transitions
always @(posedge CLK) begin
	arm_flag_latch <= arm_flag | arm_flag_latch;
	// Interrupt-style state transitions
	if (rst) begin
		state <= RESET;
		arm_flag_latch <= 0;
	end else if (~en) begin
		state <= IDLE;
	end else if (hit_status == TDL_MISSED) begin
		state <= MISSED;
	end else begin
		// Regular state-dependent transition
		case(state)
			IDLE: begin
				if (en_calib_mode) begin
					state <= CALIB;
				end else if (en_write_trigger_distance) begin
					state <= IDLE_TRIG;
				end else if (armed) begin 
					if (hit)
						state <= RIS_EDGE;
				end else begin
					state <= state;
				end
			end
			IDLE_TRIG: begin
				if (en_calib_mode) begin
					state <= CALIB;
				end else if (~en_write_trigger_distance) begin
					state <= IDLE;
				end else if (armed) begin 
					if (hit)
						state <= TRIGGERED;
				end else begin
					state <= state;
				end
			end
			TRIGGERED: begin
				if (hit)
					state <= RIS_EDGE;
				else
					state <= state;
			end
			RIS_EDGE: begin
				if (hit)
					state <= FAL_EDGE;
				else
					state <= state;
			end
			FAL_EDGE: begin
				arm_flag_latch <= 0;
				if (en_write_trigger_distance)
					state <= IDLE_TRIG;
				else
					state <= IDLE;
			end
			CALIB: begin
				if (~en_calib_mode)
					state <= IDLE_TRIG;
				else if (hit)
					state <= CALIB_HIT;
				else
					state <= CALIB;
			end
			CALIB_HIT: state <= CALIB;
			MISSED: state <= IDLE_TRIG;
			RESET: state <= IDLE;
		endcase
	end
end
endmodule
