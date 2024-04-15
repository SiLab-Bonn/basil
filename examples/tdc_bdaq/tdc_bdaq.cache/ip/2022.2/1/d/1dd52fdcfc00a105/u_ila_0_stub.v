// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Fri Apr  5 15:51:21 2024
// Host        : asiclab006.physik.uni-bonn.de running 64-bit unknown
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ u_ila_0_stub.v
// Design      : u_ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k160tffg676-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2022.2" *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[95:0],probe1[1:0],probe2[1:0],probe3[1:0],probe4[3:0],probe5[0:0],probe6[0:0],probe7[0:0]" */;
  input clk;
  input [95:0]probe0;
  input [1:0]probe1;
  input [1:0]probe2;
  input [1:0]probe3;
  input [3:0]probe4;
  input [0:0]probe5;
  input [0:0]probe6;
  input [0:0]probe7;
endmodule
