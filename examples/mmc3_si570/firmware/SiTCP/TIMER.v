`default_nettype wire
/*******************************************************************************
*                                                                              *
* Module      : TIMER                                                          *
* Version     : v 0.2.0 2010/03/31                                             *
*               v 3.0  2010/04/21 Change polarity of system reset              *
*                                                                              *
* Description : TIMER                                                          *
*                                                                              *
*                Copyright (c) 2010 Bee Beans Technologies Co.,Ltd.            *
*                All rights reserved                                           *
*                                                                              *
*******************************************************************************/
module TIMER(
// Parameter: 158(160M), 123(125M),48(50MHz) ,23(25MHz), 18(20MHz), 8(10Mz)
// System
	CLK					,	// in	: System clock
	RST					,	// in	: System reset
// Intrrupts
	TIM_1US				,	// out	: 1 us interval
	TIM_1MS				,	// out	: 1 ms interval
	TIM_1S				,	// out	: 1 s interval
	TIM_1M					// out	: 1 m interval
);

//-------- Input/Output -------------
	input			CLK					;
	input			RST					;

	output			TIM_1US				;
	output			TIM_1MS				;
	output			TIM_1S				;
	output			TIM_1M				;

//------ output signals -----
	wire			TIM_1US				;
	wire			TIM_1MS				;
	wire			TIM_1S				;
	wire			TIM_1M				;

	reg				pulse1us			;
	reg				pulse1ms			;
	reg				pulse1s				;
	reg				pulse1m				;

	parameter	[7:0]	TIM_PERIOD = 8'd23;	// 23=1us/40ns - 2(25MHz), 18(20MHz), 8(10Mz)

//------------------------------------------------------------------------------
//	Timer
//------------------------------------------------------------------------------
	reg				usCry				;
	reg		[7:0]	usTim				;

	always@ (posedge CLK or posedge RST) begin
		if(RST)begin
			{usCry,usTim[7:0]}	<= 9'd0;
		end else begin
			{usCry,usTim[7:0]}	<= (usCry	? {1'b0,TIM_PERIOD[7:0]}	: {usCry,usTim[7:0]} - 9'd1);
		end
	end

//	assign	carryUs	= usCry;

	reg		[10:0]	msTim				;
	reg		[10:0]	sTim				;
	reg		[6:0]	mTim				;

	always@ (posedge CLK or posedge RST) begin
		if(RST)begin
			msTim[10:0]	<= 11'd0;
			sTim[10:0]	<= 11'd0;
			mTim[6:0]	<= 7'd0;
		end else begin
			if(usCry)begin
				msTim[10:0]	<= (msTim[10]	? 11'd998 : msTim[10:0] - 11'd1);
			end
			if(usCry & msTim[10])begin
				sTim[10:0]	<= (sTim[10]	? 11'd998 : sTim[10:0] - 11'd1);
			end
			if(usCry & msTim[10] & sTim[10])begin
				mTim[6:0]	<= (mTim[6]	? 7'd58 : mTim[6:0] - 7'd1);
			end
		end
	end

	always@ (posedge CLK) begin
		pulse1us	<= usCry;
		pulse1ms	<= usCry & msTim[10];
		pulse1s		<= usCry & msTim[10] & sTim[10];
		pulse1m		<= usCry & msTim[10] & sTim[10] & mTim[6];
	end

	assign	TIM_1US	= pulse1us;
	assign	TIM_1MS	= pulse1ms;
	assign	TIM_1S	= pulse1s;
	assign	TIM_1M	= pulse1m;

//------------------------------------------------------------------------------
endmodule
