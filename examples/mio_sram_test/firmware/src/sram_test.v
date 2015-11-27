/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module sram_test (
    input wire FCLK_IN,

    // full speed
    inout wire [7:0] BUS_DATA,
    input wire [15:0] ADD,
    input wire RD_B,
    input wire WR_B,

    // high speed
    inout wire [7:0] FD,
    input wire FREAD,
    input wire FSTROBE,
    input wire FMODE,

    //SRAM
    output wire [19:0] SRAM_A,
    inout wire [15:0] SRAM_IO,
    output wire SRAM_BHE_B,
    output wire SRAM_BLE_B,
    output wire SRAM_CE1_B,
    output wire SRAM_OE_B,
    output wire SRAM_WE_B,

    output wire [4:0] LED,

    inout wire SDA,
    inout wire SCL

);

assign SDA = 1'bz;
assign SCL = 1'bz;

assign LED = 5'b10110;


wire [15:0] BUS_ADD;
wire BUS_CLK, BUS_RD, BUS_WR, BUS_RST;

// BASIL bus mapping
assign BUS_CLK = FCLK_IN;
fx2_to_bus i_fx2_to_bus (
    .ADD(ADD),
    .RD_B(RD_B),
    .WR_B(WR_B),

    .BUS_CLK(BUS_CLK),
    .BUS_ADD(BUS_ADD),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .CS_FPGA()
);

reset_gen i_reset_gen(.CLK(BUS_CLK), .RST(BUS_RST));

//MODULE ADREESSES
localparam GPIO_CONTROL_BASEADDR = 16'h0000;
localparam GPIO_CONTROL_HIGHADDR = 16'h000f;

localparam GPIO_PATTERN_BASEADDR = 16'h0010;
localparam GPIO_PATTERN_HIGHADDR = 16'h001f;

localparam FIFO_BASEADDR = 16'h0020;
localparam FIFO_HIGHADDR = 16'h002f;

localparam PULSE_BASEADDR = 32'h0030;
localparam PULSE_HIGHADDR = 32'h003f;

// USER MODULES //
wire [4:0] CONTROL_NOT_USED;
wire PATTERN_EN;
wire COUNTER_EN;
wire COUNTER_DIRECT;

gpio
#(
    .BASEADDR(GPIO_CONTROL_BASEADDR),
    .HIGHADDR(GPIO_CONTROL_HIGHADDR),

    .IO_WIDTH(8),
    .IO_DIRECTION(8'hff)
) i_gpio_control
(
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO({CONTROL_NOT_USED, COUNTER_DIRECT, PATTERN_EN, COUNTER_EN})
);

wire [31:0] PATTERN;
gpio
#(
    .BASEADDR(GPIO_PATTERN_BASEADDR),
    .HIGHADDR(GPIO_PATTERN_HIGHADDR),

    .IO_WIDTH(32),
    .IO_DIRECTION(32'hffffffff)
) i_gpio_pattern
(
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(PATTERN)
);


wire PULSE;
pulse_gen
#(
    .BASEADDR(PULSE_BASEADDR),
    .HIGHADDR(PULSE_HIGHADDR)
) i_pulse_gen
(
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .PULSE_CLK(BUS_CLK),
    .EXT_START(1'b0),
    .PULSE(PULSE)
);

wire PATTERN_FIFO_READ;
wire PATTERN_FIFO_EMPTY;

wire [31:0] COUNTER_FIFO_DATA;
wire COUNTER_FIFO_EMPTY;
wire COUNTER_FIFO_READ;

wire ARB_READY_OUT, ARB_WRITE_OUT;
wire [31:0] ARB_DATA_OUT;

rrp_arbiter
#(
    .WIDTH(2)
) i_rrp_arbiter
(
    .RST(BUS_RST),
    .CLK(BUS_CLK),

    .WRITE_REQ({COUNTER_EN | PULSE, PATTERN_EN}),
    .HOLD_REQ({2'b0}),
    .DATA_IN({COUNTER_FIFO_DATA, PATTERN}),
    .READ_GRANT({COUNTER_FIFO_READ, PATTERN_FIFO_READ}),

    .READY_OUT(ARB_READY_OUT),
    .WRITE_OUT(ARB_WRITE_OUT),
    .DATA_OUT(ARB_DATA_OUT)
);

wire USB_READ;
assign USB_READ = FREAD && FSTROBE;
wire [7:0] FD_SRAM;
sram_fifo
#(
    .BASEADDR(FIFO_BASEADDR),
    .HIGHADDR(FIFO_HIGHADDR)
) i_out_fifo (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .SRAM_A(SRAM_A),
    .SRAM_IO(SRAM_IO),
    .SRAM_BHE_B(SRAM_BHE_B),
    .SRAM_BLE_B(SRAM_BLE_B),
    .SRAM_CE1_B(SRAM_CE1_B),
    .SRAM_OE_B(SRAM_OE_B),
    .SRAM_WE_B(SRAM_WE_B),

    .USB_READ(USB_READ),
    .USB_DATA(FD_SRAM),

    .FIFO_READ_NEXT_OUT(ARB_READY_OUT),
    .FIFO_EMPTY_IN(!ARB_WRITE_OUT),
    .FIFO_DATA(ARB_DATA_OUT),

    .FIFO_NOT_EMPTY(),
    .FIFO_READ_ERROR(),
    .FIFO_FULL(),
    .FIFO_NEAR_FULL()
);

reg [31:0] count;
always@(posedge BUS_CLK)
    if(BUS_RST)
        count <= 0;
    else if (COUNTER_FIFO_READ)
        count <= count + 1;

wire [7:0] count_send [3:0];
assign count_send[0] = count*4;
assign count_send[1] = count*4 + 1;
assign count_send[2] = count*4 + 2;
assign count_send[3] = count*4 + 3;

assign COUNTER_FIFO_DATA = {count_send[3], count_send[2], count_send[1], count_send[0]};

reg [7:0] count_direct;
always@(posedge BUS_CLK)
    if(BUS_RST)
        count_direct <= 0;
    else if (USB_READ)
        count_direct <= count_direct + 1;

assign FD = COUNTER_DIRECT ? count_direct: FD_SRAM;

endmodule
