/*
 * Module:  cdc_fifo_bram
 * Author:  Lev Maleev
 * Email:   lev.maleev@oeaw.ac.at
 * Date:    2026-06-17
 *
 * Description:
 * Dual-clock show-ahead FIFO utilizing AMD/Xilinx BRAM.
 *
 * Revision:
 * v1.0 - Initial design
 */
`ifndef CDC_FIFO_BRAM
`define CDC_FIFO_BRAM

`timescale 1ns / 1ps
`default_nettype none


// Dual-clock show-ahead FIFO with overflow protection utilizing AMD/Xilinx block RAM
module cdc_fifo_bram #(
    parameter integer DSIZE = 32,
    parameter integer ASIZE = 8
)(
    input wire              arst,   // active high asynchronous reset
    // write port
    input wire              wclk,   // write port clock
    input wire [DSIZE-1:0]  wdata,  // write data
    input wire              we,     // active high write enable
    output wire             wfull,  // active high FIFO full indication
    // read port
    input wire              rclk,   // read clock
    output reg [DSIZE-1:0]  rdata,  // read data
    input wire              re,     // active high read enable
    output reg              rempty  // active high FIFO empty indication
);
    // synchronize reset input into wclk and rclk clock domains
    reg [3:0] reset_sync_wclk, reset_sync_rclk;
    wire wrst, rrst;

    always @(posedge wclk, posedge arst) begin: reset_sync_wclk_set
        if (arst) begin
            reset_sync_wclk <= 4'b1111;
        end else begin
            reset_sync_wclk <= {reset_sync_wclk[$left(reset_sync_wclk)-1:0], 1'b0};
        end
    end: reset_sync_wclk_set
    assign wrst = reset_sync_wclk[$left(reset_sync_wclk)];

    always @(posedge rclk, posedge arst) begin: reset_sync_rclk_set
        if (arst) begin
            reset_sync_rclk <= 4'b1111;
        end else begin
            reset_sync_rclk <= {reset_sync_rclk[$left(reset_sync_rclk)-1:0], 1'b0};
        end
    end: reset_sync_rclk_set
    assign rrst = reset_sync_rclk[$left(reset_sync_rclk)];

    // FIFO memory, AMD/Xilinx block RAM should be inferred
    localparam integer MEMORY_SIZE = 2**ASIZE;
    (* ram_style = "block" *)
    reg [DSIZE-1:0] memory [MEMORY_SIZE-1:0];
    reg [ASIZE-1:0] memory_waddr, memory_raddr;
    reg [DSIZE-1:0] memory_q;
    wire memory_we;

    always @(posedge wclk) begin: memory_write
        if (memory_we) begin
            memory[memory_waddr] <= wdata;
        end
    end: memory_write

    always @(posedge rclk) begin: memory_read
        memory_q <= memory[memory_raddr];
    end: memory_read

    // transfer memory write address into read clock domain and memory read address into write clock domain
    wire [ASIZE-1:0] memory_waddr_gray = memory_waddr ^ {1'b0, memory_waddr[ASIZE-1:1]};
    reg [ASIZE-1:0] memory_waddr_gray_rclk [1:0]; // synchronizer chain: 2 FFs for each address bit
    always @(posedge rclk) begin: memory_waddr_gray_rclk_set
        memory_waddr_gray_rclk[1] <= memory_waddr_gray_rclk[0];
        memory_waddr_gray_rclk[0] <= memory_waddr_gray;
    end: memory_waddr_gray_rclk_set
    wire [ASIZE-1:0] memory_waddr_rclk;

    wire [ASIZE-1:0] memory_raddr_gray = memory_raddr ^ {1'b0, memory_raddr[ASIZE-1:1]};
    reg [ASIZE-1:0] memory_raddr_gray_wclk [1:0]; // synchronizer chain: 2 FFs for each address bit
    always @(posedge wclk) begin: memory_raddr_gray_wclk_set
        memory_raddr_gray_wclk[1] <= memory_raddr_gray_wclk[0];
        memory_raddr_gray_wclk[0] <= memory_raddr_gray;
    end: memory_raddr_gray_wclk_set
    wire [ASIZE-1:0] memory_raddr_wclk;

    assign memory_waddr_rclk[ASIZE-1] = memory_waddr_gray_rclk[1][ASIZE-1];
    assign memory_raddr_wclk[ASIZE-1] = memory_raddr_gray_wclk[1][ASIZE-1];
    for (genvar i = ASIZE-2; i >= 0; i--) begin: g_cdc_addr_loop
        assign memory_waddr_rclk[i] = memory_waddr_gray_rclk[1][i] ^ memory_waddr_rclk[i+1];
        assign memory_raddr_wclk[i] = memory_raddr_gray_wclk[1][i] ^ memory_raddr_wclk[i+1];
    end: g_cdc_addr_loop

    // FIFO write port implementation
    wire  [ASIZE-1:0] level_wclk = memory_waddr - memory_raddr_wclk;
    assign wfull = (level_wclk) > (MEMORY_SIZE-2) ? 1'b1: 1'b0;
    assign memory_we = we & !wfull;

    // memory write address counter
    always @(posedge wclk, posedge wrst) begin: memory_waddr_set
        if (wrst) begin
            memory_waddr <= {ASIZE{1'b0}};
        end else begin
            if (memory_we) begin
                memory_waddr <= memory_waddr + 1'b1;
            end;
        end
    end: memory_waddr_set

    // FIFO read port implementation
    wire memory_re;

    // memory read address counter
    reg memory_raddr_lsb;

    always @(posedge rclk, posedge rrst) begin: memory_raddr_set
        if (rrst) begin
            memory_raddr <= {ASIZE{1'b0}};
            memory_raddr_lsb <= 1'b0;
        end else begin
            memory_raddr_lsb <= memory_raddr[0];
            if (memory_re) begin
                memory_raddr <= memory_raddr + 1'b1;
            end;
        end
    end: memory_raddr_set

    // show-ahead buffer
    reg [DSIZE-1:0] showahead_buf [3:0];
    reg [1:0] showahead_buf_wptr, showahead_buf_rptr;
    wire [1:0] showahead_buf_level = showahead_buf_wptr - showahead_buf_rptr;

    assign memory_re = (memory_raddr != memory_waddr_rclk && showahead_buf_level < 3) ? 1'b1 : 1'b0;

    always @(posedge rclk, posedge rrst) begin: showahead_buf_wptr_set
        if (rrst) begin
            showahead_buf_wptr <= 2'b00;
        end else begin
            if (memory_raddr_lsb^memory_raddr[0]) begin
                showahead_buf_wptr <= showahead_buf_wptr + 1'b1;
            end
        end
    end: showahead_buf_wptr_set

    always @(posedge rclk) begin: showahead_buf_set
        if (memory_raddr_lsb^memory_raddr[0]) begin
            showahead_buf[showahead_buf_wptr] <= memory_q;
        end
    end: showahead_buf_set

    always @(posedge rclk, posedge rrst) begin: fifo_read
        if (rrst) begin
            rempty <= 1'b1;
            rdata <= {DSIZE{1'b0}};
            showahead_buf_rptr <= 2'b00;
        end else begin
            if (rempty) begin
                if (showahead_buf_level) begin
                    rempty <= 1'b0;
                    rdata <= showahead_buf[showahead_buf_rptr];
                end
            end else begin
                if (re) begin
                    rdata <= showahead_buf[showahead_buf_rptr+1'b1];
                    showahead_buf_rptr <= showahead_buf_rptr + 1'b1;
                    if (showahead_buf_level == 2'b01) begin
                        rempty <= 1'b1;
                    end
                end
            end
        end
    end: fifo_read

endmodule
`endif
