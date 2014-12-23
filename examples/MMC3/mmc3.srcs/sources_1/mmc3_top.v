`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        SILAB , Physics Institute of Bonn University
// Engineer:       Viacheslav Filimonov
// 
// Create Date:    10:40:28 12/16/2013 
// Design Name: 
// Module Name:    KX7_IF_Test_Top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module mmc3_top(
// FX 3 interface
	input wire fx3_pclk_100MHz,
(* IOB = "FORCE" *)  input wire fx3_wr,  // force IOB register
(* IOB = "FORCE" *)	 input wire fx3_cs, // async. signal
(* IOB = "FORCE" *)	 input wire fx3_oe, // async. signal
	input wire fx3_rst,// async. signal from FX3, active high
(* IOB = "FORCE" *)  output wire fx3_ack,// force IOB register
(* IOB = "FORCE" *)	 output wire fx3_rdy,// force IOB register
    output wire reset_fx3,
    inout wire [31:0] fx3_bus, // 32 bit databus

// 200 MHz oscillator
    input  wire  sys_clk_p, 
	input  wire  sys_clk_n,
	 
// 100 Mhz oscillator
    input  wire  Clk100, 

// GPIO	 
    output wire [8:1] led,
    
    output wire [3:0] PWR_EN,
   
(* IOB = "FORCE" *) output wire fx3_rd_finish,
   
    input wire Reset_button2,// async. signal
   
    input wire FLAG1, // was DMA Flag; currently connected to TEST signal from FX3
(* IOB = "FORCE" *) input wire FLAG2, // DMA watermark flag for thread 2 of FX3

// Power supply regulators EN signals
    output wire EN_VD1,
    output wire EN_VD2,
    output wire EN_VA1,
    output wire EN_VA2,
    
// Command sequencer signals
    output wire CMD_CLK_OUT,
(* IOB = "FORCE" *) output wire CMD_DATA,
    
// FE-I4_rx signals
(* IOB = "FORCE" *) input wire DOBOUT
    
);

assign reset_fx3 = 1; // not to reset fx3 while loading fpga

assign EN_VD1 = 1;
assign EN_VD2 = 1;
assign EN_VA1 = 1;
assign EN_VA2 = 1;

wire [31:0] BUS_ADD;
wire [31:0] BUS_DATA;

wire BUS_RD, BUS_WR, BUS_RST, BUS_CLK;
//assign BUS_RST = (BUS_RST | (!LOCKED));

wire BUS_BYTE_ACCESS;
assign BUS_BYTE_ACCESS = (BUS_ADD < 32'h8000_0000) ? 1'b1 : 1'b0;

wire PLL_RST;
assign PLL_RST = ((fx3_rst)|(!LOCKED));

FX3_IF  FX3_IF_inst (
    .fx3_bus(fx3_bus),
    .fx3_wr(fx3_wr),
    .fx3_oe(fx3_oe),
    .fx3_cs(fx3_cs),
    .fx3_clk(fx3_pclk_100MHz),
    .fx3_rdy(fx3_rdy),
    .fx3_ack(fx3_ack),
    .fx3_rd_finish(fx3_rd_finish),
    .fx3_rst(PLL_RST), // PLL is reset first
//    .fx3_rst(fx3_rst), // Comment before synthesis and uncomment previous line

    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .BUS_BYTE_ACCESS(BUS_BYTE_ACCESS),
    
    .FLAG1(FLAG1),
    .FLAG2(FLAG2)
    );

wire clk40mhz_pll, clk320mhz_pll, clk160mhz_pll, clk16mhz_pll;
wire pll_feedback, LOCKED;

PLLE2_BASE #(
    .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
    .CLKFBOUT_MULT(64),       // Multiply value for all CLKOUT, (2-64)
    .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
    .CLKIN1_PERIOD(10.000),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    
    .CLKOUT0_DIVIDE(32),     // Divide amount for CLKOUT0 (1-128)
    .CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
    .CLKOUT0_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
    
    .CLKOUT1_DIVIDE(4),     // Divide amount for CLKOUT0 (1-128)
    .CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
    .CLKOUT1_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
    
    .CLKOUT2_DIVIDE(8),     // Divide amount for CLKOUT0 (1-128)
    .CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
    .CLKOUT2_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
    
    .CLKOUT3_DIVIDE(80),     // Divide amount for CLKOUT0 (1-128)
    .CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.001-0.999).
    .CLKOUT3_PHASE(0.0),      // Phase offset for CLKOUT0 (-360.000-360.000).
    
    .DIVCLK_DIVIDE(5),        // Master division value, (1-56)
    .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
    .STARTUP_WAIT("FALSE")     // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
 )
 PLLE2_BASE_inst (
     // Generated 40 MHz clock 
     .CLKOUT0(clk40mhz_pll),
     .CLKOUT1(clk320mhz_pll),
     .CLKOUT2(clk160mhz_pll),
     .CLKOUT3(clk16mhz_pll),
     .CLKOUT4(),
     .CLKOUT5(),
     
     .CLKFBOUT(pll_feedback),
     
     .LOCKED(LOCKED),     // 1-bit output: LOCK
     
     // Input 100 MHz clock
     .CLKIN1(BUS_CLK),
    
     // Control Ports
     .PWRDWN(0),
     .RST(fx3_rst), // Button is active low
    
     // Feedback
     .CLKFBIN(pll_feedback)
 );
 
 wire clk40mhz, clk320mhz, clk160mhz, clk16mhz;
 
 BUFG BUFG_inst_40 (
 .O(clk40mhz),     // Clock buffer output
 .I(clk40mhz_pll)      // Clock buffer input
 );
 
 BUFG BUFG_inst_320 (
 .O(clk320mhz),     // Clock buffer output
 .I(clk320mhz_pll)      // Clock buffer input
 );
 
 BUFG BUFG_inst_160 (
 .O(clk160mhz),     // Clock buffer output
 .I(clk160mhz_pll)      // Clock buffer input
 );
 
 BUFG BUFG_inst_16 (
 .O(clk16mhz),     // Clock buffer output
 .I(clk16mhz_pll)      // Clock buffer input
 );
 
// -------  MODULE ADREESSES  ------- //
 localparam CMD_BASEADDR = 32'h0000;
 localparam CMD_HIGHADDR = 32'h1000-1;
 
 localparam GPIO1_BASEADDR = 32'h1000;
 localparam GPIO1_HIGHADDR = 32'h1003; 
 
 localparam GPIO2_BASEADDR = 32'h1004;
 localparam GPIO2_HIGHADDR = 32'h1007;
  
 localparam FIFO_BASEADDR = 32'h8100;
 localparam FIFO_HIGHADDR = 32'h8200-1;

 localparam RX4_BASEADDR = 32'h8300;
 localparam RX4_HIGHADDR = 32'h8400-1;
 
 localparam RX3_BASEADDR = 32'h8400;
 localparam RX3_HIGHADDR = 32'h8500-1;
 
 localparam RX2_BASEADDR = 32'h8500;
 localparam RX2_HIGHADDR = 32'h8600-1;
 
 localparam RX1_BASEADDR = 32'h8600;
 localparam RX1_HIGHADDR = 32'h8700-1;
 
 localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
 localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;
 
 localparam ABUSWIDTH = 32;
 
wire CMD_EXT_START_FLAG;
assign CMD_EXT_START_FLAG = 0;


gpio
#(
    .BASEADDR(GPIO1_BASEADDR),
    .HIGHADDR(GPIO1_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .IO_WIDTH(8),
    .IO_DIRECTION(8'hff),
    .IO_TRI(0)
)gpio1(
    .BUS_CLK(BUS_CLK), 
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(led)
);

gpio
#(
    .BASEADDR(GPIO2_BASEADDR),
    .HIGHADDR(GPIO2_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH),
    .IO_WIDTH(8),
    .IO_DIRECTION(8'hff),
    .IO_TRI(0)
)gpio2(
    .BUS_CLK(BUS_CLK), 
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .IO(PWR_EN[3:0])
);

cmd_seq 
#( 
    .BASEADDR(CMD_BASEADDR),
    .HIGHADDR(CMD_HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH)
) icmd (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA[7:0]),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    
    .CMD_CLK_OUT(CMD_CLK_OUT),
    .CMD_CLK_IN(clk40mhz),
    .CMD_EXT_START_FLAG(CMD_EXT_START_FLAG),
    .CMD_EXT_START_ENABLE(),
    .CMD_DATA(CMD_DATA),
    .CMD_READY(),
    .CMD_START_FLAG()
);

parameter DSIZE = 10;
wire FIFO_READ, FIFO_EMPTY;
wire [31:0] FIFO_DATA;
//assign FIFO_READ = 0;

genvar i;
generate
  for (i = 3; i < 4; i = i + 1) begin: rx_gen
    fei4_rx 
    #(
        .BASEADDR(RX1_BASEADDR-32'h0100*i),
        .HIGHADDR(RX1_HIGHADDR-32'h0100*i),
        .DSIZE(DSIZE),
        .DATA_IDENTIFIER(i+1),
        .ABUSWIDTH(ABUSWIDTH)
    ) i_fei4_rx (
        .RX_CLK(clk160mhz),
        .RX_CLK2X(clk320mhz),
        .DATA_CLK(clk16mhz),
        
        .RX_DATA(DOBOUT),
        
        .RX_READY(),
        .RX_8B10B_DECODER_ERR(),
        .RX_FIFO_OVERFLOW_ERR(),
         
        .FIFO_READ(FIFO_READ),
        .FIFO_EMPTY(FIFO_EMPTY),
        .FIFO_DATA(FIFO_DATA),
        
        .RX_FIFO_FULL(),
         
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA[7:0]),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR)
    ); 
  end
endgenerate

wire FIFO_NOT_EMPTY, FIFO_FULL, FIFO_NEAR_FULL, FIFO_READ_ERROR;

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

    .FIFO_NOT_EMPTY(FIFO_NOT_EMPTY),
    .FIFO_FULL(FIFO_FULL),
    .FIFO_NEAR_FULL(FIFO_NEAR_FULL),
    .FIFO_READ_ERROR(FIFO_READ_ERROR)
);

//assign led[5] = FIFO_NOT_EMPTY;
//assign led[6] = FIFO_FULL;
//assign led[7] = FIFO_NEAR_FULL;
//assign led[8] = FIFO_READ_ERROR;

/*always @ (posedge BUS_CLK)
begin
if (BUS_RST)
    begin
       led[5] <= 0;
       led[6] <= 0;
       led[7] <= 0;
       led[8] <= 0;
    end
else
    begin
        if (FIFO_NOT_EMPTY)
            led[5] <= 1;
        else if (FIFO_FULL)
            led[6] <= 1;
        else if (FIFO_NEAR_FULL)
            led[7] <= 1;
        else if (FIFO_READ_ERROR)
            led[8] <= 1;
    end
end*/

/*
gpio 
#( 
    .BASEADDR(GPIO_BASEADDR), 
    .HIGHADDR(GPIO_HIGHADDR),
    .ABUSWIDTH(32),
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
    .IO(led[8:1])
);

*/

/*Register #(
    .REG_SIZE(32), 
    .ADDRESS(1))
Reg1_inst (
    .D(DataIn), 
    .WR(WR), 
    .RD(RD), 
    .Addr(Addr),
    .CLK(CLK_100MHz), 
	  .Q(Reg1),
    .RB(DataOut), 
		.RDYB(RDYB),
		.RD_VALID_N(ACKB),
    .RST(RST)
    );
    
Register #(
    .REG_SIZE(32), 
    .ADDRESS(2))
Reg2_inst (
    .D(DataIn), 
    .WR(WR), 
    .RD(RD), 
    .Addr(Addr),
    .CLK(CLK_100MHz), 
	  .Q(Reg2),
    .RB(DataOut), 
		.RDYB(RDYB),
		.RD_VALID_N(ACKB),
    .RST(RST)
    );		
    
BRAM_Test #(
    .ADDRESS( 32'h10_00_00_00),
    .MEM_SIZE(32'h00_00_40_00))
BRAM_Test_inst (
    .DataIn(DataIn), 
    .WR(WR), 
    .RD(RD), 
    .CLK(CLK_100MHz), 
    .DataOut(DataOut), 
    .Addr(Addr[31:0]),
		.RDYB(RDYB),
		.RD_VALID_N(ACKB),
//	.DMA_RDY(DMA_RDY),
	.RST(RST)
    );    

DDR3_256_8  #(
    .ADDRESS( 32'h20_00_00_00), 
    .MEM_SIZE(32'h10_00_00_00)) 
DDR3_256_8_inst (
    .DataIn(DataIn[31:0]), 
    .WR(WR), 
    .RD(RD), 
    .Addr(Addr[31:0]), 
    .DataOut(DataOut[31:0]), 
    .RDY_N(RDYB), 
    .RD_VALID_N(ACKB), 
    .CLK_OUT(CLK_100MHz), 
    .RST(RST), 
    .Reset_button2(Reset_button2),
    .INIT_COMPLETE(INIT_COMPLETE),
    .ddr3_dq(ddr3_dq), 
    .ddr3_addr(ddr3_addr), 
//    .ddr3_dm(ddr3_dm), 
    .ddr3_dqs_p(ddr3_dqs_p), 
    .ddr3_dqs_n(ddr3_dqs_n), 
    .ddr3_ba(ddr3_ba), 
    .ddr3_ck_p(ddr3_ck_p), 
    .ddr3_ck_n(ddr3_ck_n), 
    .ddr3_ras_n(ddr3_ras_n), 
    .ddr3_cas_n(ddr3_cas_n), 
    .ddr3_we_n(ddr3_we_n), 
    .ddr3_reset_n(ddr3_reset_n), 
    .ddr3_cke(ddr3_cke), 
    .ddr3_odt(ddr3_odt), 
//    .ddr3_cs_n(ddr3_cs_n), 
    .sys_clk_p(sys_clk_p), 
    .sys_clk_n(sys_clk_n),
    .Clk100(Clk100),
    .full_fifo(full_fifo),
//    .DMA_RDY(DMA_RDY),
    .CS_FX3(CS_FX3),
    .FLAG2_reg(FLAG2_reg)
    );	*/	

endmodule