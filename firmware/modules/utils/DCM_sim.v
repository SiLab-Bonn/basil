/**
Based on: https://github.com/dirjud/Nitro-Parts-lib-Xilinx
 */
`timescale 1ps/1ps
`default_nettype none

         
module DCM
  #(   parameter CLKFX_MULTIPLY = 4,
       parameter CLKFX_DIVIDE   = 1,
       parameter CLKDV_DIVIDE   = 2,
       parameter CLKIN_PERIOD   = 10,
       parameter CLK_FEEDBACK   = 0,
       parameter CLKOUT_PHASE_SHIFT = 0,
       parameter CLKIN_DIVIDE_BY_2 = "FALSE",
       parameter DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS",
       parameter DFS_FREQUENCY_MODE = "LOW",
       parameter DLL_FREQUENCY_MODE = "LOW",
       parameter DUTY_CYCLE_CORRECTION = "TRUE",
       parameter FACTORY_JF = 16'hC080,
       parameter PHASE_SHIFT = 0,
       parameter STARTUP_WAIT = "TRUE"
       )
   (
    CLK0, CLK180, CLK270, CLK2X, CLK2X180, CLK90,
    CLKDV, CLKFX, CLKFX180, LOCKED, PSDONE, STATUS,
    CLKFB, CLKIN, DSSEN, PSCLK, PSEN, PSINCDEC, RST);
   

input CLKFB, CLKIN, DSSEN;
input PSCLK, PSEN, PSINCDEC, RST;

output CLKDV, CLKFX, CLKFX180, LOCKED, PSDONE;
output CLK0, CLK180, CLK270, CLK2X, CLK2X180, CLK90;
output [7:0] STATUS;

assign STATUS = 0;
assign CLK0 = CLKIN;
assign CLK180 = ~CLKIN;
assign CLK270   = ~CLK90;
assign CLK2X180 = ~CLK2X;
assign CLKFX180 = ~CLKFX;

wire resetb = ~RST;

wire clk2x;
clock_multiplier #( .MULTIPLIER(2) ) i_clock_multiplier(.CLK(CLKIN),.CLOCK(clk2x));

reg clk90;
reg [1:0] cnt;
always @(posedge clk2x or negedge clk2x or negedge resetb) begin
  if (!resetb) begin
     clk90 <= 0;
     cnt <= 0;
  end else begin
     cnt <= cnt + 1;
     if (!cnt[0]) clk90 <= ~clk90; 
  end
end
assign CLK2X = clk2x;
assign CLK90 = clk90;

generate
    wire lock_fx;
    if (CLKFX_MULTIPLY==2 && CLKFX_DIVIDE==1) begin
         assign CLKFX = clk2x;
    end else begin
        wire CLKINM;
        clock_multiplier #( .MULTIPLIER(CLKFX_MULTIPLY) ) i_clock_multiplier(.CLK(CLKIN),.CLOCK(CLKINM));
        clock_divider #(.DIVISOR(2)) i_clock_divisor_rx (.CLK(CLKINM), .RESET(RST), .CE(), .CLOCK(CLKFX)); 

    end
endgenerate

clock_divider #(.DIVISOR(CLKDV_DIVIDE)) i_clock_divisor_dv (.CLK(CLKIN), .RESET(RST), .CE(), .CLOCK(CLKDV)); 

assign LOCKED = 1'b1;

endmodule
