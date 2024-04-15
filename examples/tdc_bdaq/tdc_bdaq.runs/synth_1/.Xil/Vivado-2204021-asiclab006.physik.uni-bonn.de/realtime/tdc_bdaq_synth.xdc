set_property SRC_FILE_INFO {cfile:/users/rleiser/work/basil_branch/examples/tdc_bdaq/bdaq53.xdc rfile:../../../../../bdaq53.xdc id:1} [current_design]
set_property SRC_FILE_INFO {cfile:/users/rleiser/work/basil_branch/examples/tdc_bdaq/tdc_bdaq.xdc rfile:../../../../../tdc_bdaq.xdc id:2} [current_design]
set_property src_info {type:XDC file:1 line:2 export:INPUT save:INPUT read:READ} [current_design]
create_clock -period 10.000 -name clkin -add [get_ports clkin]
set_property src_info {type:XDC file:1 line:3 export:INPUT save:INPUT read:READ} [current_design]
create_clock -period 8.000 -name rgmii_rxc -add [get_ports rgmii_rxc]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name PLL2_FEEDBACK -source [get_pins PLLE2_BASE_160/CLKIN1] -multiply_by 1 -add -master_clock [get_clocks clkin] [get_pins PLLE2_BASE_160/CLKFBOUT]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name CLK160 -source [get_pins PLLE2_BASE_160/CLKIN1] -edges {1 2 3} -edge_shift {1.562 -0.312 -2.188} -add -master_clock [get_clocks clkin] [get_pins PLLE2_BASE_160/CLKOUT0]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name PLL_FEEDBACK -source [get_pins PLLE2_BASE_BUS/CLKIN1] -multiply_by 1 -add -master_clock [get_clocks clkin] [get_pins PLLE2_BASE_BUS/CLKFBOUT]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name BUS_CLK_PLL -source [get_pins PLLE2_BASE_BUS/CLKIN1] -edges {1 2 3} -edge_shift {0.000 -1.500 -3.000} -add -master_clock [get_clocks clkin] [get_pins PLLE2_BASE_BUS/CLKOUT0]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name CLK125PLLTX -source [get_pins PLLE2_BASE_BUS/CLKIN1] -edges {1 2 3} -edge_shift {0.000 -1.000 -2.000} -add -master_clock [get_clocks clkin] [get_pins PLLE2_BASE_BUS/CLKOUT2]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name CLK125PLLTX90 -source [get_pins PLLE2_BASE_BUS/CLKIN1] -edges {1 2 3} -edge_shift {2.000 1.000 -0.000} -add -master_clock [get_clocks clkin] [get_pins PLLE2_BASE_BUS/CLKOUT3]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name PLL3_FEEDBACK -source [get_pins PLLE2_BASE_480/CLKIN1] -multiply_by 1 -add -master_clock [get_clocks CLK160] [get_pins PLLE2_BASE_480/CLKFBOUT]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name CLK160PLL -source [get_pins PLLE2_BASE_480/CLKIN1] -multiply_by 1 -add -master_clock [get_clocks CLK160] [get_pins PLLE2_BASE_480/CLKOUT0]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name CLK480PLL -source [get_pins PLLE2_BASE_480/CLKIN1] -edges {1 2 3} -edge_shift {0.000 -2.083 -4.167} -add -master_clock [get_clocks CLK160] [get_pins PLLE2_BASE_480/CLKOUT1]
set_property src_info {type:XDC file:1 line:5 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks CLK125PLLTX] -to [get_clocks BUS_CLK_PLL]
set_property src_info {type:XDC file:1 line:6 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK125PLLTX]
set_property src_info {type:XDC file:1 line:7 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks rgmii_rxc]
set_property src_info {type:XDC file:1 line:8 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks rgmii_rxc] -to [get_clocks BUS_CLK_PLL]
set_property src_info {type:XDC file:1 line:9 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK160PLL]
set_property src_info {type:XDC file:1 line:10 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks CLK160PLL] -to [get_clocks BUS_CLK_PLL]
set_property src_info {type:XDC file:1 line:11 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK480PLL]
set_property src_info {type:XDC file:1 line:12 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_clocks CLK160PLL] -to [get_clocks CLK480PLL]
set_property src_info {type:XDC file:1 line:14 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -from [get_cells [list i_tdc/i_tdc_core/calib_sig_gen/pulse_reg {i_tdc/i_tdc_core/calib_sig_gen/count_index_reg[0]} {i_tdc/i_tdc_core/calib_sig_gen/count_index_reg[1]} {i_tdc/i_tdc_core/calib_sig_gen/count_index_reg[2]} {i_tdc/i_tdc_core/calib_sig_gen/count_index_reg[3]}]] -to [get_cells [list i_tdc/i_tdc_core/i_tdl/tdl_sampler/FirstCell/TDL_FF_A \
          i_tdc/i_tdc_core/i_tdl/tdl_sampler/FirstCell/TDL_FF_B \
          i_tdc/i_tdc_core/i_tdl/tdl_sampler/FirstCell/TDL_FF_C \
          i_tdc/i_tdc_core/i_tdl/tdl_sampler/FirstCell/TDL_FF_D \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[10].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[10].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[10].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[10].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[11].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[11].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[11].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[11].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[12].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[12].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[12].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[12].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[13].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[13].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[13].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[13].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[14].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[14].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[14].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[14].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[15].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[15].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[15].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[15].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[16].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[16].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[16].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[16].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[17].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[17].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[17].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[17].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[18].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[18].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[18].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[18].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[19].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[19].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[19].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[19].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[1].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[1].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[1].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[1].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[20].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[20].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[20].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[20].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[21].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[21].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[21].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[21].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[22].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[22].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[22].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[22].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[23].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[23].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[23].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[23].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[24].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[24].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[24].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[24].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[25].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[25].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[25].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[25].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[26].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[26].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[26].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[26].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[27].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[27].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[27].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[27].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[28].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[28].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[28].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[28].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[29].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[29].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[29].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[29].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[2].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[2].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[2].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[2].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[30].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[30].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[30].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[30].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[31].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[31].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[31].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[31].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[32].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[32].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[32].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[32].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[33].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[33].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[33].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[33].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[34].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[34].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[34].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[34].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[35].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[35].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[35].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[35].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[36].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[36].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[36].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[36].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[37].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[37].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[37].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[37].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[38].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[38].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[38].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[38].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[39].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[39].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[39].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[39].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[3].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[3].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[3].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[3].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[40].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[40].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[40].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[40].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[41].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[41].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[41].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[41].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[42].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[42].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[42].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[42].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[43].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[43].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[43].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[43].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[44].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[44].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[44].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[44].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[45].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[45].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[45].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[45].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[46].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[46].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[46].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[46].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[47].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[47].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[47].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[47].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[4].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[4].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[4].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[4].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[5].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[5].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[5].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[5].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[6].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[6].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[6].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[6].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[7].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[7].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[7].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[7].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[8].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[8].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[8].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[8].MoreCells/TDL_FF_D} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[9].MoreCells/TDL_FF_A} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[9].MoreCells/TDL_FF_B} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[9].MoreCells/TDL_FF_C} \
          {i_tdc/i_tdc_core/i_tdl/tdl_sampler/carry_chain[9].MoreCells/TDL_FF_D}]]
set_property src_info {type:XDC file:1 line:18 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS15 [get_ports clkin]
set_property src_info {type:XDC file:1 line:21 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports RESET_N]
set_property src_info {type:XDC file:1 line:22 export:INPUT save:INPUT read:READ} [current_design]
set_property PULLUP true [get_ports RESET_N]
set_property src_info {type:XDC file:1 line:24 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports mdio_phy_mdc]
set_property src_info {type:XDC file:1 line:25 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_phy_mdc]
set_property src_info {type:XDC file:1 line:28 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports mdio_phy_mdio]
set_property src_info {type:XDC file:1 line:29 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_phy_mdio]
set_property src_info {type:XDC file:1 line:33 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports phy_rst_n]
set_property src_info {type:XDC file:1 line:34 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports phy_rst_n]
set_property src_info {type:XDC file:1 line:37 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rxc]
set_property src_info {type:XDC file:1 line:40 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rx_ctl]
set_property src_info {type:XDC file:1 line:43 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[0]}]
set_property src_info {type:XDC file:1 line:45 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[1]}]
set_property src_info {type:XDC file:1 line:47 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[2]}]
set_property src_info {type:XDC file:1 line:49 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[3]}]
set_property src_info {type:XDC file:1 line:52 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports rgmii_txc]
set_property src_info {type:XDC file:1 line:53 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_txc]
set_property src_info {type:XDC file:1 line:56 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports rgmii_tx_ctl]
set_property src_info {type:XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_tx_ctl]
set_property src_info {type:XDC file:1 line:60 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports {rgmii_txd[0]}]
set_property src_info {type:XDC file:1 line:61 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[0]}]
set_property src_info {type:XDC file:1 line:63 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports {rgmii_txd[1]}]
set_property src_info {type:XDC file:1 line:64 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[1]}]
set_property src_info {type:XDC file:1 line:66 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports {rgmii_txd[2]}]
set_property src_info {type:XDC file:1 line:67 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[2]}]
set_property src_info {type:XDC file:1 line:69 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW FAST [get_ports {rgmii_txd[3]}]
set_property src_info {type:XDC file:1 line:70 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[3]}]
set_property src_info {type:XDC file:1 line:76 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[0]}]
set_property src_info {type:XDC file:1 line:78 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[1]}]
set_property src_info {type:XDC file:1 line:80 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[2]}]
set_property src_info {type:XDC file:1 line:82 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[3]}]
set_property src_info {type:XDC file:1 line:85 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property src_info {type:XDC file:1 line:87 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property src_info {type:XDC file:1 line:89 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property src_info {type:XDC file:1 line:91 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property src_info {type:XDC file:1 line:92 export:INPUT save:INPUT read:READ} [current_design]
set_property SLEW SLOW [get_ports LED*]
set_property src_info {type:XDC file:2 line:3 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports sig_in]
set_property src_info {type:XDC file:2 line:5 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports trig_in]
set_property src_info {type:XDC file:2 line:220 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/hit_status[0]}]
set_property src_info {type:XDC file:2 line:221 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/hit_status[1]}]
set_property src_info {type:XDC file:2 line:222 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time[0]}]
set_property src_info {type:XDC file:2 line:223 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time[1]}]
set_property src_info {type:XDC file:2 line:226 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[0]}]
set_property src_info {type:XDC file:2 line:227 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[1]}]
set_property src_info {type:XDC file:2 line:228 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[2]}]
set_property src_info {type:XDC file:2 line:229 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[3]}]
set_property src_info {type:XDC file:2 line:230 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[4]}]
set_property src_info {type:XDC file:2 line:231 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[5]}]
set_property src_info {type:XDC file:2 line:232 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[6]}]
set_property src_info {type:XDC file:2 line:233 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[0]}]
set_property src_info {type:XDC file:2 line:234 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[1]}]
set_property src_info {type:XDC file:2 line:235 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[2]}]
set_property src_info {type:XDC file:2 line:236 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[3]}]
set_property src_info {type:XDC file:2 line:237 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time_delayed[0]}]
set_property src_info {type:XDC file:2 line:238 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time_delayed[1]}]
