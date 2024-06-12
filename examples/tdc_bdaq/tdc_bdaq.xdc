#TDL input
# LEMO RX_0
#set_property PACKAGE_PIN AB22 [get_ports sig_in]
# DP_ML ("DP2") L_1_P
set_property PACKAGE_PIN C19 [get_ports sig_in]
set_property IOSTANDARD LVCMOS25 [get_ports sig_in]
# LEMO RX_1
#set_property PACKAGE_PIN AD23 [get_ports trig_in]
# DP_ML ("DP2") L_0_P
set_property PACKAGE_PIN A18 [get_ports trig_in]
set_property IOSTANDARD LVCMOS25 [get_ports trig_in]

# DP_ML ("DP2") connected to SelectIOs
#set_property PACKAGE_PIN C19 [get_ports DP_GPIO_P[1]]
#set_property PACKAGE_PIN E18 [get_ports DP_GPIO_P[2]]



set_property LOC SLICE_X38Y3 [get_cells -hier -regexp .*FirstCell/CARRY4_inst]


set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/hit_status[0]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/hit_status[1]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time[0]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time[1]}]


set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[0]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[1]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[2]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[3]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[4]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[5]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/encoder/position_out[6]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[0]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[1]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[2]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/tdc_state_delayed[3]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time_delayed[0]}]
set_property MARK_DEBUG true [get_nets {i_tdc/i_tdc_core/fine_time_delayed[1]}]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list CLK160PLL_BUFG]]
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe0]
set_property port_width 7 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_tdc/i_tdc_core/encoder/position_out[0]} {i_tdc/i_tdc_core/encoder/position_out[1]} {i_tdc/i_tdc_core/encoder/position_out[2]} {i_tdc/i_tdc_core/encoder/position_out[3]} {i_tdc/i_tdc_core/encoder/position_out[4]} {i_tdc/i_tdc_core/encoder/position_out[5]} {i_tdc/i_tdc_core/encoder/position_out[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe1]
set_property port_width 96 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_tdc/i_tdc_core/selected_sample[0]} {i_tdc/i_tdc_core/selected_sample[1]} {i_tdc/i_tdc_core/selected_sample[2]} {i_tdc/i_tdc_core/selected_sample[3]} {i_tdc/i_tdc_core/selected_sample[4]} {i_tdc/i_tdc_core/selected_sample[5]} {i_tdc/i_tdc_core/selected_sample[6]} {i_tdc/i_tdc_core/selected_sample[7]} {i_tdc/i_tdc_core/selected_sample[8]} {i_tdc/i_tdc_core/selected_sample[9]} {i_tdc/i_tdc_core/selected_sample[10]} {i_tdc/i_tdc_core/selected_sample[11]} {i_tdc/i_tdc_core/selected_sample[12]} {i_tdc/i_tdc_core/selected_sample[13]} {i_tdc/i_tdc_core/selected_sample[14]} {i_tdc/i_tdc_core/selected_sample[15]} {i_tdc/i_tdc_core/selected_sample[16]} {i_tdc/i_tdc_core/selected_sample[17]} {i_tdc/i_tdc_core/selected_sample[18]} {i_tdc/i_tdc_core/selected_sample[19]} {i_tdc/i_tdc_core/selected_sample[20]} {i_tdc/i_tdc_core/selected_sample[21]} {i_tdc/i_tdc_core/selected_sample[22]} {i_tdc/i_tdc_core/selected_sample[23]} {i_tdc/i_tdc_core/selected_sample[24]} {i_tdc/i_tdc_core/selected_sample[25]} {i_tdc/i_tdc_core/selected_sample[26]} {i_tdc/i_tdc_core/selected_sample[27]} {i_tdc/i_tdc_core/selected_sample[28]} {i_tdc/i_tdc_core/selected_sample[29]} {i_tdc/i_tdc_core/selected_sample[30]} {i_tdc/i_tdc_core/selected_sample[31]} {i_tdc/i_tdc_core/selected_sample[32]} {i_tdc/i_tdc_core/selected_sample[33]} {i_tdc/i_tdc_core/selected_sample[34]} {i_tdc/i_tdc_core/selected_sample[35]} {i_tdc/i_tdc_core/selected_sample[36]} {i_tdc/i_tdc_core/selected_sample[37]} {i_tdc/i_tdc_core/selected_sample[38]} {i_tdc/i_tdc_core/selected_sample[39]} {i_tdc/i_tdc_core/selected_sample[40]} {i_tdc/i_tdc_core/selected_sample[41]} {i_tdc/i_tdc_core/selected_sample[42]} {i_tdc/i_tdc_core/selected_sample[43]} {i_tdc/i_tdc_core/selected_sample[44]} {i_tdc/i_tdc_core/selected_sample[45]} {i_tdc/i_tdc_core/selected_sample[46]} {i_tdc/i_tdc_core/selected_sample[47]} {i_tdc/i_tdc_core/selected_sample[48]} {i_tdc/i_tdc_core/selected_sample[49]} {i_tdc/i_tdc_core/selected_sample[50]} {i_tdc/i_tdc_core/selected_sample[51]} {i_tdc/i_tdc_core/selected_sample[52]} {i_tdc/i_tdc_core/selected_sample[53]} {i_tdc/i_tdc_core/selected_sample[54]} {i_tdc/i_tdc_core/selected_sample[55]} {i_tdc/i_tdc_core/selected_sample[56]} {i_tdc/i_tdc_core/selected_sample[57]} {i_tdc/i_tdc_core/selected_sample[58]} {i_tdc/i_tdc_core/selected_sample[59]} {i_tdc/i_tdc_core/selected_sample[60]} {i_tdc/i_tdc_core/selected_sample[61]} {i_tdc/i_tdc_core/selected_sample[62]} {i_tdc/i_tdc_core/selected_sample[63]} {i_tdc/i_tdc_core/selected_sample[64]} {i_tdc/i_tdc_core/selected_sample[65]} {i_tdc/i_tdc_core/selected_sample[66]} {i_tdc/i_tdc_core/selected_sample[67]} {i_tdc/i_tdc_core/selected_sample[68]} {i_tdc/i_tdc_core/selected_sample[69]} {i_tdc/i_tdc_core/selected_sample[70]} {i_tdc/i_tdc_core/selected_sample[71]} {i_tdc/i_tdc_core/selected_sample[72]} {i_tdc/i_tdc_core/selected_sample[73]} {i_tdc/i_tdc_core/selected_sample[74]} {i_tdc/i_tdc_core/selected_sample[75]} {i_tdc/i_tdc_core/selected_sample[76]} {i_tdc/i_tdc_core/selected_sample[77]} {i_tdc/i_tdc_core/selected_sample[78]} {i_tdc/i_tdc_core/selected_sample[79]} {i_tdc/i_tdc_core/selected_sample[80]} {i_tdc/i_tdc_core/selected_sample[81]} {i_tdc/i_tdc_core/selected_sample[82]} {i_tdc/i_tdc_core/selected_sample[83]} {i_tdc/i_tdc_core/selected_sample[84]} {i_tdc/i_tdc_core/selected_sample[85]} {i_tdc/i_tdc_core/selected_sample[86]} {i_tdc/i_tdc_core/selected_sample[87]} {i_tdc/i_tdc_core/selected_sample[88]} {i_tdc/i_tdc_core/selected_sample[89]} {i_tdc/i_tdc_core/selected_sample[90]} {i_tdc/i_tdc_core/selected_sample[91]} {i_tdc/i_tdc_core/selected_sample[92]} {i_tdc/i_tdc_core/selected_sample[93]} {i_tdc/i_tdc_core/selected_sample[94]} {i_tdc/i_tdc_core/selected_sample[95]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_tdc/i_tdc_core/tdc_state_delayed[0]} {i_tdc/i_tdc_core/tdc_state_delayed[1]} {i_tdc/i_tdc_core/tdc_state_delayed[2]} {i_tdc/i_tdc_core/tdc_state_delayed[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 4 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_tdc/i_tdc_core/tdc_state[0]} {i_tdc/i_tdc_core/tdc_state[1]} {i_tdc/i_tdc_core/tdc_state[2]} {i_tdc/i_tdc_core/tdc_state[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe4]
set_property port_width 2 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_tdc/i_tdc_core/fine_time_delayed[0]} {i_tdc/i_tdc_core/fine_time_delayed[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe5]
set_property port_width 2 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {i_tdc/i_tdc_core/input_mux_addr[0]} {i_tdc/i_tdc_core/input_mux_addr[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe6]
set_property port_width 2 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {i_tdc/i_tdc_core/hit_status[0]} {i_tdc/i_tdc_core/hit_status[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe7]
set_property port_width 2 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {i_tdc/i_tdc_core/fine_time[0]} {i_tdc/i_tdc_core/fine_time[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe8]
set_property port_width 16 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {i_tdc/i_tdc_core/corse_time_delayed[0]} {i_tdc/i_tdc_core/corse_time_delayed[1]} {i_tdc/i_tdc_core/corse_time_delayed[2]} {i_tdc/i_tdc_core/corse_time_delayed[3]} {i_tdc/i_tdc_core/corse_time_delayed[4]} {i_tdc/i_tdc_core/corse_time_delayed[5]} {i_tdc/i_tdc_core/corse_time_delayed[6]} {i_tdc/i_tdc_core/corse_time_delayed[7]} {i_tdc/i_tdc_core/corse_time_delayed[8]} {i_tdc/i_tdc_core/corse_time_delayed[9]} {i_tdc/i_tdc_core/corse_time_delayed[10]} {i_tdc/i_tdc_core/corse_time_delayed[11]} {i_tdc/i_tdc_core/corse_time_delayed[12]} {i_tdc/i_tdc_core/corse_time_delayed[13]} {i_tdc/i_tdc_core/corse_time_delayed[14]} {i_tdc/i_tdc_core/corse_time_delayed[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list i_tdc/sig_in_IBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list i_tdc/i_tdc_core/tdl_input]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list i_tdc/i_tdc_core/trig_in_IBUF]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets CLK160PLL_BUFG]
