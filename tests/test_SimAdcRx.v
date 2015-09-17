/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
`timescale 1ps / 1ps

`include "utils/bus_to_ip.v"
`include "utils/cdc_pulse_sync.v"

`include "pulse_gen/pulse_gen.v"
`include "pulse_gen/pulse_gen_core.v"

`include "seq_gen/seq_gen.v"
`include "seq_gen/seq_gen_core.v"
`include "utils/RAMB16_S1_S2_sim.v"
`include "seq_gen/seq_gen_blk_mem_16x8196.v"

`include "spi/spi.v"
`include "spi/spi_core.v"
`include "spi/blk_mem_gen_8_to_1_2k.v"
`include "utils/RAMB16_S1_S9_sim.v"

`include "utils/CG_MOD_pos.v"

`include "gpac_adc_rx/gpac_adc_rx_core.v"
`include "gpac_adc_rx/gpac_adc_rx.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"

`include "utils/generic_fifo.v"
//`include "utils/cdc_pulse_sync_cnt.v"
`include "utils/cdc_syncfifo.v"
`include "utils/pulse_gen_rising.v"

`include "utils/clock_divider.v"

`include "utils/cdc_reset_sync.v"

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
    
    localparam SEQ_GEN_BASEADDR = 32'h1000;                      //0x1000
    localparam SEQ_GEN_HIGHADDR = 32'h3000-1;   //0x300f
    
    localparam ADC_RX_BASEADDR = 32'h3000;
    localparam ADC_RX_HIGHADDR = 32'h5000 - 1;
    
    localparam SPI_ADC_BASEADDR = 32'h5000; 
    localparam SPI_ADC_HIGHADDR = 32'h6000-1;
    
    localparam FIFO_BASEADDR = 32'h8000;
    localparam FIFO_HIGHADDR = 32'h9000-1;
 
    localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
    localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;
 
    localparam ABUSWIDTH = 32;
    assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;
    
    
    wire DIV_CLK;
    
    clock_divider #(
    .DIVISOR(8) 
    ) i_clock_divisor_spi (
        .CLK(BUS_CLK),
        .RESET(1'b0),
        .CE(),
        .CLOCK(DIV_CLK)
    ); 
    
    wire EX_START_PULSE;
    pulse_gen
    #( 
        .BASEADDR(PULSE_BASEADDR), 
        .HIGHADDR(PULSE_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_pulse_gen
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
    
        .PULSE_CLK(DIV_CLK),
        .EXT_START(1'b0),
        .PULSE(EX_START_PULSE)
    );
    
    wire [15:0] SEQ_OUT;
    seq_gen 
    #( 
        .BASEADDR(SEQ_GEN_BASEADDR), 
        .HIGHADDR(SEQ_GEN_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .MEM_BYTES(16*1024), 
        .OUT_BITS(16) 
    ) i_seq_gen
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
    
        .SEQ_EXT_START(EX_START_PULSE),
        .SEQ_CLK(DIV_CLK),
        .SEQ_OUT(SEQ_OUT)
    );
    
    wire SDI;
    
    spi 
    #( 
        .BASEADDR(SPI_ADC_BASEADDR), 
        .HIGHADDR(SPI_ADC_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .MEM_BYTES(2) 
    )  i_spi
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
    
        .SPI_CLK(DIV_CLK),
    
        .SCLK(),
        .SDI(SDI),
        .SDO(SDI),
        .SEN(),
        .SLD()
    );
    
    wire FIFO_READ_ADC;
    wire FIFO_EMPTY_ADC;
    wire [31:0] FIFO_DATA_ADC;
    
    gpac_adc_rx 
    #(
        .BASEADDR(ADC_RX_BASEADDR), 
        .HIGHADDR(ADC_RX_HIGHADDR),
        .ABUSWIDTH(ABUSWIDTH),
        .ADC_ID(0), 
        .HEADER_ID(0) 
    ) i_gpac_adc_rx
    (
        .ADC_ENC(DIV_CLK),
        .ADC_IN(SEQ_OUT[13:0]),

        .ADC_SYNC(EX_START_PULSE),
        .ADC_TRIGGER(1'b0),

        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR), 

        .FIFO_READ(FIFO_READ_ADC),
        .FIFO_EMPTY(FIFO_EMPTY_ADC),
        .FIFO_DATA(FIFO_DATA_ADC),

        .LOST_ERROR()
    ); 
    
    wire FIFO_READ, FIFO_EMPTY;
    wire [31:0] FIFO_DATA;
    assign FIFO_DATA = FIFO_DATA_ADC;
    assign FIFO_EMPTY = FIFO_EMPTY_ADC;
    assign FIFO_READ_ADC = FIFO_READ;
    
    bram_fifo 
    #(
        .BASEADDR(FIFO_BASEADDR),
        .HIGHADDR(FIFO_HIGHADDR),
        .BASEADDR_DATA(FIFO_BASEADDR_DATA),
        .HIGHADDR_DATA(FIFO_HIGHADDR_DATA),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_out_fifo (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
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

    
    initial begin
        $dumpfile("adcrx.vcd");
        $dumpvars(0);
    end 
    
endmodule
