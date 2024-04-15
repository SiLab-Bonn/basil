module controller (
	input wire CLK,
	input wire rst,
	input wire [1:0] hit_status,
	input wire cdc_fifo_full,
	input wire arm_flag,
	input wire en,
	input wire en_arm_mode,
	input wire en_calib_mode,
	input wire counter_overflow,

	output reg counter_count,
	output reg counter_reset,
	output wire [state_bits-1:0] tdc_state,
	output reg [7:0] miss_cnt,
	output reg [31:0] event_cnt,
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

function [state_bits-1:0] int_to_gray;
	input [state_bits-1:0] int;
	begin
		int_to_gray = int ^ (int >> 1);
	end
endfunction
// TDC states
// These need to be in sync with the word broker.
localparam [state_bits-1:0] IDLE = 0;
localparam [state_bits-1:0] ARMED = 1;
localparam [state_bits-1:0] TRIGGERED = 2;
localparam [state_bits-1:0] RIS_EDGE = 3;
localparam [state_bits-1:0] FAL_EDGE = 4;
localparam [state_bits-1:0] COUNTER_OVERFLOW = 5;
localparam [state_bits-1:0] FIFO_FULL = 6;
localparam [state_bits-1:0] MISSED = 7;
localparam [state_bits-1:0] CALIB = 8;
localparam [state_bits-1:0] CALIB_HIT = 9;
localparam [state_bits-1:0] RESET = 10;


reg [state_bits-1:0] state = 0;
reg [state_bits-1:0] previous_state = 0;
always @(posedge CLK) begin
	previous_state <= state;
end

assign tdc_state = state;


always @(state) begin
	// State dependent control outputs
	case(state)
		RESET: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
		end
		IDLE: begin
			mux_addr <= TRIG_IN;
			counter_reset <= 1;
			counter_count <= 0;
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
		MISSED:
			miss_cnt <= miss_cnt + 1; 
	endcase
end

always @(posedge CLK) begin
	// State transitions
	if (rst) begin
		state <= RESET;
	end else if (~en) begin
		state <= IDLE;
	end else if (cdc_fifo_full) begin
		state <= FIFO_FULL;
	end else if (counter_overflow) begin
		state <= COUNTER_OVERFLOW;
	end else if (hit_status == TDL_MISSED) begin
		state <= MISSED;
	end else begin
		case(state)
			IDLE: begin
				if (en_calib_mode) begin
					state <= CALIB;
				end else if (~en_arm_mode) begin 
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
					state <= IDLE;
			end
			CALIB: begin
				if (~en_calib_mode)
					state <= IDLE;
				else if (hit_status == TDL_HIT)
					state <= CALIB_HIT;
				else
					state <= CALIB;
			end
			CALIB_HIT: state <= CALIB;
			FIFO_FULL: state <= IDLE;
			COUNTER_OVERFLOW: state <= IDLE;
			MISSED: state <= IDLE;
			RESET: state <= IDLE;
		endcase
	end
end
endmodule
