/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`ifndef FAST_ARBITER
`define FAST_ARBITER

`timescale 1ps/1ps
`default_nettype none

module fast_arbiter #(
    parameter WIDTH = 4,
    parameter DWIDTH = 32
) (
    input wire RST,
    input wire CLK,

    input wire  [WIDTH-1:0]        WRITE_REQ,  // Which channel has data
    input wire  [WIDTH-1:0]        PRIO_REQ,
    input wire  [WIDTH*DWIDTH-1:0] DATA_IN,
    output wire [WIDTH-1:0]        READ_GRANT,  // Which channel is allowed to write to downstream FIFO

    input wire               READY_OUT,  // From downstream FIFO
    output wire              WRITE_OUT,  // To downstream FIFO
    output wire [DWIDTH-1:0] DATA_OUT
);

// 1-hot encoding of selected channel
wire [WIDTH-1:0] select;
reg [WIDTH-1:0] prev_select;

wire [WIDTH-1:0] mask_above_prev;
wire [WIDTH-1:0] wr_req_high;
wire [WIDTH-1:0] mask_prio_req;
wire [WIDTH-1:0] grant_high;
wire [WIDTH-1:0] grant_low;
wire [WIDTH-1:0] grant_prio;

assign mask_above_prev = ~((prev_select << 1) - 1'b1);
assign wr_req_high = WRITE_REQ & mask_above_prev;  // channels above prev_select with data
assign grant_high = wr_req_high & (~wr_req_high + 1'b1);  // lowest channel above prev_select with data
assign grant_low = WRITE_REQ & (~WRITE_REQ + 1'b1);  // lowest channel overall with data (wrap-around)

// Priority channels
assign mask_prio_req = WRITE_REQ & PRIO_REQ;  // Priority channels with data
assign grant_prio = mask_prio_req & (~mask_prio_req + 1'b1);  // lowest channel of the priority input

// Prioritize lowest PRIO_REQ channel, then higher ones; if no PRIO_REQ, regular arbitration
assign select = |grant_prio ? grant_prio : (|wr_req_high ? grant_high : grant_low);
assign READ_GRANT = select & {WIDTH{READY_OUT}};
assign WRITE_OUT = |READ_GRANT;

reg [DWIDTH-1:0] data_out_reg;
always @(*) begin : data_out_mux
    integer k;

    data_out_reg = {DWIDTH{1'b0}};  // Initialize before every change
    for (k = 0; k < WIDTH; k = k + 1) begin
        // Slice DATA_IN to currently granted block of DWIDTH bits
        data_out_reg = data_out_reg | (DATA_IN[k*DWIDTH +: DWIDTH] & {DWIDTH{select[k]}});
    end
end
assign DATA_OUT = data_out_reg;

always @(posedge CLK) begin
    if (RST)
        prev_select <= {1'b1, {(WIDTH-1){1'b0}}};
    else if (|READ_GRANT)
        // Advance select and calculate new mask
        prev_select <= select;
end

endmodule

`endif
