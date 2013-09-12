/**
 * ------------------------------------------------------------
 * Copyright (c) SILAB , Physics Institute of Bonn University 
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $: 
 *  $Date::                      $:
 */
 
 
`timescale 1ps / 1ps

`default_nettype none

module example (
    
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
    
    inout FPGA_BUTTON,

    inout SDA,
    inout SCL

    );   
        
    assign SDA = 1'bz;
    assign SCL = 1'bz;
    
    assign DEBUG_D = 16'ha5a5;
    
    wire BUS_CLK, BUS_CLK270;
    wire SPI_CLK;
    wire ADC_ENC;
    wire CLK_LOCKED;
    wire BUS_RST;
    
    reset_gen i_reset_gen(.CLK(BUS_CLK), .RST(BUS_RST));
    
    clk_gen i_clkgen(
        .CLKIN(FCLK_IN),
        .CLKINBUF(BUS_CLK),
        .CLKINBUF270(BUS_CLK270),
        .LOCKED(CLK_LOCKED)
    );
    

    //MODULE ADREESSES
    localparam GPIO_BASEADDR = 16'h0000;
    localparam GPIO_HIGHADDR = 16'h000f;
    
    wire [15:0] BUS_ADD;
    assign BUS_ADD = ADD - 16'h4000;
    wire BUS_RD, BUS_WR;
    assign BUS_RD = ~RD_B;
    assign BUS_WR = ~WR_B;

    // MODULES //
    wire [1:0] GPIO_NOT_USED;
    gpio8 
    #( 
        .BASEADDR(GPIO_BASEADDR), 
        .HIGHADDR(GPIO_HIGHADDR)
    ) i_gpio8
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO({FPGA_BUTTON, GPIO_NOT_USED, LED5, LED4, LED3, LED2, LED1})
    );

endmodule
