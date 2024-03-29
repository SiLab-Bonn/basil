/**
* ------------------------------------------------------------
	* Copyright (c) All rights reserved
	* SiLab, Physics Institute, University of Bonn
	* ------------------------------------------------------------
		*/
	       `timescale 1ns / 1ps

	       module bdaq53_eth_tdl_core_bb(
		       input wire RESET_N,
		       // TDL related IO
		       input wire sig_in,


			       // clocks from PLL clock buffers
			       input wire BUS_CLK,
				       input wire PLL_LOCKED,
				       input wire CLK533,
				       input wire CLK133,

				       input wire          BUS_RST,
				       input wire  [31:0]  BUS_ADD,
				       inout wire  [7:0]   BUS_DATA,
				       input wire          BUS_RD,
				       input wire          BUS_WR,

				       input wire          FIFO_READY,
				       output reg          FIFO_VALID,
				       output reg [31:0]   FIFO_DATA,
				       output wire EN
			       );


			       /* -------  MODULE ADREESSES  ------- */
			       localparam GPIO_BASEADDR = 32'h1000;
			       localparam GPIO_HIGHADDR = 32'h101f;


			       /* -------  USER MODULES  ------- */
			       wire [7:0] GPIO;
			       gpio #(
				       .BASEADDR(GPIO_BASEADDR),
				       .HIGHADDR(GPIO_HIGHADDR),
				       .ABUSWIDTH(32),
				       .IO_WIDTH(8),
				       .IO_DIRECTION(8'h0f)
			       ) i_gpio_rx (
				       .BUS_CLK(BUS_CLK),
				       .BUS_RST(BUS_RST),
				       .BUS_ADD(BUS_ADD),
				       .BUS_DATA(BUS_DATA[7:0]),
				       .BUS_RD(BUS_RD),
				       .BUS_WR(BUS_WR),
				       .IO(GPIO)
			       );

			       wire ARM;
			       wire RST;
			       wire CAL;
			       assign ARM = GPIO[0];
			       assign RST = GPIO[1];
			       assign CAL = GPIO[2];
			       assign EN = GPIO[3];

			       localparam word_width = 32;
			       wire [word_width-1: 0] word_to_fifo;
			       wire fifo_write;
			       wire corse_overflow;
			       tdc i_tdc(
				       .CLK533(CLK533),
				       .CLK133(CLK133),
				       .sig_in(sig_in),
				       .arm(ARM),
				       .reset(RST),
				       .calibration_mode(CAL),

				       .corse_overflow(corse_overflow),
				       .out_word(word_to_fifo),
				       .out_valid(fifo_write));
			       assign GPIO[7] = corse_overflow;

			       //
			       // Now we need to transfer clock domains to Bus
			       wire no_hits_BUS;
			       wire [32-1:0] code_BUS;
			       cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) clock_sync_fifo (
				       .wdata(word_to_fifo),
				       .wclk(CLK133),
				       .winc(fifo_write),
				       .wrst(1'b0),
				       .rclk(BUS_CLK),
				       .rrst(1'b0),
				       .rinc(FIFO_READY),

				       .wfull(),
				       .rempty(no_hits_BUS),
				       .rdata(code_BUS)
			       );

			       always @(posedge BUS_CLK) begin
				       if(FIFO_READY) begin
					       if(~no_hits_BUS) begin
						       FIFO_DATA <= code_BUS;
						       FIFO_VALID <= 1;
					       end
					       else begin
						       FIFO_VALID <= 0;
						       FIFO_DATA <= 0;
					       end
				       end
				       else begin
					       FIFO_VALID <= 0;
					       FIFO_DATA <= 0;
				       end
			       end

			       endmodule
