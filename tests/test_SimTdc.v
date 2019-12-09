/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

`include "utils/clock_multiplier.v"
`include "utils/DCM_sim.v"
`include "utils/IDDR_sim.v"
`include "utils/ddr_des.v"

`include "seq_gen/seq_gen.v"
`include "seq_gen/seq_gen_core.v"

`include "tdc_s3/tdc_s3_core.v"
`include "tdc_s3/tdc_s3.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"

`include "utils/bus_to_ip.v"

`include "utils/cdc_syncfifo.v"
`include "utils/cdc_pulse_sync.v"
`include "utils/flag_domain_crossing.v"
`include "utils/generic_fifo.v"
`include "utils/3_stage_synchronizer.v"


module tb (
    input wire           BUS_CLK,
    input wire           BUS_RST,
    input wire   [31:0]  BUS_ADD,
    inout wire   [31:0]  BUS_DATA,
    input wire           BUS_RD,
    input wire           BUS_WR,
    output wire          BUS_BYTE_ACCESS
);

localparam SEQ_GEN_BASEADDR = 32'h0000;
localparam SEQ_GEN_HIGHADDR = 32'h8000 - 1;

localparam TDC_BASEADDR = 32'h8000;
localparam TDC_HIGHADDR = 32'h8100 - 1;

localparam FIFO_BASEADDR = 32'h8300;
localparam FIFO_HIGHADDR = 32'h8400 - 1;

localparam FIFO_BASEADDR_DATA = 32'h6000_0000;
localparam FIFO_HIGHADDR_DATA = 32'h7000_0000 - 1;

localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h6000_0000 ? 1'b1 : 1'b0;

wire TDC_TRIGGER_IN, TDC_ARM, TDC_EXT_EN;
wire [2:0] TDC_IN;
wire [3:0] NOT_CONNECTED;
wire [7:0] SEQ_OUT;
assign NOT_CONNECTED = SEQ_OUT[7:4];
assign TDC_TRIGGER_IN = SEQ_OUT[0];
// Use same TDC for all TDC modules
assign TDC_IN[0] = SEQ_OUT[1];
assign TDC_IN[1] = SEQ_OUT[1];
assign TDC_IN[2] = SEQ_OUT[1];
assign TDC_ARM = SEQ_OUT[2];
assign TDC_EXT_EN = SEQ_OUT[3];

wire CLK_40, CLK_160, CLK_320, CLK_320_TO_DCM, CLK_640;

DCM #(
    .CLKFX_MULTIPLY(40),
    .CLKFX_DIVIDE(3)
) i_dcm_1 (
    .CLK0(), .CLK180(), .CLK270(), .CLK2X(), .CLK2X180(), .CLK90(),
    .CLKDV(), .CLKFX(CLK_320_TO_DCM), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(),
    .CLKFB(1'b0), .CLKIN(BUS_CLK), .DSSEN(1'b0), .PSCLK(1'b0), .PSEN(1'b0), .PSINCDEC(1'b0), .RST(1'b0)
);

DCM #(
    .CLKFX_MULTIPLY(1),
    .CLKFX_DIVIDE(2),
    .CLKDV_DIVIDE(8)
) i_dcm_2 (
    .CLK0(CLK_320), .CLK180(), .CLK270(), .CLK2X(CLK_640), .CLK2X180(), .CLK90(),
    .CLKDV(CLK_40), .CLKFX(CLK_160), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(),
    .CLKFB(1'b0), .CLKIN(CLK_320_TO_DCM), .DSSEN(1'b0), .PSCLK(1'b0), .PSEN(1'b0), .PSINCDEC(1'b0), .RST(1'b0)
);


seq_gen #(
    .BASEADDR(SEQ_GEN_BASEADDR),
    .HIGHADDR(SEQ_GEN_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .MEM_BYTES(8 * 8 * 1024 - 1),
    .OUT_BITS(8)
) i_seq_gen (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .SEQ_EXT_START(),
    .SEQ_CLK(CLK_640),
    .SEQ_OUT(SEQ_OUT)
);


localparam CLKDV = 4;  // division factor from 160 MHz clock to DC_CLK (here 40 MHz)
wire [2:0] TDC_FIFO_EMPTY;
wire [31:0] TDC_FIFO_DATA [2:0];
wire [2:0] TDC_FIFO_READ;
wire [CLKDV*4-1:0] FAST_TRIGGER_OUT;
wire [1:0] TRIG_FAST_OUT;
// First TDC module: creates fast sampled trigger signal to use it for other TDC modules.
tdc_s3 #(
    .BASEADDR(TDC_BASEADDR),
    .HIGHADDR(TDC_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .CLKDV(4),
    .DATA_IDENTIFIER(4'b0000),
    .FAST_TDC(1),
    .FAST_TRIGGER(1),
    .BROADCAST(0)  // generate for first TDC module the 640MHz sampled trigger signal and share it with other TDC mddules (broadcast)
) i_tdc (
    .CLK320(CLK_320),  // 320 MHz
    .CLK160(CLK_160),  // 160 MHz
    .DV_CLK(CLK_40),  // 40 MHz
    .TDC_IN(TDC_IN[0]),
    .TDC_OUT(),
    .TRIG_IN(TDC_TRIGGER_IN),
    .TRIG_OUT(),

    // input/output trigger signals for broadcasting mode
    .FAST_TRIGGER_IN(16'b0),
    .FAST_TRIGGER_OUT(FAST_TRIGGER_OUT),  // collect 640 MHz sampled trigger signal to pass it to other TDC modules

    .FIFO_READ(TDC_FIFO_READ[0]),
    .FIFO_EMPTY(TDC_FIFO_EMPTY[0]),
    .FIFO_DATA(TDC_FIFO_DATA[0]),

    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .ARM_TDC(TDC_ARM),
    .EXT_EN(TDC_EXT_EN),

    .TIMESTAMP(16'b0)
);

// Additional TDC modules: Use the fast sampled trigger signal from first TDC module.
genvar i;
generate
    for (i = 1; i < 3; i = i + 1) begin: tdc_gen
        tdc_s3 #(
            .BASEADDR(TDC_BASEADDR + 32'h0100*i),
            .HIGHADDR(TDC_HIGHADDR + 32'h0100*i),
            .ABUSWIDTH(ABUSWIDTH),
            .CLKDV(CLKDV),
            .DATA_IDENTIFIER(4'b0000),
            .FAST_TDC(1),
            .FAST_TRIGGER(1),
            .BROADCAST(1)  // generate for first TDC module the 640MHz sampled trigger signal and share it with other TDC mddules (broadcast)
        ) i_tdc (
            .CLK320(CLK_320),  // 320 MHz
            .CLK160(CLK_160),  // 160 MHz
            .DV_CLK(CLK_40),  // 40 MHz
            .TDC_IN(TDC_IN[i]),
            .TDC_OUT(),
            // Use FAST_TRIGGER_IN as input for trigger signal
            .TRIG_IN(1'b0),
            .TRIG_OUT(),

            // input/output trigger signals for broadcasting mode
            .FAST_TRIGGER_IN(FAST_TRIGGER_OUT),  // Use the already existing 640 MHz sampled trigger signal from first module as FAST TRIGGER (broadcast)
            .FAST_TRIGGER_OUT(),

            .FIFO_READ(TDC_FIFO_READ[i]),
            .FIFO_EMPTY(TDC_FIFO_EMPTY[i]),
            .FIFO_DATA(TDC_FIFO_DATA[i]),

            .BUS_CLK(BUS_CLK),
            .BUS_RST(BUS_RST),
            .BUS_ADD(BUS_ADD),
            .BUS_DATA(BUS_DATA[7:0]),
            .BUS_RD(BUS_RD),
            .BUS_WR(BUS_WR),

            .ARM_TDC(TDC_ARM),
            .EXT_EN(TDC_EXT_EN),

            .TIMESTAMP(16'b0)
        );
    end
endgenerate


wire FIFO_READ [2:0], FIFO_EMPTY [2:0], FIFO_FULL [2:0];
wire [31:0] FIFO_DATA [2:0];
genvar k;
generate
    for (k = 0; k < 3; k = k + 1) begin: bram_fifo_gen
        assign FIFO_DATA[k] = TDC_FIFO_DATA[k];
        assign FIFO_EMPTY[k] = TDC_FIFO_EMPTY[k];
        assign TDC_FIFO_READ[k] = FIFO_READ[k];

        bram_fifo #(
            .BASEADDR(FIFO_BASEADDR + 32'h0100*k),
            .HIGHADDR(FIFO_HIGHADDR + 32'h0100*k),
            .BASEADDR_DATA(FIFO_BASEADDR_DATA + 32'h1000_0000*k),
            .HIGHADDR_DATA(FIFO_HIGHADDR_DATA + 32'h1000_0000*k),
            .ABUSWIDTH(ABUSWIDTH)
        ) i_out_fifo (
            .BUS_CLK(BUS_CLK),
            .BUS_RST(BUS_RST),
            .BUS_ADD(BUS_ADD),
            .BUS_DATA(BUS_DATA),
            .BUS_RD(BUS_RD),
            .BUS_WR(BUS_WR),

            .FIFO_READ_NEXT_OUT(FIFO_READ[k]),
            .FIFO_EMPTY_IN(FIFO_EMPTY[k]),
            .FIFO_DATA(FIFO_DATA[k]),

            .FIFO_NOT_EMPTY(),
            .FIFO_FULL(FIFO_FULL[k]),
            .FIFO_NEAR_FULL(),
            .FIFO_READ_ERROR()
        );
    end
endgenerate


initial begin
    $dumpfile("tdc.vcd");
    $dumpvars(0);
end

endmodule
