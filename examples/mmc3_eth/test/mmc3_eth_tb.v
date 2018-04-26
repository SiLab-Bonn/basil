/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

`include "firmware/src/mmc3_eth_core.v"
`include "gpio/gpio.v"
`include "bram_fifo/bram_fifo.v"
`include "bram_fifo/bram_fifo_core.v"
`include "utils/reset_gen.v"
`include "utils/fifo_32_to_8.v"
`include "utils/generic_fifo.v"
`include "utils/clock_multiplier.v"
`include "utils/clock_divider.v"
`include "utils/rbcp_to_bus.v"
`include "utils/bus_to_ip.v"


module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
    inout wire  [31:0]  BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS
);

localparam FIFO_BASEADDR = 32'h8000;
localparam FIFO_HIGHADDR = 32'h9000-1;

localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;

localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;


localparam RESET_DELAY = 5000;
/*
localparam CLOCKPERIOD_CLKIN1 = 10*1000;
reg CLKIN1;
initial CLKIN1 = 1'b0;
always #(CLOCKPERIOD_CLKIN1 / 2) CLKIN1 = !CLKIN1;
*/
// ----- Clock (mimics a PLL) -----
localparam PLL_MUL            = 5;
localparam PLL_DIV_BUS_CLK    = 7;
localparam PLL_DIV_CLK250     = 4;
localparam PLL_DIV_CLK125TX   = 8;
localparam PLL_DIV_CLK125TX90 = 8;
localparam PLL_DIV_CLK125RX   = 8;
localparam PLL_LOCK_DELAY     = 1000*1000;

wire PLL_VCO, CLK250, CLK125TX, CLK125TX90, CLK125RX;

clock_multiplier #( .MULTIPLIER(PLL_MUL)  ) i_clock_multiplier( .CLK(BUS_CLK),                      .CLOCK(PLL_VCO)  );
//clock_divider #(.DIVISOR(PLL_DIV_BUS_CLK) ) i_clock_divisor_1 ( .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(BUS_CLK)  );
clock_divider #(.DIVISOR(PLL_DIV_CLK250)  ) i_clock_divisor_2 ( .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(CLK250)   );
clock_divider #(.DIVISOR(PLL_DIV_CLK125TX)) i_clock_divisor_3 ( .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(CLK125TX) );
clock_divider #(.DIVISOR(PLL_DIV_CLK125RX)) i_clock_divisor_4 ( .CLK(PLL_VCO), .RESET(1'b0), .CE(), .CLOCK(CLK125RX) );

reg LOCKED;
initial begin
    LOCKED = 1'b0;
    #(PLL_LOCK_DELAY) LOCKED = 1'b1;
end
// -------------------------


// ------- RESET/CLOCK  ------- //
//wire BUS_RST;
//reset_gen ireset_gen(.CLK(BUS_CLK), .RST(BUS_RST));

reg RESET_N;
initial begin
    RESET_N = 1'b0;
    #(RESET_DELAY) RESET_N = 1'b1;
end



// -------  USER MODULES  ------- //
wire FIFO_FULL, FIFO_READ, FIFO_NOT_EMPTY, FIFO_WRITE;
wire [31:0] FIFO_DATA;
bram_fifo
#(
    .BASEADDR(FIFO_BASEADDR),
    .HIGHADDR(FIFO_HIGHADDR),
    .BASEADDR_DATA(FIFO_BASEADDR_DATA),
    .HIGHADDR_DATA(FIFO_HIGHADDR_DATA),
    .ABUSWIDTH(32)
) i_out_fifo (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .FIFO_READ_NEXT_OUT(FIFO_READ),
    .FIFO_EMPTY_IN(!FIFO_WRITE),
    .FIFO_DATA(FIFO_DATA),

    .FIFO_NOT_EMPTY(FIFO_NOT_EMPTY),
    .FIFO_FULL(FIFO_FULL),
    .FIFO_NEAR_FULL(),
    .FIFO_READ_ERROR()
);


wire [7:0] GPIO;
wire ENABLE;
assign ENABLE = GPIO[0];

mmc3_eth_core i_mmc3_eth_core(
    .RESET_N(RESET_N),

    // clocks from PLL
    .BUS_CLK(BUS_CLK), .CLK125TX(CLK125TX), .CLK125TX90(CLK125TX90), .CLK125RX(CLK125RX),
    .PLL_LOCKED(LOCKED),

    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .BUS_BYTE_ACCESS(BUS_BYTE_ACCESS),

    .fifo_empty(!FIFO_NOT_EMPTY),
    .fifo_full(FIFO_FULL),
    .FIFO_NEXT(!FIFO_FULL && ENABLE),
    .FIFO_DATA(FIFO_DATA),
    .FIFO_WRITE(FIFO_WRITE),

    .GPIO(GPIO)
    );


initial begin
    $dumpfile("/tmp/mmc3_eth.vcd");
    $dumpvars(0);
end

endmodule
