#Seq_gen output
# DP_ML ("DP2") L_3_P
#B148
set_property PACKAGE_PIN B17 [get_ports sig_out]
set_property IOSTANDARD LVCMOS25 [get_ports sig_out]
# DP_ML ("DP2") L_2_P
#B154
set_property PACKAGE_PIN E18 [get_ports trig_out]
set_property IOSTANDARD LVCMOS25 [get_ports trig_out]

#TDL input
# LEMO RX_0
#set_property PACKAGE_PIN AB22 [get_ports sig_in]

# DP_ML ("DP2") L_1_P
# B160
set_property PACKAGE_PIN C19 [get_ports sig_in]
set_property IOSTANDARD LVCMOS25 [get_ports sig_in]

# LEMO RX_1
#set_property PACKAGE_PIN AD23 [get_ports trig_in]

# DP_ML ("DP2") L_0_P
# B164
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


