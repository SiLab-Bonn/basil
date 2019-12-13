/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module receiver_logic #(
    parameter               DSIZE = 10
) (
    input wire              RESET,
    input wire              WCLK,
    input wire              FCLK,
    input wire              FCLK2X,
    input wire              BUS_CLK,
    input wire              RX_DATA,
    input wire              read,
    output wire  [23:0]     data,
    output wire             empty,
    output reg              rx_fifo_full,
    output wire             rec_sync_ready,
    output reg  [7:0]       lost_data_cnt,
    output reg  [7:0]       decoder_err_cnt,
    output reg [15:0]       fifo_size,
    input wire              invert_rx_data,
    input wire              enable_rx,
    input wire              FIFO_CLK
);

wire RESET_WCLK;
flag_domain_crossing reset_domain_crossing_wclk_inst (
    .CLK_A(BUS_CLK),
    .CLK_B(WCLK),
    .FLAG_IN_CLK_A(RESET),
    .FLAG_OUT_CLK_B(RESET_WCLK)
);

wire RESET_FCLK;
flag_domain_crossing reset_domain_crossing_fclk_inst (
    .CLK_A(BUS_CLK),
    .CLK_B(FCLK),
    .FLAG_IN_CLK_A(RESET),
    .FLAG_OUT_CLK_B(RESET_FCLK)
);

wire RESET_FIFO_CLK;
flag_domain_crossing reset_domain_crossing_fifo_clk_inst (
    .CLK_A(BUS_CLK),
    .CLK_B(FIFO_CLK),
    .FLAG_IN_CLK_A(RESET),
    .FLAG_OUT_CLK_B(RESET_FIFO_CLK)
);

// data to clock phase alignment
wire RX_DATA_SYNC; //, USEAOUT, USEBOUT, USECOUT, USEDOUT;
sync_master sync_master_inst(
    .clk(FCLK),             // clock input
    .clk_2x(FCLK2X),        // clock 90 input
    .datain(RX_DATA),       // data inputs
    .rst(RESET_FCLK),       // reset input
    .useaout(),             // useA output for cascade
    .usebout(),             // useB output for cascade
    .usecout(),             // useC output for cascade
    .usedout(),             // useD output for cascade
    .ctrlout(),             // ctrl outputs for cascade
    .sdataout(RX_DATA_SYNC)
);

reg RX_DATA_SYNC_BUF, RX_DATA_SYNC_BUF2;
always @(posedge FCLK) begin
    RX_DATA_SYNC_BUF <= RX_DATA_SYNC;
    RX_DATA_SYNC_BUF2 <= RX_DATA_SYNC_BUF;
end

// 8b/10b record sync
wire [9:0] data_8b10b;
reg decoder_err;
rec_sync #(
    .DSIZE(DSIZE)
) rec_sync_inst (
    .reset(RESET_WCLK),
    .datain(invert_rx_data ? ~RX_DATA_SYNC_BUF2 : RX_DATA_SYNC_BUF2),
    .data(data_8b10b),
    .WCLK(WCLK),
    .FCLK(FCLK),
    .rec_sync_ready(rec_sync_ready),
    .decoder_err(decoder_err)
);

wire write_8b10b;
assign write_8b10b = rec_sync_ready & enable_rx;

reg [9:0] data_to_dec;
integer i;
always @(*) begin
    for (i=0; i<10; i=i+1)
        data_to_dec[(10-1)-i] = data_8b10b[i];
end

reg dispin;
wire dispout;
always @(posedge WCLK) begin
    if(RESET_WCLK)
        dispin <= 1'b0;
    else// if(write_8b10b)
        dispin <= dispout;
    // if(RESET_WCLK)
        // dispin <= 1'b0;
    // else
        // if(write_8b10b)
            // dispin <= ~dispout;
        // else
            // dispin <= dispin;
end

wire dec_k;
wire [7:0] dec_data;
wire code_err, disp_err;
decode_8b10b decode_8b10b_inst (
    .datain(data_to_dec),
    .dispin(dispin),
    .dataout({dec_k,dec_data}), // control character, data out
    .dispout(dispout),
    .code_err(code_err),
    .disp_err(disp_err)
);

always @(posedge WCLK) begin
    if(RESET_WCLK)
        decoder_err <= 1'b0;
    else
        decoder_err <= code_err | disp_err;
end
// Invalid symbols may or may not cause
// disparity errors depending on the symbol
// itself and the disparities of the previous and
// subsequent symbols. For this reason,
// DISP_ERR should always be combined
// with CODE_ERR to detect all errors.

always @(posedge WCLK) begin
    if(RESET_WCLK)
        decoder_err_cnt <= 0;
    else
        if(decoder_err && write_8b10b && decoder_err_cnt != 8'hff)
            decoder_err_cnt <= decoder_err_cnt + 1;
end

reg [2:0] byte_sel;
always @(posedge WCLK) begin
    if(RESET_WCLK || (write_8b10b && dec_k) || (write_8b10b && dec_k==0 && byte_sel==2))
        byte_sel <= 0;
    else if(write_8b10b)
        byte_sel <= byte_sel + 1;
    // if(RESET_WCLK || (write_8b10b && dec_k) || (write_8b10b && dec_k==0 && byte_sel==2))
        // byte_sel <= 0;
    // else
        // if(write_8b10b)
            // byte_sel <= byte_sel + 1;
        // else
            // byte_sel <= byte_sel;
end

reg [7:0] data_dec_in [2:0];
always @(posedge WCLK) begin
    for (i=0; i<3; i=i+1)
        data_dec_in[i] <= data_dec_in[i];
    if(RESET_WCLK)
        for (i=0; i<3; i=i+1)
            data_dec_in[i] <= 8'b0;
    else
        if(write_8b10b && dec_k==0)
            data_dec_in[byte_sel] <= dec_data;
end

reg cdc_fifo_write;
always @(posedge WCLK) begin
    if(RESET_WCLK)
        cdc_fifo_write <= 0;
    else
        if(write_8b10b && dec_k==0 && byte_sel==2)
            cdc_fifo_write <= 1;
        else
            cdc_fifo_write <= 0;
end

wire [23:0] cdc_data_out;
wire [23:0] wdata;
assign wdata = {data_dec_in[0], data_dec_in[1], data_dec_in[2]};

// generate long reset
reg [3:0] rst_cnt_wclk;
reg RST_LONG_WCLK;
always @(posedge WCLK) begin
    if (RESET_WCLK)
        rst_cnt_wclk <= 4'b1111; // start value
    else if (rst_cnt_wclk != 0)
        rst_cnt_wclk <= rst_cnt_wclk - 1;
    RST_LONG_WCLK <= |rst_cnt_wclk;
end

reg [3:0] rst_cnt_fifo_clk;
reg RST_LONG_FIFO_CLK;
always @(posedge FIFO_CLK) begin
    if (RESET_FIFO_CLK)
        rst_cnt_fifo_clk <= 4'b1111; // start value
    else if (rst_cnt_fifo_clk != 0)
        rst_cnt_fifo_clk <= rst_cnt_fifo_clk - 1;
    RST_LONG_FIFO_CLK <= |rst_cnt_fifo_clk;
end

wire wfull;
wire fifo_full, cdc_fifo_empty;
cdc_syncfifo #(
    .DSIZE(24),
    .ASIZE(2)
) cdc_syncfifo_i (
    .rdata(cdc_data_out),
    .wfull(wfull),
    .rempty(cdc_fifo_empty),
    .wdata(wdata),
    .winc(cdc_fifo_write),
    .wclk(WCLK),
    .wrst(RST_LONG_WCLK),
    .rinc(!fifo_full),
    .rclk(FIFO_CLK),
    .rrst(RST_LONG_FIFO_CLK)
);

wire [10:0] fifo_size_int;

gerneric_fifo #(
    .DATA_SIZE(24),
    .DEPTH(2048)
) fifo_i (
    .clk(FIFO_CLK),
    .reset(RST_LONG_FIFO_CLK),
    .write(!cdc_fifo_empty),
    .read(read),
    .data_in(cdc_data_out),
    .full(fifo_full),
    .empty(empty),
    .data_out(data),
    .size(fifo_size_int)
);

always @(posedge WCLK) begin
    if (wfull && cdc_fifo_write) begin  // write when FIFO full
        rx_fifo_full <= 1'b1;
    end else if (!wfull && cdc_fifo_write) begin  // write when FIFO not full
        rx_fifo_full <= 1'b0;
    end
end

always @(posedge WCLK) begin
    if (RESET_WCLK)
        lost_data_cnt <= 0;
    else
        if (wfull && cdc_fifo_write && lost_data_cnt != 8'b1111_1111)
            lost_data_cnt <= lost_data_cnt + 1;
end

always @(posedge FIFO_CLK) begin
    fifo_size <= {5'b0, fifo_size_int};
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
    .CLK(FCLK),
    .TRIG0({dec_k, dec_data, data_to_dec, rec_sync_ready, 1'b0, USEAOUT, USEBOUT, USECOUT, USEDOUT, RX_DATA_SYNC, RX_DATA})
);
`endif

endmodule
