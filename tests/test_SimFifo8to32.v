/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

`ifdef BASIL_SBUS
    `define SPLIT_BUS
`elsif BASIL_TOPSBUS
    `define SPLIT_BUS
`endif

`ifndef BASIL_SBUS
`include "utils/bus_to_ip.v"

`include "utils/cdc_syncfifo.v"
`include "utils/fifo_8_to_32.v"
`include "utils/generic_fifo.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"
`else
    $fatal("Sbus modules not implemented yet");
`endif

module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
`ifndef SPLIT_BUS
    inout wire  [31:0]   BUS_DATA,
`else
    input wire  [31:0]   BUS_DATA_IN,
    output wire [31:0]   BUS_DATA_OUT,
`endif
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS
);

localparam FIFO_BASEADDR = 32'h8000;
localparam FIFO_HIGHADDR = 32'h9000 - 1;

localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
localparam FIFO_HIGHADDR_DATA = 32'h9000_0000-1;

localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

// Connect tb internal bus to external split bus
`ifdef BASIL_TOPSBUS
    wire [31:0] BUS_DATA;
    assign BUS_DATA = BUS_DATA_IN;
    assign BUS_DATA_OUT = BUS_DATA;
`elsif BASIL_SBUS
    wire [31:0] BUS_DATA_OUT_1;
    assign BUS_DATA_OUT = BUS_DATA_OUT_1;
`endif

wire FIFO_READ_RX;
wire FIFO_EMPTY_RX;
wire [31:0] FIFO_DATA_RX;
wire cdc_fifo_write;
assign cdc_fifo_write = (BUS_ADD >= 32'h1000 && BUS_ADD < 32'h8000) & BUS_WR;

wire fifo_full, cdc_fifo_empty;
wire [7:0] cdc_data_out;

`ifndef BASIL_SBUS
cdc_syncfifo #(
`else
cdc_syncfifo_sbus #(
`endif
    .DSIZE(8),
    .ASIZE(3)
) cdc_syncfifo_i (
    .rdata(cdc_data_out),
    .wfull(),
    .rempty(cdc_fifo_empty),
`ifndef BASIL_SBUS
    .wdata(BUS_DATA),
`else
    .wdata(BUS_DATA_IN),
`endif
    .winc(cdc_fifo_write), .wclk(BUS_CLK), .wrst(BUS_RST),
    .rinc(!fifo_full), .rclk(BUS_CLK), .rrst(BUS_RST)
);

wire FIFO_READ, FIFO_EMPTY;
wire [31:0] FIFO_DATA;

`ifndef BASIL_SBUS
fifo_8_to_32 #(
`else
fifo_8_to_32_sbus #(
`endif
    .DEPTH(1024)
) fifo_8_to_32_i (
    .RST(BUS_RST),
    .CLK(BUS_CLK),
    .WRITE(!cdc_fifo_empty),
    .READ(FIFO_READ),
    .DATA_IN(cdc_data_out),
    .FULL(fifo_full),
    .EMPTY(FIFO_EMPTY),
    .DATA_OUT(FIFO_DATA)
);



`ifndef BASIL_SBUS
bram_fifo #(
`else
bram_fifo_sbus #(
`endif
    .BASEADDR(FIFO_BASEADDR),
    .HIGHADDR(FIFO_HIGHADDR),
    .BASEADDR_DATA(FIFO_BASEADDR_DATA),
    .HIGHADDR_DATA(FIFO_HIGHADDR_DATA),
    .ABUSWIDTH(ABUSWIDTH)
) i_out_fifo (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
`ifndef BASIL_SBUS
    .BUS_DATA(BUS_DATA),
`else
    .BUS_DATA_IN(BUS_DATA_IN),
    .BUS_DATA_OUT(BUS_DATA_OUT_1),
`endif
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .FIFO_READ_NEXT_OUT(FIFO_READ),
    .FIFO_EMPTY_IN(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),

    .FIFO_NOT_EMPTY(),
    .FIFO_FULL(),
    .FIFO_NEAR_FULL(),
    .FIFO_READ_ERROR()
);

`ifndef VERILATOR_SIM
initial begin
    $dumpfile("test_SimFifo8to32.vcd");
    $dumpvars(0);
end
`endif

endmodule
