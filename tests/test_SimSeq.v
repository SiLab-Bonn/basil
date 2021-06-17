/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

`include "utils/bus_to_ip.v"

`include "pulse_gen/pulse_gen.v"
`include "pulse_gen/pulse_gen_core.v"

`include "seq_gen/seq_gen.v"
`include "seq_gen/seq_gen_core.v"

`include "seq_rec/seq_rec.v"
`include "seq_rec/seq_rec_core.v"

`include "utils/3_stage_synchronizer.v"
`include "utils/flag_domain_crossing.v"
`include "utils/cdc_pulse_sync.v"
`include "utils/ramb_8_to_n.v"


module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
    inout wire  [31:0]  BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS
);

localparam PULSE_BASEADDR = 32'h0000;
localparam PULSE_HIGHADDR = PULSE_BASEADDR + 15;

localparam SEQ_GEN_BASEADDR = 32'h1000_0000;
localparam SEQ_GEN_HIGHADDR = 32'h2000_0000-1;

localparam SEQ_REC_BASEADDR = 32'h2000_0000;
localparam SEQ_REC_HIGHADDR = 32'h3000_0000 - 1;

localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

`ifdef BITS
    localparam BITS = `BITS;
`else
    localparam BITS = 8;
`endif

`ifdef MEM_KB
    localparam MEM_KB = `MEM_KB;
`else
    localparam MEM_KB = 1;
`endif

wire EX_START_PULSE;
pulse_gen #(
    .BASEADDR(PULSE_BASEADDR),
    .HIGHADDR(PULSE_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH)
) i_pulse_gen (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .PULSE_CLK(BUS_CLK),
    .EXT_START(1'b0),
    .PULSE(EX_START_PULSE)
);

wire [BITS-1:0] SEQ_OUT;
seq_gen #(
    .BASEADDR(SEQ_GEN_BASEADDR),
    .HIGHADDR(SEQ_GEN_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .MEM_BYTES(MEM_KB*1024),
    .OUT_BITS(BITS)
) i_seq_gen (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .SEQ_EXT_START(EX_START_PULSE),
    .SEQ_CLK(BUS_CLK),
    .SEQ_OUT(SEQ_OUT)
);

seq_rec #(
    .BASEADDR(SEQ_REC_BASEADDR),
    .HIGHADDR(SEQ_REC_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .MEM_BYTES(MEM_KB*1024),
    .IN_BITS(BITS)
) i_seq_rec (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .SEQ_EXT_START(EX_START_PULSE),
    .SEQ_CLK(BUS_CLK),
    .SEQ_IN(SEQ_OUT)
);



initial begin
    $dumpfile("seq.vcd");
    $dumpvars(0);
end

endmodule
