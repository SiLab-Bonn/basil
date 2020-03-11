/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps / 1ps


`include "utils/bus_to_ip.v"

`include "gpio/gpio.v"


`include "spi/blk_mem_gen_8_to_1_2k.v"
`include "jtag_master/jtag_master.v"
`include "jtag_master/jtag_master_core.v"

`include "pulse_gen/pulse_gen.v"
`include "pulse_gen/pulse_gen_core.v"

`include "utils/cdc_pulse_sync.v"
`include "utils/cdc_reset_sync.v"
`include "utils/CG_MOD_pos.v"
`include "utils/clock_divider.v"

`include "utils/RAMB16_S1_S9_sim.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"
`include "utils/generic_fifo.v"

module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
    inout wire  [31:0]  BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS
);

// MODULE ADREESSES //
localparam JTAGM_BASEADDR = 32'h0000;
localparam JTAGM_HIGHADDR = 32'h1000-1;

localparam GPIO_BASEADDR_DEV1 = 16'h1000;
localparam GPIO_HIGHADDR_DEV1 = 16'h100f;

localparam GPIO_BASEADDR_DEV2 = 16'h2000;
localparam GPIO_HIGHADDR_DEV2 = 16'h200f;

localparam PULSE_BASEADDR = 32'h3000;
localparam PULSE_HIGHADDR = PULSE_BASEADDR + 15;

localparam FIFO1_BASEADDR = 32'h8000;
localparam FIFO1_HIGHADDR = 32'h9000-1;

localparam FIFO1_BASEADDR_DATA = 32'h8000_0000;
localparam FIFO1_HIGHADDR_DATA = 32'h9000_0000;

localparam FIFO2_BASEADDR = 32'ha000;
localparam FIFO2_HIGHADDR = 32'hb000-1;

localparam FIFO2_BASEADDR_DATA = 32'ha000_0000;
localparam FIFO2_HIGHADDR_DATA = 32'hb000_0000;


localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

// MODULES //
wire JTAG_CLK;
clock_divider #(
    .DIVISOR(20)
) i_clock_divisor_jtag (
    .CLK(BUS_CLK),
    .RESET(1'b0),
    .CE(),
    .CLOCK(JTAG_CLK)
);

wire TCK, TDI, TDO, TMS, SEN, SLD;

jtag_master #(
    .BASEADDR(JTAGM_BASEADDR),
    .HIGHADDR(JTAGM_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .MEM_BYTES(2000)
) i_jtag_master (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .JTAG_CLK(JTAG_CLK),

    .TCK(TCK),
    .TDI(TDI),
    .TDO(TDO),
    .TMS(TMS),
    .SEN(SEN),
    .SLD(SLD)
);

wire td_int;
wire [31:0] debug_reg1, debug_reg2;

wire wr_fifo;
jtag_tap i_jtag_tap1(.jtag_tms_i(TMS), .jtag_tck_i(TCK), .jtag_trstn_i(1'b1), .jtag_tdi_i(TDI), .jtag_tdo_o(td_int), .debug_reg(debug_reg1));
jtag_tap i_jtag_tap2(.jtag_tms_i(TMS), .jtag_tck_i(TCK), .jtag_trstn_i(1'b1), .jtag_tdi_i(td_int), .jtag_tdo_o(TDO), .debug_reg(debug_reg2), .is_tap_state_update_dr_o(wr_fifo));

wire D1_F1;
wire [5:0] D1_F2;
wire [3:0] D1_F3;
wire [20:0] D1_F4;
assign {D1_F4, D1_F3, D1_F2, D1_F1} = debug_reg1;

wire D2_F1;
wire [5:0] D2_F2;
wire [3:0] D2_F3;
wire [20:0] D2_F4;
assign {D2_F4, D2_F3, D2_F2, D2_F1} = debug_reg2;

gpio #(
    .BASEADDR(GPIO_BASEADDR_DEV1),
    .HIGHADDR(GPIO_HIGHADDR_DEV1),
    .IO_WIDTH(32),
    .IO_DIRECTION(32'h00000000)
) i_gpio_dev2 (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD[15:0]),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(debug_reg2)
);

gpio #(
    .BASEADDR(GPIO_BASEADDR_DEV2),
    .HIGHADDR(GPIO_HIGHADDR_DEV2),
    .IO_WIDTH(32),
    .IO_DIRECTION(32'h00000000)
) i_gpio_dev1 (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD[15:0]),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(debug_reg1)
);

output reg wr_fifo_FF;
output reg fifo_strobe;
always @(posedge BUS_CLK)
begin
    wr_fifo_FF <= wr_fifo;
end
assign fifo_strobe = wr_fifo_FF && ~wr_fifo;

bram_fifo #(
    .BASEADDR(FIFO1_BASEADDR),
    .HIGHADDR(FIFO1_HIGHADDR),
    .BASEADDR_DATA(FIFO1_BASEADDR_DATA),
    .HIGHADDR_DATA(FIFO1_HIGHADDR_DATA),
    .ABUSWIDTH(ABUSWIDTH)
) i_out_fifo_tap_1 (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .FIFO_READ_NEXT_OUT(),
    .FIFO_EMPTY_IN(~fifo_strobe),
    .FIFO_DATA(debug_reg1),

    .FIFO_NOT_EMPTY(),
    .FIFO_FULL(),
    .FIFO_NEAR_FULL(),
    .FIFO_READ_ERROR()
);

bram_fifo #(
    .BASEADDR(FIFO2_BASEADDR),
    .HIGHADDR(FIFO2_HIGHADDR),
    .BASEADDR_DATA(FIFO2_BASEADDR_DATA),
    .HIGHADDR_DATA(FIFO2_HIGHADDR_DATA),
    .ABUSWIDTH(ABUSWIDTH)
) i_out_fifo_tap_2 (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .FIFO_READ_NEXT_OUT(),
    .FIFO_EMPTY_IN(~fifo_strobe),
    .FIFO_DATA(debug_reg2),

    .FIFO_NOT_EMPTY(),
    .FIFO_FULL(),
    .FIFO_NEAR_FULL(),
    .FIFO_READ_ERROR()
);

initial begin
    $dumpfile("jtag_master.vcd");
    $dumpvars(0);
end

endmodule
