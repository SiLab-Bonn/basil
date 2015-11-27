/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------

 */

module tb (
    
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
    wire INJECT;

    // Instantiate the Unit Under Test (UUT)
    pixel uut (
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
        .PIXEL_SR_OUT(SR_IN), // loop SR_IN to SR_OUT for testing

        .HIT_OR(INJECT), // loop INJECT to HIT_OR for testing
        .INJECT(INJECT)

    );
   
    /// SRAM Model
    reg [15:0] sram [1048576-1:0];
    always@(negedge SRAM_WE_B)
        sram[SRAM_A] <= SRAM_IO;
    
    assign SRAM_IO = !SRAM_OE_B ? sram[SRAM_A] : 16'hzzzz;
    
    initial begin
        $dumpfile("pixel.vcd");
        $dumpvars(0);
    end

endmodule

