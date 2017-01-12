
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
    
    inout wire FPGA_BUTTON,

    inout wire SDA,
    inout wire SCL

    );   
        
    wire [15:0] BUS_ADD;
    wire BUS_CLK, BUS_RD, BUS_WR, BUS_RST;

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
    localparam GPIO_BASEADDR = 16'h0000;
    localparam GPIO_HIGHADDR = 16'h000f;
    
    // USER MODULES //
    wire [1:0] GPIO_NOT_USED;
    gpio
    #( 
        .BASEADDR(GPIO_BASEADDR), 
        .HIGHADDR(GPIO_HIGHADDR),
        
        .IO_WIDTH(8),
        .IO_DIRECTION(8'h1f) // 3 MSBs are input the rest output
    ) i_gpio
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO({FPGA_BUTTON, GPIO_NOT_USED, LED5, LED4, LED3, LED2, LED1})
    );
    
    assign GPIO_NOT_USED = {LED2, LED1};
   
    //For simulation
    initial begin
        $dumpfile("mio_example.vcd");
        $dumpvars(0);
    end
    
    assign SDA = 1'bz;
    assign SCL = 1'bz;
    assign DEBUG_D = 16'ha5a5;

    `ifdef COCOTB_SIM
        assign FPGA_BUTTON = 0;
    `endif

endmodule
