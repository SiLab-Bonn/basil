/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module rec_sync
#(
    parameter                       DSIZE = 10
)
(
    input wire                      reset,
    input wire                      datain,
    output reg      [DSIZE-1:0]     data,
    input wire                      WCLK,
    input wire                      FCLK,
    output reg                      rec_sync_ready,
    input wire                      decoder_err
);

wire BITSLIP_FLAG, BITSLIP_FLAG_FCLK;
flag_domain_crossing bitslip_flag_domain_crossing_inst (
    .CLK_A(WCLK),
    .CLK_B(FCLK),
    .FLAG_IN_CLK_A(BITSLIP_FLAG),
    .FLAG_OUT_CLK_B(BITSLIP_FLAG_FCLK)
);

reg [DSIZE-1:0] shift_reg;
always@(posedge FCLK)
    shift_reg <= {shift_reg[DSIZE-2:0], datain};

reg [DSIZE-1:0] bitslip_cnt;
initial bitslip_cnt = 1;
always@(posedge FCLK)
    if(BITSLIP_FLAG_FCLK)
        bitslip_cnt <= {bitslip_cnt[DSIZE-3:0],bitslip_cnt[DSIZE-1:DSIZE-2]};
    else
        bitslip_cnt <= {bitslip_cnt[DSIZE-2:0],bitslip_cnt[DSIZE-1]};

reg [DSIZE-1:0] fdataout;
always@(posedge FCLK)
    if(bitslip_cnt[0])
        fdataout <= shift_reg;
    else
        fdataout <= fdataout;

// reg [DSIZE-1:0] old_data;
always@(posedge WCLK) begin
    data <= fdataout;
    // old_data <= data;
end

integer wait_cnt;
reg [2:0] state, next_state;

localparam      START  = 0,
                WAIT = 1,
                CHECK = 2,
                BITSHIFT = 3,
                IDLE = 4;

localparam      K28_1P = 10'b00_1111_1001,
                K28_1N = 10'b11_0000_0110;

always @ (posedge WCLK) begin
    if (reset)  state <= START;
    else        state <= next_state;
end

always @ (state or data or wait_cnt or decoder_err) begin // old_data
    
    case(state)
        START:
            next_state = WAIT;
        
        WAIT:
            if (wait_cnt == 2)
                next_state = CHECK;
            else
                next_state = WAIT;

        CHECK:
            if (decoder_err == 1'b0)//(data == K28_1P && old_data == K28_1N) || (data == K28_1N && old_data == K28_1P))
                next_state = IDLE;
            else
                next_state = BITSHIFT;
            
        BITSHIFT:
            next_state = WAIT;
        
        IDLE:
            if(decoder_err==1'b1)
                next_state = WAIT;
            else
                next_state = IDLE;
        
        default : next_state = START;
    endcase
end

assign BITSLIP_FLAG = (state==CHECK && next_state==BITSHIFT);
//assign rec_sync_ready = (state==IDLE);

always @ (posedge WCLK)
begin
    if (reset) // get D-FF
    begin
        rec_sync_ready <= 1'b0;
        wait_cnt <= 0;
    end
    else
    begin
        rec_sync_ready <= rec_sync_ready;
        wait_cnt <= 0;

        case (next_state)

            START:
            begin
                rec_sync_ready <= 1'b0;
            end
        
            WAIT:
            begin
                if(decoder_err==1'b1)
                    rec_sync_ready <= 1'b0;
                else
                    rec_sync_ready <= 1'b1;
                wait_cnt <= wait_cnt+1;
            end

            CHECK:
            begin
                wait_cnt <= wait_cnt+1;
            end
            
            BITSHIFT:
            begin
                rec_sync_ready <= 1'b0;
            end
            
            IDLE:
            begin
                if(decoder_err==1'b1)
                    rec_sync_ready <= 1'b0;
                else
                    rec_sync_ready <= 1'b1;
            end
        
        endcase
    end
end

`ifdef SYNTHESIS_NOT
wire [35:0] control_bus;
chipscope_icon ichipscope_icon
(
    .CONTROL0(control_bus)
);

chipscope_ila ichipscope_ila 
(
    .CONTROL(control_bus),
    .CLK(WCLK), 
    .TRIG0({lck, eye_size, REC_SYNC_ERROR, data, BITSLIP_FLAG, state, pa_ready_flag, reset, pll_rst}) 
);
`endif

endmodule
