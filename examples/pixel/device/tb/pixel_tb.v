/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $:
 *  $Date::                      $:
 */
 
//`timescale 1ns / 1ps

`define GPIO_BASE_ADD 16'h0000

`define FIFO_BASE_ADD 16'h0020
`define FIFO_BASE_SIZE `FIFO_BASE_ADD+1

`define SEQ_GEN_BASEADDR 16'h1000

`define FAST_SR_AQ 16'h0100
`define FAST_SR_AQ_EN `FAST_SR_AQ + 2

module pixel_tb;

    // Inputs
    reg FCLK_IN;
    wire FE_RX;
    
    // Outputs
    wire [15:0] DEBUG_D;
    wire LED1;
    wire LED2;
    wire LED3;
    wire LED4;
    wire LED5;
    wire [19:0] SRAM_A;
    wire SRAM_BHE_B;
    wire SRAM_BLE_B;
    wire SRAM_CE1_B;
    wire SRAM_OE_B;
    wire SRAM_WE_B;

    // Bidirs
    wire [15:0] SRAM_IO;

    wire SR_IN;
    wire GLOBAL_SR_CLK;
    wire GLOBAL_CTR_LD;
    wire GLOBAL_DAC_LD;

    wire PIXEL_SR_CLK;
    wire PIXEL_SR_OUT;

    wire HIT_OR;
    wire INJECT;
    
    SiLibUSB sidev(FCLK_IN);

    // Instantiate the Unit Under Test (UUT)
    pixel uut (
        .FCLK_IN(FCLK_IN), 
        
        .BUS_DATA(sidev.DATA), 
        .ADD(sidev.ADD), 
        .RD_B(sidev.RD_B), 
        .WR_B(sidev.WR_B), 
        .FD(sidev.FD), 
        .FREAD(sidev.FREAD), 
        .FSTROBE(sidev.FSTROBE), 
        .FMODE(sidev.FMODE),
        
        .DEBUG_D(DEBUG_D), 
        .LED1(LED1), 
        .LED2(LED2), 
        .LED3(LED3), 
        .LED4(LED4), 
        .LED5(LED5), 
        
        .SRAM_A(SRAM_A), 
        .SRAM_IO(SRAM_IO), 
        .SRAM_BHE_B(SRAM_BHE_B), 
        .SRAM_BLE_B(SRAM_BLE_B), 
        .SRAM_CE1_B(SRAM_CE1_B), 
        .SRAM_OE_B(SRAM_OE_B), 
        .SRAM_WE_B(SRAM_WE_B),
        
        .SR_IN(SR_IN),
        .GLOBAL_SR_CLK(GLOBAL_SR_CLK),
        .GLOBAL_CTR_LD(GLOBAL_CTR_LD),
        .GLOBAL_DAC_LD(GLOBAL_DAC_LD),

        .PIXEL_SR_CLK(PIXEL_SR_CLK),
        .PIXEL_SR_OUT(PIXEL_SR_OUT),

        .HIT_OR(HIT_OR),
        .INJECT(INJECT)
        
        
    );
   
    /// SRAM
    reg [15:0] sram [1048576-1:0];
    always@(negedge SRAM_WE_B)
        sram[SRAM_A] <= SRAM_IO;
    
    assign SRAM_IO = !SRAM_OE_B ? sram[SRAM_A] : 16'hzzzz;
    
    initial begin
            FCLK_IN = 1;
            forever
                #(20.833/2) FCLK_IN =!FCLK_IN;
    end
    
    initial begin
        $dumpfile("uut.vcd");
        $dumpvars(-1, uut);
        //$monitor("%b", uut);
    end

    reg [15:0] data ;
    reg [23:0] sram_fifo_size;
    reg [23:0] bytes_to_read;
    reg [31:0] sram_data;
    
    initial begin
        repeat (300) @(posedge FCLK_IN);
        
        sidev.WriteExternal( `GPIO_BASE_ADD + 2,  8'h01); 
        sidev.WriteExternal( `GPIO_BASE_ADD + 2,  8'h02);
        sidev.WriteExternal( `GPIO_BASE_ADD + 2,  8'h03);
        
        sidev.WriteExternal( `SEQ_GEN_BASEADDR + 16,  8'hff); 
        sidev.WriteExternal( `SEQ_GEN_BASEADDR + 1,  8'h00); 
         
        repeat (1000) @(posedge FCLK_IN);
        
        $finish;
        
        /*
        #400us
        sram_fifo_size = 0;
        sidev.ReadExternal( `FIFO_BASE_SIZE,  sram_fifo_size[23:16]); 
        sidev.ReadExternal( `FIFO_BASE_SIZE+1,  sram_fifo_size[15:8]);
        sidev.ReadExternal( `FIFO_BASE_SIZE+2,  sram_fifo_size[7:0]);
        $display (" SRAM FIFO Size %d",  sram_fifo_size ); 
        bytes_to_read = sram_fifo_size *2; // sram data bus is 16bit = 2 bytes 
        
        //Read with fast usb always 4 bytes
        for(int i=0;i<bytes_to_read/4;i++) begin
            sidev.FastBlockRead(sram_data[31:24]);
            sidev.FastBlockRead(sram_data[23:16]); 
            sidev.FastBlockRead(sram_data[15:8]);
            sidev.FastBlockRead(sram_data[7:0]);
            $display (" SRAM DATA [%d]: %h",  i, sram_data ); 
        end
        */
    end
    
endmodule

