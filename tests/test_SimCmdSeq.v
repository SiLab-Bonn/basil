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

`include "cmd_seq/cmd_seq.v"
`include "cmd_seq/cmd_seq_core.v"

`include "seq_rec/seq_rec.v"
`include "seq_rec/seq_rec_core.v"

// `include "utils/glbl.v"
`include "utils/ODDR_sim.v"
`include "utils/cdc_pulse_sync.v"
`include "utils/3_stage_synchronizer.v"
`include "utils/flag_domain_crossing.v"

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

localparam CMD_SEQ_BASEADDR = 32'h1000;
localparam CMD_SEQ_HIGHADDR = 32'h2000 - 1;

localparam SEQ_REC_BASEADDR = 32'h2000;
localparam SEQ_REC_HIGHADDR = 32'h1_3000 - 1;

localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

localparam CMD_MEM_SIZE = 2048;


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

wire CMD_DATA;
wire CMD_EXT_START_ENABLE;
wire CMD_READY;
wire CMD_START_FLAG;
cmd_seq #(
    .BASEADDR(CMD_SEQ_BASEADDR),
    .HIGHADDR(CMD_SEQ_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .OUTPUTS(1),
    .CMD_MEM_SIZE(CMD_MEM_SIZE)
) i_cmd_seq (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .CMD_CLK_IN(BUS_CLK),
    .CMD_CLK_OUT(),
    .CMD_DATA(CMD_DATA),

    .CMD_EXT_START_FLAG(EX_START_PULSE),
    .CMD_EXT_START_ENABLE(CMD_EXT_START_ENABLE),
    .CMD_READY(CMD_READY),
    .CMD_START_FLAG(CMD_START_FLAG)
);

reg EX_START_PULSE_FF, EX_START_PULSE_FF2, EX_START_PULSE_FF3, EX_START_PULSE_FF4;
always @(posedge BUS_CLK) begin
    EX_START_PULSE_FF <= EX_START_PULSE;
    EX_START_PULSE_FF2 <= EX_START_PULSE_FF;
    EX_START_PULSE_FF3 <= EX_START_PULSE_FF2;
    EX_START_PULSE_FF4 <= EX_START_PULSE_FF3;
end

reg CMD_DATA_FF;
always @(posedge BUS_CLK) begin
    CMD_DATA_FF <= CMD_DATA;  // delay data, SEQ_EXT_START signal hast to come first by 1 clock cycle
end

reg CMD_READY_FF, CMD_READY_FF2, CMD_READY_FF3;
always @(posedge BUS_CLK) begin
    CMD_READY_FF <= CMD_READY;  // delay for short pulses
    CMD_READY_FF2 <= CMD_READY_FF;
    CMD_READY_FF3 <= CMD_READY_FF2;
end
wire test;
assign test = (CMD_START_FLAG && (!CMD_READY_FF || !CMD_READY_FF2)) || (EX_START_PULSE_FF4 && CMD_EXT_START_ENABLE);

seq_rec #(
    .BASEADDR(SEQ_REC_BASEADDR),
    .HIGHADDR(SEQ_REC_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .MEM_BYTES(CMD_MEM_SIZE*8*4),
    .IN_BITS(8)
) i_seq_rec (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .SEQ_EXT_START((CMD_START_FLAG && (!CMD_READY_FF || !CMD_READY_FF2)) || (EX_START_PULSE_FF4 && CMD_EXT_START_ENABLE)),  // all output modes
    // .SEQ_EXT_START(EX_START_PULSE_FF4 && CMD_EXT_START_ENABLE),  // output mode 0
    // .SEQ_EXT_START(EX_START_PULSE_FF3 && CMD_EXT_START_ENABLE),  // output mode 1
    .SEQ_CLK(BUS_CLK),
    .SEQ_IN({7'b0, CMD_DATA_FF})  // all output modes
);



initial begin
    $dumpfile("cmd_seq.vcd");
    $dumpvars(0);
end

endmodule
