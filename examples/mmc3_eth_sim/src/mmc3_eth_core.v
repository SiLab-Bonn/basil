`timescale 1ns / 1ps

/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */


module mmc3_eth_core(

    input wire RESET_N,
    
    // clocks from PLL clock buffers
    input wire BUS_CLK, CLK125TX, CLK125TX90, CLK125RX,
    input wire PLL_LOCKED,


    // User I/F
	input wire SiTCP_RST           ,   // Reset for SiTCP and related circuits
	// TCP connection control
	output wire TCP_OPEN_REQ       ,   // Reserved input, shoud be 0
    input wire TCP_OPEN_ACK		   ,   // Acknowledge for open (=Socket busy)
	input wire TCP_ERROR           ,   // TCP error, its active period is equal to MSL
	input wire TCP_CLOSE_REQ       ,   // Connection close request
	output wire TCP_CLOSE_ACK      ,   // Acknowledge for closing
	// FIFO I/F
	output reg [10:0] TCP_RX_WC_11B,   // Rx FIFO write count[15:0] (Unused bits should be set 1)
	input wire TCP_RX_WR           ,   // Write enable
	input wire [7:0] TCP_RX_DATA   ,   // Write data[7:0]
	input wire TCP_TX_FULL         ,   // Almost full flag
	output wire TCP_TX_WR          ,   // Write enable
	output wire [7:0] TCP_TX_DATA  ,   // Write data[7:0]
	// RBCP
	input wire RBCP_ACT            ,   // RBCP active
	input wire [31:0] RBCP_ADDR    ,   // Address[31:0]
	input wire [7:0] RBCP_WD       ,   // Data[7:0]
	input wire RBCP_WE             ,   // Write enable
	input wire RBCP_RE             ,   // Read enable
	output wire RBCP_ACK           ,   // Access acknowledge
	output wire [7:0] RBCP_RD,         // Read data[7:0]

    
    output wire [7:0] LED

    );
    
   
/* -------  MODULE ADREESSES  ------- */
    localparam GPIO_BASEADDR = 32'h1000;
    localparam GPIO_HIGHADDR = 32'h101f;
 
 
/* -------  BUS SIGNALING  ------- */
    wire BUS_WR, BUS_RD, BUS_RST;
    wire [31:0] BUS_ADD;
    wire [7:0] BUS_DATA;
    assign BUS_RST = SiTCP_RST;
    
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

     
/* -------  USER MODULES  ------- */
    wire [7:0] GPIO_IO;
    gpio #(
        .BASEADDR(GPIO_BASEADDR),
        .HIGHADDR(GPIO_HIGHADDR),
        .ABUSWIDTH(32),
        .IO_WIDTH(8),
        .IO_DIRECTION(8'hff)
    ) i_gpio_rx (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA(BUS_DATA),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .IO(GPIO_IO)
    );
    
    
    wire FIFO_EMPTY, FIFO_FULL;
    reg fifo_write;
    reg [31:0] fifo_data_in;
    fifo_32_to_8 #(.DEPTH(256*1024)) i_data_fifo (
        .RST(BUS_RST),
        .CLK(BUS_CLK),
        
        .WRITE(fifo_write),
        .READ(TCP_TX_WR),
        .DATA_IN(fifo_data_in),
        .FULL(FIFO_FULL),
        .EMPTY(FIFO_EMPTY),
        .DATA_OUT(TCP_TX_DATA)
    );
    
    
    assign TCP_TX_WR = !TCP_TX_FULL && !FIFO_EMPTY;    
    
    reg ETH_START_SENDING, ETH_START_SENDING_temp, ETH_START_SENDING_LOCK;
    reg [31:0] datasource;
    assign LED = ~{TCP_OPEN_ACK, TCP_CLOSE_REQ, TCP_RX_WR, TCP_TX_WR, FIFO_FULL, FIFO_EMPTY, fifo_write, TCP_TX_WR};    //GPIO_IO[3:0]};
    
    
/* -------  Main FSM  ------- */    
    always@ (posedge BUS_CLK)
        begin
        
        // wait for start condition
        ETH_START_SENDING <= GPIO_IO[0];    //TCP_OPEN_ACK;
        
        if(ETH_START_SENDING && !ETH_START_SENDING_temp)
            ETH_START_SENDING_LOCK <= 1;
        ETH_START_SENDING_temp <= ETH_START_SENDING;  
        
        // RX FIFO word counter
        if(TCP_RX_WR) begin
            TCP_RX_WC_11B <= TCP_RX_WC_11B + 1;
        end
        else begin
            TCP_RX_WC_11B <= 11'd0;
        end
    
        // FIFO handshake
        if(ETH_START_SENDING_LOCK) begin
            if(!FIFO_FULL) begin
                fifo_data_in <= datasource;
                datasource <= datasource + 1;
                fifo_write <= 1'b1;
                end
            else
                fifo_write <= 1'b0;
        end
    
        // stop, if connection is closed by host
        if(TCP_CLOSE_REQ || !GPIO_IO[0]) begin
            ETH_START_SENDING_LOCK <= 0;
            fifo_write <= 1'b0;
            datasource <= 32'd0;
        end
        
    end     
    
endmodule
