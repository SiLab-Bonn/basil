
create_clock -period 10.000 -name clkin -add [get_ports clkin]
create_clock -period 8.000 -name rgmii_rxc -add [get_ports rgmii_rxc]

create_clock -period 6.250 -name CLK_160_in -add [get_ports Si570_P]
create_clock -period 6.400 -name CLK_156M250_in -add [get_ports Si511_P]

create_generated_clock -name I2C_CLK -source [get_pins PLLE2_BASE_BUS/CLKOUT0] -divide_by 1600 [get_pins -hier -filter {NAME =~ *i_clock_divisor_i2c/CLOCK_reg/Q}]

set_false_path -from [get_clocks CLK125PLLTX] -to [get_clocks BUS_CLK_PLL]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK125PLLTX]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks rgmii_rxc]
set_false_path -from [get_clocks rgmii_rxc] -to [get_clocks BUS_CLK_PLL]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK160PLL]
set_false_path -from [get_clocks CLK160PLL] -to [get_clocks BUS_CLK_PLL]
set_false_path -from [get_clocks CLK160PLL] -to [get_clocks CLK480PLL]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK480PLL]
set_false_path -from [get_clocks rgmii_rxc] -to [get_clocks CLK160PLL]
set_false_path -from [get_clocks CLK_156M250_in] -to [get_clocks CLK160PLL]
set_false_path -from [get_clocks CLK_156M250_in] -to [get_clocks CLK480PLL]
set_false_path -from [get_clocks CLK_156M250_in] -to [get_clocks BUS_CLK_PLL]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK_156M250_in]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks I2C_CLK]

set_false_path -from [get_cells -hier -filter {NAME =~ */calib_sig_gen/*  && IS_SEQUENTIAL ==1}] -to [get_cells -hier -filter {NAME =~ */i_controller/* && IS_SEQUENTIAL ==1  }]
set_false_path -from [get_cells -hier -filter {NAME =~ */input_mux_addr_buf_reg*  && IS_SEQUENTIAL ==1}] -to [get_cells -hier -filter {NAME =~ */tdl_sampler/carry_chain* && IS_SEQUENTIAL ==1  }]
set_false_path -from [get_cells -hier -filter {NAME =~ */calib_sig_gen/*  && IS_SEQUENTIAL ==1}] -to [get_cells -hier -filter {NAME =~ */tdl_sampler/* && IS_SEQUENTIAL ==1  }]
set_false_path -from [get_cells -hier -filter {NAME =~ */conf_en_invert_tdc_synchronizer_dv_clk/* && IS_SEQUENTIAL ==1}] -to [get_cells -hier -filter {NAME =~ */tdl_sampler/carry_chain* && IS_SEQUENTIAL ==1}]

#CLK Mux
set_property PACKAGE_PIN D23 [get_ports MGT_REF_SEL]
set_property IOSTANDARD LVCMOS33 [get_ports MGT_REF_SEL]
set_property PULLUP true [get_ports MGT_REF_SEL]

# I2C pins
set_property PACKAGE_PIN L23 [get_ports I2C_SCL]
set_property PACKAGE_PIN C24 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports I2C_*]
set_property SLEW SLOW [get_ports I2C_*]

# Si570 Clock, MGT_REFCLK0 in bdaq
set_property PACKAGE_PIN H6 [get_ports Si570_P]
set_property PACKAGE_PIN H5 [get_ports Si570_N]

# Si511 Clock, MGT_REFCLK3 in bdaq
set_property PACKAGE_PIN F6 [get_ports Si511_P]
set_property PACKAGE_PIN F5 [get_ports Si511_N]

#NET "Clk100"
set_property PACKAGE_PIN AA4 [get_ports clkin]
set_property IOSTANDARD LVCMOS15 [get_ports clkin]

set_property PACKAGE_PIN G9 [get_ports RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports RESET_N]
set_property PULLUP true [get_ports RESET_N]

set_property SLEW FAST [get_ports mdio_phy_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_phy_mdc]
set_property PACKAGE_PIN B25 [get_ports mdio_phy_mdc]

set_property SLEW FAST [get_ports mdio_phy_mdio]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_phy_mdio]
set_property PACKAGE_PIN B26 [get_ports mdio_phy_mdio]

#M20 is routed to Connector C. The Ethernet PHY on th KX2 board has NO reset connection
set_property SLEW FAST [get_ports phy_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports phy_rst_n]
set_property PACKAGE_PIN M20 [get_ports phy_rst_n]

set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rxc]
set_property PACKAGE_PIN G22 [get_ports rgmii_rxc]

set_property IOSTANDARD LVCMOS33 [get_ports rgmii_rx_ctl]
set_property PACKAGE_PIN F23 [get_ports rgmii_rx_ctl]

set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[0]}]
set_property PACKAGE_PIN H23 [get_ports {rgmii_rxd[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[1]}]
set_property PACKAGE_PIN H24 [get_ports {rgmii_rxd[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[2]}]
set_property PACKAGE_PIN J21 [get_ports {rgmii_rxd[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_rxd[3]}]
set_property PACKAGE_PIN H22 [get_ports {rgmii_rxd[3]}]

set_property SLEW FAST [get_ports rgmii_txc]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_txc]
set_property PACKAGE_PIN K23 [get_ports rgmii_txc]

set_property SLEW FAST [get_ports rgmii_tx_ctl]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_tx_ctl]
set_property PACKAGE_PIN J23 [get_ports rgmii_tx_ctl]

set_property SLEW FAST [get_ports {rgmii_txd[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[0]}]
set_property PACKAGE_PIN J24 [get_ports {rgmii_txd[0]}]
set_property SLEW FAST [get_ports {rgmii_txd[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[1]}]
set_property PACKAGE_PIN J25 [get_ports {rgmii_txd[1]}]
set_property SLEW FAST [get_ports {rgmii_txd[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[2]}]
set_property PACKAGE_PIN L22 [get_ports {rgmii_txd[2]}]
set_property SLEW FAST [get_ports {rgmii_txd[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_txd[3]}]
set_property PACKAGE_PIN K22 [get_ports {rgmii_txd[3]}]

# LEDs
# LED 0..3 are onboard LEDs
set_property PACKAGE_PIN U9 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[0]}]
set_property PACKAGE_PIN V12 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[1]}]
set_property PACKAGE_PIN V13 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[2]}]
set_property PACKAGE_PIN W13 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[3]}]
# LED 4..7 are LEDs on the BDAQ53 base board
set_property PACKAGE_PIN E21 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN E22 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN D21 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN C22 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property SLEW SLOW [get_ports LED*]

# DP_ML ("DP2") L_3_P (B148)
set_property PACKAGE_PIN B17 [get_ports sig_out]
set_property IOSTANDARD LVCMOS25 [get_ports sig_out]

# DP_ML ("DP2") L_2_P (B154)
set_property PACKAGE_PIN E18 [get_ports trig_out]
set_property IOSTANDARD LVCMOS25 [get_ports trig_out]

# TDL input
# LEMO RX_0
# set_property PACKAGE_PIN AB22 [get_ports sig_in]

# DP_ML ("DP2") L_1_P (B160)
set_property PACKAGE_PIN C19 [get_ports sig_in]
set_property IOSTANDARD LVCMOS25 [get_ports sig_in]

# LEMO RX_1
#set_property PACKAGE_PIN AD23 [get_ports trig_in]

# DP_ML ("DP2") L_0_P (B164)
set_property PACKAGE_PIN A18 [get_ports trig_in]
set_property IOSTANDARD LVCMOS25 [get_ports trig_in]

# SPI configuration flash
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
