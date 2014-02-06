/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved 
 * SiLab , Physics Institute of Bonn University , All Right 
 * ------------------------------------------------------------
 *
 * SVN revision information:
 *  $Rev::                       $:
 *  $Author::                    $:
 *  $Date::                      $:
 */

`timescale 1ps / 1ps
`default_nettype none

module manchester_encoding (
    input wire CLK, // clock
    input wire CLK4X, // 4x clock
    input wire DI, // data input
    output reg DO // data out
    input wire ENABLE, // enable ME
    input wire INVERT // change phase of ME data by 180 degree
);

reg [1:0] cnt;
reg rst;

always @(posedge CLK4X)
begin
	if (ENABLE)
		begin
			if (INVERT)
				begin
					if ((cnt == 2) || (cnt == 3))
						DO <= !DI;
					else
						DO <= DI;
				end		
			else
				begin
					if ((cnt == 0) || (cnt == 1))
						DO <= !DI;
					else
						DO <= DI;
				end
		end
    else
        DO <= DI;
end

always @ (posedge CLK4X)
begin
    if (!rst && CLK)
        rst <= 1;
    else
        rst <= 0;
end

always @(posedge CLK4X)
begin
    if (rst)
        cnt <= 0;
    else
        cnt <= cnt + 1;
end

endmodule
