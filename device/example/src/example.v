`timescale 1ps / 1ps

//`default_nettype none

module example (
    
    input wire FCLK_IN, 
    
    //full speed 
    inout wire [7:0] DATA,
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

    reset_gen ireset_gen(.CLK(BUS_CLK), .RST(BUS_RST));

    clk_gen iclkgen(
        .CLKIN(FCLK_IN),
        .CLKINBUF(BUS_CLK),
        .CLKINBUF270(BUS_CLK270),
        .LOCKED(CLK_160_LOCKED)
    );
    
    wire [7:0] BUS_DATA_IN;
    assign BUS_DATA_IN = DATA;
    
    ///
    reg [7:0] DATA_OUT;

    reg [15:0] GPIO_ADD;
    wire [7:0] GPIO_BUS_DATA_OUT;
    reg GPIO_RD, GPIO_WR;

    wire [15:0] ADD_REAL;
    assign ADD_REAL = ADD - 16'h4000;
    
    always@(*) begin
        DATA_OUT = 0;
                
        GPIO_RD = 0;
        GPIO_WR = 0;
        GPIO_ADD = 0;


    if( ADD_REAL < 16'h0010 ) begin
            GPIO_RD = ~RD_B;
            GPIO_WR = ~WR_B;
            GPIO_ADD = ADD_REAL-16'h0000;
            DATA_OUT = GPIO_BUS_DATA_OUT;
        end

    end

    assign DATA = ~RD_B ? DATA_OUT : 8'bzzzz_zzzz;

    // MODULES // 

    wire [1:0] GPIO_NOT_USED;
    
    gpio8 igpio8
    (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),                  
    .BUS_ADD(GPIO_ADD),                    
    .BUS_DATA_IN(BUS_DATA_IN),                    
    .BUS_RD(GPIO_RD),                    
    .BUS_WR(GPIO_WR),                    
    .BUS_DATA_OUT(GPIO_BUS_DATA_OUT), 
    
    .IO({FPGA_BUTTON, GPIO_NOT_USED, LED5, LED4, LED3, LED2, LED1})
    );
    
    
endmodule
