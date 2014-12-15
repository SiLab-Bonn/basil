

module top (
    input wire USER_RESET,
    input wire USER_CLOCK,
    
    input wire ETH_COL,
    input wire ETH_CRS,
    output wire ETH_MDC,
    inout wire ETH_MDIO,
    output wire ETH_RESET_n,
    input wire ETH_RX_CLK,
    input wire [3:0] ETH_RX_D,
    input wire ETH_RX_DV,
    output wire ETH_RX_ER,
    output wire ETH_TX_CLK,
    output wire [3:0] ETH_TX_D,
    output wire ETH_TX_EN,
    
    output [3:0] GPIO_LED,
    input [3:0] GPIO_DIP
);


   PLL_BASE #(
      .BANDWIDTH("OPTIMIZED"),             // "HIGH", "LOW" or "OPTIMIZED" 
      .CLKFBOUT_MULT(20),                   // Multiply value for all CLKOUT clock outputs (1-64)
      .CLKFBOUT_PHASE(0.0),                // Phase offset in degrees of the clock feedback output (0.0-360.0).
      .CLKIN_PERIOD(25.0),                  // Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                           // MHz).
      // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      .CLKOUT0_DIVIDE(20), //40
      .CLKOUT1_DIVIDE(32), //25
      .CLKOUT2_DIVIDE(80), //10
      .CLKOUT3_DIVIDE(10), 
      .CLKOUT4_DIVIDE(5), 
      .CLKOUT5_DIVIDE(20),
      // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .CLK_FEEDBACK("CLKFBOUT"),           // Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      .COMPENSATION("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL" 
      .DIVCLK_DIVIDE(1),                   // Division value for all output clocks (1-52)
      .REF_JITTER(0.1),                    // Reference Clock Jitter in UI (0.000-0.999).
      .RESET_ON_LOSS_OF_LOCK("FALSE")      // Must be set to FALSE
   )
   PLL_BASE_inst (
      .CLKFBOUT(CLKFBOUT), // 1-bit output: PLL_BASE feedback output
      // CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      .CLKOUT0(CLKOUT0),
      .CLKOUT1(CLKOUT1),
      .CLKOUT2(CLKOUT2),
      .CLKOUT3(),
      .CLKOUT4(),
      .CLKOUT5(),
      .LOCKED(LOCKED),     // 1-bit output: PLL_BASE lock status output
      .CLKFBIN(CLKFBIN),   // 1-bit input: Feedback clock input
      .CLKIN(USER_CLOCK),       // 1-bit input: Clock input
      .RST(USER_RESET)            // 1-bit input: Reset input
   );
   
    assign RST = USER_RESET | !LOCKED;
    assign CLKFBIN = CLKFBOUT;//BUFG BUFG_FB (  .O(CLKFBIN),  .I(CLKFBOUT) );
    BUFG BUFG_BUS (  .O(BUS_CLK),  .I(CLKOUT0) );
    BUFG BUFG_ETH (  .O(ETH_CLK),  .I(CLKOUT1) );
    BUFG BUFG_ETH_RX_CLK (  .O(ETH_RX_CLK_BUFG),  .I(ETH_RX_CLK) );
    BUFG BUFG_SPI(  .O(SPI_CLK),  .I(CLKOUT2) );

    wire EEPROM_CS, EEPROM_SK, EEPROM_DI;
    wire TCP_CLOSE_REQ;
    wire RBCP_ACT, RBCP_WE, RBCP_RE;
    wire [7:0] RBCP_WD, RBCP_RD;
    wire [31:0] RBCP_ADDR;
    wire TCP_RX_WR;
    wire [7:0] TCP_RX_DATA;
    wire RBCP_ACK;
     
    wire   mdio_gem_i;
    wire   mdio_gem_o;
    wire   mdio_gem_t;
    
    wire [3:0] ETH_TX_D_NO;
    WRAP_SiTCP_GMII_XC6S_16K #(.TIM_PERIOD(40))sitcp(
      .CLK(BUS_CLK)                    ,    // in    : System Clock >129MHz
      .RST(RST)                    ,    // in    : System reset
    // Configuration parameters
      .FORCE_DEFAULTn(1'b0)        ,    // in    : Load default parameters
      .EXT_IP_ADDR(32'hc0a80a10)            ,    // in    : IP address[31:0] //192.168.10.16
      .EXT_TCP_PORT(16'd24)        ,    // in    : TCP port #[15:0]
      .EXT_RBCP_PORT(16'd4660)        ,    // in    : RBCP port #[15:0]
      .PHY_ADDR(5'd3)            ,    // in    : PHY-device MIF address[4:0]
    // EEPROM
      .EEPROM_CS()            ,    // out    : Chip select
      .EEPROM_SK()            ,    // out    : Serial data clock
      .EEPROM_DI()            ,    // out    : Serial write data
      .EEPROM_DO(1'b0)            ,    // in    : Serial read data
      // user data, intialial values are stored in the EEPROM, 0xFFFF_FC3C-3F
      .USR_REG_X3C()            ,    // out    : Stored at 0xFFFF_FF3C
      .USR_REG_X3D()            ,    // out    : Stored at 0xFFFF_FF3D
      .USR_REG_X3E()            ,    // out    : Stored at 0xFFFF_FF3E
      .USR_REG_X3F()            ,    // out    : Stored at 0xFFFF_FF3F
    // MII interface
      .GMII_RSTn(ETH_RESET_n)            ,    // out    : PHY reset
      .GMII_1000M(1'b0)            ,    // in    : GMII mode (0:MII, 1:GMII)
      // TX 
      .GMII_TX_CLK(ETH_CLK)            ,    // in    : Tx clock
      .GMII_TX_EN(ETH_TX_EN)            ,    // out    : Tx enable
      .GMII_TXD({ETH_TX_D_NO,ETH_TX_D})            ,    // out    : Tx data[7:0]
      .GMII_TX_ER(ETH_RX_ER)            ,    // out    : TX error
      // RX
      .GMII_RX_CLK(ETH_RX_CLK_BUFG)           ,    // in    : Rx clock
      .GMII_RX_DV(ETH_RX_DV)            ,    // in    : Rx data valid
      .GMII_RXD({4'b0, ETH_RX_D})            ,    // in    : Rx data[7:0]
      .GMII_RX_ER(ETH_RX_ER)            ,    // in    : Rx error
      .GMII_CRS(ETH_CRS)            ,    // in    : Carrier sense
      .GMII_COL(ETH_COL)            ,    // in    : Collision detected
      // Management IF
      .GMII_MDC(ETH_MDC)            ,    // out    : Clock for MDIO
      .GMII_MDIO_IN(mdio_gem_i)        ,    // in    : Data
      .GMII_MDIO_OUT(mdio_gem_o)        ,    // out    : Data
      .GMII_MDIO_OE(mdio_gem_t)        ,    // out    : MDIO output enable
    // User I/F
      .SiTCP_RST(SiTCP_RST)            ,    // out    : Reset for SiTCP and related circuits
      // TCP connection control
      .TCP_OPEN_REQ(1'b0)        ,    // in    : Reserved input, shoud be 0
      .TCP_OPEN_ACK()        ,    // out    : Acknowledge for open (=Socket busy)
      .TCP_ERROR()            ,    // out    : TCP error, its active period is equal to MSL
      .TCP_CLOSE_REQ(TCP_CLOSE_REQ)        ,    // out    : Connection close request
      .TCP_CLOSE_ACK(TCP_CLOSE_REQ)        ,    // in    : Acknowledge for closing
      // FIFO I/F
      .TCP_RX_WC(1'b1)            ,    // in    : Rx FIFO write count[15:0] (Unused bits should be set 1)
      .TCP_RX_WR(TCP_RX_WR)            ,    // out    : Write enable
      .TCP_RX_DATA(TCP_RX_DATA)            ,    // out    : Write data[7:0]
      .TCP_TX_FULL()            ,    // out    : Almost full flag
      .TCP_TX_WR(1'b0)            ,    // in    : Write enable
      .TCP_TX_DATA(8'b0)            ,    // in    : Write data[7:0]
      // RBCP
      .RBCP_ACT(RBCP_ACT)            ,    // out    : RBCP active
      .RBCP_ADDR(RBCP_ADDR)            ,    // out    : Address[31:0]
      .RBCP_WD(RBCP_WD)                ,    // out    : Data[7:0]
      .RBCP_WE(RBCP_WE)                ,    // out    : Write enable
      .RBCP_RE(RBCP_RE)                ,    // out    : Read enable
      .RBCP_ACK(RBCP_ACK)            ,    // in    : Access acknowledge
      .RBCP_RD(RBCP_RD)                    // in    : Read data[7:0]
    );

   ODDR2 #(
      .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
      .INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
   ) ODDR2_ETH_TX_CLK (
      .Q(ETH_TX_CLK),   // 1-bit DDR output data
      .C0(ETH_CLK),   // 1-bit clock input
      .C1(~ETH_CLK),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D0(1'b0), // 1-bit data input (associated with C0)
      .D1(1'b1), // 1-bit data input (associated with C1)
      .R(1'b0),   // 1-bit reset input
      .S(1'b0)    // 1-bit set input
   );

    IOBUF i_iobuf_mdio(
      .O(mdio_gem_i),
      .IO(ETH_MDIO),
      .I(mdio_gem_o),
      .T(mdio_gem_t));

    wire BUS_WR, BUS_RD;
    wire [31:0] BUS_ADD;
    wire [7:0] BUS_DATA;
    
    rbcp_to_bus irbcp_to_bus(
    
    .BUS_RST(BUS_RST),
    .BUS_CLK(BUS_CLK),
    
    .RBCP_ACT(RBCP_ACT),
    .RBCP_ADDR(RBCP_ADDR),
    .RBCP_WD(RBCP_WD),
    .RBCP_WE(RBCP_WE),
    .RBCP_RE(RBCP_RE),
    .RBCP_ACK(RBCP_ACK),
    .RBCP_RD(RBCP_RD),
    
    .BUS_WR(BUS_WR),
    .BUS_RD(BUS_RD),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA)
  );
    
    //MODULE ADREESSES
    localparam GPIO_BASEADDR = 32'h0000_0000;
    localparam GPIO_HIGHADDR = 32'h0000_000f;
    
    localparam FIFO_BASEADDR = 32'h0020;                    // 0x0020
    localparam FIFO_HIGHADDR = FIFO_BASEADDR + 15;          // 0x002f
    
    localparam FAST_SR_AQ_BASEADDR = 32'h0100;                    
    localparam FAST_SR_AQ_HIGHADDR = FAST_SR_AQ_BASEADDR + 15;
    
    localparam TDC_BASEADDR = 32'h0200;                    
    localparam TDC_HIGHADDR = TDC_BASEADDR + 15; 

    localparam SEQ_GEN_BASEADDR = 32'h1000;                      //0x1000
    localparam SEQ_GEN_HIGHADDR = SEQ_GEN_BASEADDR + 16 + 32'h1fff;   //0x300f
    
     
    // MODULES //
    gpio 
    #( 
        .BASEADDR(GPIO_BASEADDR), 
        .HIGHADDR(GPIO_HIGHADDR),
        .ABUSWIDTH(32),
        .IO_WIDTH(8),
        .IO_DIRECTION(8'h0f)
    ) i_gpio
    (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO({GPIO_DIP, GPIO_LED})
    );
     
    wire [7:0] SEQ_OUT;
    seq_gen 
    #( 
        .BASEADDR(SEQ_GEN_BASEADDR), 
        .HIGHADDR(SEQ_GEN_HIGHADDR),
        .ABUSWIDTH(32),
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
    
    assign SR_IN                = SEQ_OUT[0];
    assign GLOBAL_SR_EN         = SEQ_OUT[1];   
    assign GLOBAL_CTR_LD        = SEQ_OUT[2];   
    assign GLOBAL_DAC_LD        = SEQ_OUT[3];     
    assign PIXEL_SR_EN          = SEQ_OUT[4];
    assign INJECT               = SEQ_OUT[5];
 
    OFDDRRSE GLOBAL_SR_GC (
        .CE(GLOBAL_SR_EN), 
        .C0(~SPI_CLK),
        .C1(SPI_CLK),
        .D0(1'b1),
        .D1(1'b0),
        .R(1'b0),
        .S(1'b0),
        .Q(GLOBAL_SR_CLK)
    );

    OFDDRRSE PIXEL_SR_GC (
        .CE(PIXEL_SR_EN), 
        .C0(~SPI_CLK),
        .C1(SPI_CLK),
        .D0(1'b1),
        .D1(1'b0),
        .R(1'b0),
        .S(1'b0),
        .Q(PIXEL_SR_CLK)
    );
 
  
endmodule
