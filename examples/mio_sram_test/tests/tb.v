
`timescale 1ps / 1ps
`default_nettype none

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
    
    
    //SRAM
    wire [19:0] SRAM_A;
    wire [15:0] SRAM_IO;
    wire SRAM_BHE_B;
    wire SRAM_BLE_B;
    wire SRAM_CE1_B;
    wire SRAM_OE_B;
    wire SRAM_WE_B;
    
    wire [4:0] LED;
    wire SDA;
    wire SCL;
    
    sram_test dut(.FCLK_IN(FCLK_IN), 
                  .BUS_DATA(BUS_DATA), .ADD(ADD), .RD_B(RD_B), .WR_B(WR_B),
                  .FD(FD), .FREAD(FREAD), .FSTROBE(FSTROBE), .FMODE(FMODE),
                  .SRAM_A(SRAM_A), .SRAM_IO(SRAM_IO), .SRAM_BHE_B(SRAM_BHE_B), .SRAM_BLE_B(SRAM_BLE_B), .SRAM_CE1_B(SRAM_CE1_B), .SRAM_OE_B(SRAM_OE_B), .SRAM_WE_B(SRAM_WE_B), 
                  .LED(LED), .SDA(SDA), .SCL(SCL) );
  
    defparam dut.i_out_fifo.DEPTH = 21'h100;
    
    /// SRAM
    reg [15:0] sram [1048576-1:0];
    always@(negedge SRAM_WE_B)
        sram[SRAM_A] <= SRAM_IO;
    
    assign SRAM_IO = !SRAM_OE_B ? sram[SRAM_A] : 16'hzzzz;

    initial begin
        $dumpfile("sram_test.vcd");
        $dumpvars(0);
    end

endmodule
