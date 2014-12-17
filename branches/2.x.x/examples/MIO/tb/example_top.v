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

module example_top (
    
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
    input wire FMODE

    );   
        
	example iexample(
    
		.FCLK_IN(FCLK_IN), 
		
		.BUS_DATA(BUS_DATA),
		.ADD(ADD),
		.RD_B(RD_B),
		.WR_B(WR_B),
		
		.FD(FD),
		.FREAD(FREAD),
		.FSTROBE(FSTROBE),
		.FMODE(FMODE),

		.DEBUG_D(),		
		.LED1(),
		.LED2(),
		.LED3(),
		.LED4(),
		.LED5(),
		
		.FPGA_BUTTON(),

		.SDA(),
		.SCL()

    );    
	
endmodule
