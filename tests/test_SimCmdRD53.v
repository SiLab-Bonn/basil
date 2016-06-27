/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

//`default_nettype none

`include "cmd_rd53/cmd_rd53.v"
`include "cmd_rd53/cmd_rd53_core.v"

`include "utils/bus_to_ip.v"
`include "utils/cdc_pulse_sync.v"
`include "utils/cdc_reset_sync.v"

module tb (
		input wire          BUS_CLK,
		input wire          BUS_RST,
		input wire  [31:0]  BUS_ADD,
		inout wire  [31:0]  BUS_DATA,
		input wire          BUS_RD,
		input wire          BUS_WR,
		output wire         BUS_BYTE_ACCESS,
		output wire			CMD_SERIAL_OUT
	);


	localparam CMD_RD53_BASEADDR = 32'h0000;
	localparam CMD_RD53_HIGHADDR = 32'h2000-1;


	localparam ABUSWIDTH = 32;
	assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

	cmd_rd53
    #(
        .BASEADDR(CMD_RD53_BASEADDR),
        .HIGHADDR(CMD_RD53_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_cmd_rd53
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

    	.CMD_CLK(BUS_CLK),
    	.CMD_SERIAL_OUT(CMD_SERIAL_OUT)
	);


	initial begin
		$dumpfile("cmd_rd53.vcd");
		$dumpvars(0);
	end

endmodule
