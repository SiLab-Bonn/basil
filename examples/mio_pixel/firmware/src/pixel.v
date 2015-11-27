/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
`timescale 1ps / 1ps
//`default_nettype none

module pixel (

    input wire FCLK_IN, 

    //full speed 
    inout wire [7:0] BUS_DATA,
    input wire [15:0] ADD,
    input wire RD_B,
    input wire WR_B,

    //high speed
    inout wire [7:0] FD,
    input wire FREAD,
    input wire FSTROBE,
    input wire FMODE,

    //debug
    output wire [15:0] DEBUG_D,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5,

    // trigger
    input wire [2:0] LEMO_RX,
    output wire [2:0] LEMO_TX,
    input wire RJ45_RESET,
    input wire RJ45_TRIGGER,
    
    inout SDA,
    inout SCL,

    //SRAM
    output wire [19:0] SRAM_A,
    inout wire [15:0] SRAM_IO,
    output wire SRAM_BHE_B,
    output wire SRAM_BLE_B,
    output wire SRAM_CE1_B,
    output wire SRAM_OE_B,
    output wire SRAM_WE_B,

    //SR CONTOL
    output SR_IN,
    output GLOBAL_SR_CLK,
    output GLOBAL_CTR_LD,
    output GLOBAL_DAC_LD,
    output GLOBAL_SR_EN,
    output PIXEL_SR_EN,

    output PIXEL_SR_CLK,
    input  PIXEL_SR_OUT,

    input  HIT_OR,
    output INJECT,
 
    output EN_VA1,
    output EN_VA2,
    output EN_VD2,
    output EN_VD1
);   

    assign SDA = 1'bz;
    assign SCL = 1'bz;

    assign LEMO_TX[0] = INJECT;
    assign LEMO_TX[1] = 1'b0;
    assign LEMO_TX[2] = 1'b0;
    
    (* KEEP = "{TRUE}" *) 
    wire CLK320;
    (* KEEP = "{TRUE}" *) 
    wire CLK160;
    (* KEEP = "{TRUE}" *) 
    wire BUS_CLK;
    (* KEEP = "{TRUE}" *) 
    wire SPI_CLK;
    (* KEEP = "{TRUE}" *) 
    wire TDC_WCLK; 
    
    wire CLK_LOCKED;
    wire BUS_RST;

    reset_gen i_reset_gen(.CLK(BUS_CLK), .RST(BUS_RST));

    clk_gen i_clkgen(
        .CLKIN(FCLK_IN),
        .BUS_CLK(BUS_CLK),
        .U2_CLK5(),
        .U2_CLK80(TDC_WCLK),
        .U2_CLK160(CLK160),
        .U2_CLK320(CLK320),
        .SPI_CLK(SPI_CLK),
        .LOCKED(CLK_LOCKED)
    ); 

    // -------  MODULE ADREESSES  ------- //
    localparam GPIO_BASEADDR = 16'h0000;
    localparam GPIO_HIGHADDR = 16'h000f;

    localparam FIFO_BASEADDR = 16'h0020;                    // 0x0020
    localparam FIFO_HIGHADDR = FIFO_BASEADDR + 15;          // 0x002f
    
    localparam FAST_SR_AQ_BASEADDR = 16'h0100;                    
    localparam FAST_SR_AQ_HIGHADDR = FAST_SR_AQ_BASEADDR + 15;
    
    localparam TDC_BASEADDR = 16'h0200;                    
    localparam TDC_HIGHADDR = TDC_BASEADDR + 15; 

    localparam SEQ_GEN_BASEADDR = 16'h1000;                      //0x1000
    localparam SEQ_GEN_HIGHADDR = SEQ_GEN_BASEADDR + 16 + 16'h1fff;   //0x300f

    
    // -------  BUS SYGNALING  ------- //
    wire [15:0] BUS_ADD;
    wire BUS_RD, BUS_WR;
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

    // -------  USER MODULES  ------- //
    wire ARB_READY_OUT, ARB_WRITE_OUT;
    wire [31:0] ARB_DATA_OUT;
    
    wire TLU_FIFO_READ;
    wire TLU_FIFO_EMPTY;
    wire [31:0] TLU_FIFO_DATA;
    wire TLU_FIFO_PEEMPT_REQ;
    
    wire TDC_FIFO_READ;
    wire TDC_FIFO_EMPTY;
    wire [31:0] TDC_FIFO_DATA;
    
    wire [31:0] FIFO_DATA_SPI_RX;
    wire FIFO_EMPTY_SPI_RX;
    wire FIFO_READ_SPI_RX;
    
    rrp_arbiter 
    #( 
        .WIDTH(2)
    ) i_rrp_arbiter
    (
        .RST(BUS_RST),
        .CLK(BUS_CLK),
    
        .WRITE_REQ({~FIFO_EMPTY_SPI_RX, ~TDC_FIFO_EMPTY}),
        .HOLD_REQ({2'b0}),
        .DATA_IN({FIFO_DATA_SPI_RX, TDC_FIFO_DATA}),
        .READ_GRANT({FIFO_READ_SPI_RX, TDC_FIFO_READ}),

        .READY_OUT(ARB_READY_OUT),
        .WRITE_OUT(ARB_WRITE_OUT),
        .DATA_OUT(ARB_DATA_OUT)
    );
    
    
    wire USB_READ;
    assign USB_READ = FREAD && FSTROBE;
    wire FIFO_NEAR_FULL;
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
        .USB_DATA(FD),
    
        .FIFO_READ_NEXT_OUT(ARB_READY_OUT),
        .FIFO_EMPTY_IN(!ARB_WRITE_OUT),
        .FIFO_DATA(ARB_DATA_OUT),
    
        .FIFO_NOT_EMPTY(),
        .FIFO_READ_ERROR(),
        .FIFO_FULL(),
        .FIFO_NEAR_FULL(FIFO_NEAR_FULL)
    ); 
    
    assign LED1 = FIFO_NEAR_FULL;
    
    
    wire [7:0] SEQ_OUT;
    seq_gen 
    #( 
        .BASEADDR(SEQ_GEN_BASEADDR), 
        .HIGHADDR(SEQ_GEN_HIGHADDR),
        .MEM_BYTES(8*1024), 
        .OUT_BITS(8) 
    ) i_seq_gen
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
    
        .SEQ_CLK(SPI_CLK),
        .SEQ_OUT(SEQ_OUT)
    
    );
    
    //wire GLOBAL_SR_EN, PIXEL_SR_EN;
    
    assign SR_IN                = SEQ_OUT[0];
    assign GLOBAL_SR_EN         = SEQ_OUT[1];   
    assign GLOBAL_CTR_LD        = SEQ_OUT[2];   
    assign GLOBAL_DAC_LD        = SEQ_OUT[3];     
    assign PIXEL_SR_EN          = SEQ_OUT[4];
    assign INJECT               = SEQ_OUT[5];
    
    assign DEBUG_D = {SEQ_OUT,SEQ_OUT};


    ODDR GLOBAL_SR_GC (
        .CE(GLOBAL_SR_EN), 
        .C(~SPI_CLK),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0),
        .Q(GLOBAL_SR_CLK)
    );

    ODDR PIXEL_SR_GC (
        .CE(PIXEL_SR_EN), 
        .C(~SPI_CLK),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0),
        .Q(PIXEL_SR_CLK)
    );
    
    fast_spi_rx 
    #(         
        .BASEADDR(FAST_SR_AQ_BASEADDR), 
        .HIGHADDR(FAST_SR_AQ_HIGHADDR)
    ) i_pixel_sr_fast_rx
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        
        .SCLK(~SPI_CLK),
        .SDI(PIXEL_SR_OUT),
        .SEN(PIXEL_SR_EN),
    
        .FIFO_READ(FIFO_READ_SPI_RX),
        .FIFO_EMPTY(FIFO_EMPTY_SPI_RX),
        .FIFO_DATA(FIFO_DATA_SPI_RX)

    ); 
    
    
    tdc_s3 #(
        .BASEADDR(TDC_BASEADDR),
        .HIGHADDR(TDC_HIGHADDR),
        .CLKDV(2),
        .DATA_IDENTIFIER(4'b0100), 
        .FAST_TDC(1),
        .FAST_TRIGGER(0)
    ) i_tdc (
        .CLK320(CLK320),
        .CLK160(CLK160),
        .DV_CLK(TDC_WCLK),
        .TDC_IN(HIT_OR),
        .TDC_OUT(),
        .TRIG_IN(LEMO_RX[1]),
        .TRIG_OUT(),

        .FIFO_READ(TDC_FIFO_READ),
        .FIFO_EMPTY(TDC_FIFO_EMPTY),
        .FIFO_DATA(TDC_FIFO_DATA),

        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

        .ARM_TDC(1'b0), // arm TDC by sending commands
        .EXT_EN(1'b0),
        
        .TIMESTAMP(16'b0)
    );
    
    gpio 
    #( 
        .BASEADDR(GPIO_BASEADDR), 
        .HIGHADDR(GPIO_HIGHADDR),
        .IO_WIDTH(8),
        .IO_DIRECTION(8'hff)
    ) i_gpio
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO({LED5, LED4, LED3, LED2, EN_VD1, EN_VD2, EN_VA2, EN_VA1})
    );
     
endmodule
