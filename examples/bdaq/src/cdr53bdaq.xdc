
# ------------------------------------------------------------
#  Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
#   Constraints for the BDAQ53 PCB with the Mercury+ KX2(160T-2) FPGA board
#
#   VCC_IO
#   ------
#   Bank 12: VCCO_12        1.0 - 3.3 V
#   Bank 13: VCCO_13        1.0 - 3.3 V
#   Bank 14: VCCO_0/VCCO_14 1.8 - 2.5 V     ETH-PHY
#   Bank 15: VCCO_15        1.0 - 3.3 V
#   Bank 16: VCCO_16        1.8 - 3.3 V
#

# clock inputs
create_clock -period 10.000 -name clkin -add [get_ports clkin]

# internally generated clocks (PLL)
create_clock -period 8.000 -name rgmii_rxc -add [get_ports rgmii_rxc]

# derived clocks (clock dividers)
create_generated_clock -name i_cdr53bdaq_core/i_clock_divisor_i2c/I2C_CLK -source [get_pins PLLE2_BASE_inst/CLKOUT0] -divide_by 1500 [get_pins i_cdr53bdaq_core/i_clock_divisor_i2c/CLOCK_reg/Q]
create_generated_clock -name i_cdr53bdaq_core/i_clock_divisor_spi/SPI_CLK -source [get_pins PLLE2_BASE_inst/CLKOUT0] -divide_by 4 [get_pins i_cdr53bdaq_core/i_clock_divisor_spi/CLOCK_reg/Q]
create_generated_clock -name rgmii_txc -source [get_pins rgmii/ODDR_inst/C] -divide_by 1 [get_ports rgmii_txc]

set_property ASYNC_REG true [get_cells { sitcp/SiTCP/GMII/GMII_TXCNT/irMacPauseExe_0 sitcp/SiTCP/GMII/GMII_TXCNT/irMacPauseExe_1 }]
set_clock_groups -asynchronous -group [get_clocks {rgmii_rxc}] -group [get_clocks {CLK125PLLTX}]

set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK125PLLTX]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks i_cdr53bdaq_core/i_clock_divisor_i2c/I2C_CLK]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks i_cdr53bdaq_core/i_clock_divisor_spi/SPI_CLK]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks rgmii_rxc]
set_false_path -from [get_clocks rgmii_rxc] -to [get_clocks BUS_CLK_PLL]
set_false_path -from [get_clocks CLK125PLLTX] -to [get_clocks BUS_CLK_PLL]

#Oscillator 100MHz
set_property PACKAGE_PIN AA4 [get_ports clkin]
set_property IOSTANDARD LVCMOS15 [get_ports clkin]

#Oscillator 200MHz
#set_property PACKAGE_PIN AC11 [get_ports CLK200_N]
#set_property PACKAGE_PIN AB11 [get_ports CLK200_P]
#set_property IOSTANDARD LVDS [get_ports CLK200_*]

#CLK Mux
#set_property PACKAGE_PIN D23 [get_ports CLK_SEL]
#set_property IOSTANDARD LVCMOS33 [get_ports CLK_SEL]
#set_property PULLUP true [get_ports CLK_SEL]

#Reset push button
set_property PACKAGE_PIN G9 [get_ports RESET_BUTTON]
set_property IOSTANDARD LVCMOS25 [get_ports RESET_BUTTON]
set_property PULLUP true [get_ports RESET_BUTTON]

#USER push button
#set_property PACKAGE_PIN Y26 [get_ports USER_BUTTON]
#set_property IOSTANDARD LVCMOS25 [get_ports USER_BUTTON]
#set_property PULLUP true [get_ports USER_BUTTON]

#SITCP
set_property SLEW FAST [get_ports mdio_phy_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_phy_mdc]
set_property PACKAGE_PIN B25 [get_ports mdio_phy_mdc]

set_property SLEW FAST [get_ports mdio_phy_mdio]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_phy_mdio]
set_property PACKAGE_PIN B26 [get_ports mdio_phy_mdio]

set_property SLEW FAST [get_ports phy_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports phy_rst_n]
#M20 is routed to Connector C. The Ethernet PHY on th KX2 board has NO reset connection to an FPGA pin
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

# Aurora related signals
#set_property PACKAGE_PIN H5 [get_ports MGT_REFCLK0_N]
#set_property PACKAGE_PIN H6 [get_ports MGT_REFCLK0_P]
#set_property PACKAGE_PIN K6 [get_ports MGT_REFCLK1_P]
#set_property PACKAGE_PIN K5 [get_ports MGT_REFCLK1_N]

#set_property PACKAGE_PIN R4 [get_ports {MGT_RX_P[0]}]
#set_property PACKAGE_PIN R3 [get_ports {MGT_RX_N[0]}]
#set_property PACKAGE_PIN N4 [get_ports {MGT_RX_P[1]}]
#set_property PACKAGE_PIN N3 [get_ports {MGT_RX_N[1]}]
#set_property PACKAGE_PIN L4 [get_ports {MGT_RX_P[2]}]
#set_property PACKAGE_PIN L3 [get_ports {MGT_RX_N[2]}]
#set_property PACKAGE_PIN J4 [get_ports {MGT_RX_P[3]}]
#set_property PACKAGE_PIN J3 [get_ports {MGT_RX_N[3]}]
#set_property PACKAGE_PIN G3 [get_ports {MGT_RX_N[4]}]
#set_property PACKAGE_PIN G4 [get_ports {MGT_RX_P[4]}]
#set_property PACKAGE_PIN E4 [get_ports {MGT_RX_P[5]}]
#set_property PACKAGE_PIN E3 [get_ports {MGT_RX_N[5]}]
#set_property PACKAGE_PIN C4 [get_ports {MGT_RX_P[6]}]
#set_property PACKAGE_PIN C3 [get_ports {MGT_RX_N[6]}]
#set_property PACKAGE_PIN B6 [get_ports {MGT_RX_P[7]}]
#set_property PACKAGE_PIN B5 [get_ports {MGT_RX_N[7]}]

# DP_ML ("DP2") connected to SelectIOs
#set_property PACKAGE_PIN A18 [get_ports DP_GPIO_LANE0_P]
#set_property PACKAGE_PIN A19 [get_ports DP_GPIO_LANE0_N]
#set_property PACKAGE_PIN C19 [get_ports DP_GPIO_LANE1_P]
#set_property PACKAGE_PIN B19 [get_ports DP_GPIO_LANE1_N]
#set_property PACKAGE_PIN E18 [get_ports DP_GPIO_LANE2_P]
#set_property PACKAGE_PIN D18 [get_ports DP_GPIO_LANE2_N]
#set_property PACKAGE_PIN B17 [get_ports DP_GPIO_LANE3_P]
#set_property PACKAGE_PIN A17 [get_ports DP_GPIO_LANE3_N]
#set_property IOSTANDARD LVDS_25 [get_ports DP_GPIO_LANE*]
#set_property PACKAGE_PIN C16 [get_ports DP_GPIO_AUX_P]
#set_property PACKAGE_PIN B16 [get_ports DP_GPIO_AUX_N]
#set_property IOSTANDARD LVDS_25 [get_ports DP_GPIO_AUX*]

# DP_ML ("DP1") connected to MGTs
#set_property PACKAGE_PIN H19 [get_ports DP_ML_AUX_P]
#set_property PACKAGE_PIN G20 [get_ports DP_ML_AUX_N]
#set_property IOSTANDARD LVDS_25 [get_ports DP_ML_AUX*]

# DP_SL ("DP2..4") connected to MGTs
# DP_SL0: B124, B126; DP_SL1: B130, B132; DP_SL2: B136, B138
#set_property PACKAGE_PIN C17 [get_ports {DP_SL_AUX_P[2]}]
#set_property PACKAGE_PIN C18 [get_ports {DP_SL_AUX_N[2]}]
#set_property PACKAGE_PIN G17 [get_ports {DP_SL_AUX_P[1]}]
#set_property PACKAGE_PIN F18 [get_ports {DP_SL_AUX_N[1]}]
#set_property PACKAGE_PIN D19 [get_ports {DP_SL_AUX_P[0]}]
#set_property PACKAGE_PIN D20 [get_ports {DP_SL_AUX_N[0]}]
#set_property IOSTANDARD LVDS_25 [get_ports DP_SL_AUX*]

# Displayport RESET signals 0:DP1, 1:DP3, 2:DP4, 3:DP5, 4:mDP
#set_property PACKAGE_PIN G10 [get_ports {GPIO_RESET[4]}]
#set_property PACKAGE_PIN K18 [get_ports {GPIO_RESET[3]}]
#set_property PACKAGE_PIN L17 [get_ports {GPIO_RESET[2]}]
#set_property PACKAGE_PIN H11 [get_ports {GPIO_RESET[1]}]
#set_property PACKAGE_PIN H12 [get_ports {GPIO_RESET[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_RESET*]
#set_property PULLUP TRUE [get_ports GPIO_RESET*]

# Displayport VDD_SENSE signals 0:DP1, 1:DP3, 2:DP4, 3:DP5
#set_property PACKAGE_PIN V22 [get_ports {GPIO_SENSE[3]}]
#set_property PACKAGE_PIN W23 [get_ports {GPIO_SENSE[2]}]
#set_property PACKAGE_PIN W24 [get_ports {GPIO_SENSE[1]}]
#set_property PACKAGE_PIN AD26 [get_ports {GPIO_SENSE[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_SENSE*]
#set_property PULLUP TRUE [get_ports GPIO_SENSE*]

# Debug LEDs
#LED 0..3 are onboard LEDs: Bank 32, 33 running at 1.5 V)
set_property PACKAGE_PIN U9 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[0]}]
set_property PACKAGE_PIN V12 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[1]}]
set_property PACKAGE_PIN V13 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[2]}]
set_property PACKAGE_PIN W13 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[3]}]
#LED 4..7 are LEDs on the BDAQ53 base board. They have pull-ups to 1.8 V.
set_property PACKAGE_PIN E21 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN E22 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN D21 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN C22 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property SLEW SLOW [get_ports LED*]

#set_property PACKAGE_PIN AB21 [get_ports LEMO_TX0]
#set_property PACKAGE_PIN AD25 [get_ports LEMO_TX1]
#set_property IOSTANDARD LVCMOS25 [get_ports LEMO_TX*]
#set_property SLEW FAST [get_ports LEMO_TX*]

## PMOD
##  ____________
## |1 2 3 4  G +|  First PMOD channel (4 signal lines, ground and vcc)
## |7_8_9_10_G_+|  Second PMOD channel ("")
##
## PMOD connector PMOD10-->PMOD0; PMOD9-->PMOD1; PMOD8-->PMOD2; PMOD7-->PMOD3;
#set_property PACKAGE_PIN AC23 [get_ports {PMOD[0]}]
#set_property PACKAGE_PIN AC24 [get_ports {PMOD[1]}]
#set_property PACKAGE_PIN W25 [get_ports {PMOD[2]}]
#set_property PACKAGE_PIN W26 [get_ports {PMOD[3]}]
## PMOD connector PMOD4-->PMOD4; PMOD3-->PMOD5; PMOD2-->PMOD6; PMOD1-->PMOD7;
#set_property PACKAGE_PIN U26 [get_ports {PMOD[4]}]
#set_property PACKAGE_PIN V26 [get_ports {PMOD[5]}]
#set_property PACKAGE_PIN AE25 [get_ports {PMOD[6]}]
#set_property PACKAGE_PIN AD24 [get_ports {PMOD[7]}]
#set_property IOSTANDARD LVCMOS25 [get_ports PMOD*]
## pull down the PMOD pins which are used as inputs
#set_property PULLDOWN true [get_ports {PMOD[0]}]
#set_property PULLDOWN true [get_ports {PMOD[1]}]
#set_property PULLDOWN true [get_ports {PMOD[2]}]
#set_property PULLDOWN true [get_ports {PMOD[3]}]

# I2C pins
set_property PACKAGE_PIN L23 [get_ports I2C_SCL]
set_property PACKAGE_PIN C24 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports I2C_*]
set_property SLEW SLOW [get_ports I2C_*]

# EEPROM (SPI for SiTCP)
set_property PACKAGE_PIN A20 [get_ports EEPROM_CS]
set_property PACKAGE_PIN B20 [get_ports EEPROM_SK]
set_property PACKAGE_PIN A24 [get_ports EEPROM_DI]
set_property PACKAGE_PIN A23 [get_ports EEPROM_DO]
set_property IOSTANDARD LVCMOS33 [get_ports EEPROM_*]

# SPI configuration flash
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

# TLU
#set_property PACKAGE_PIN AE23 [get_ports RJ45_TRIGGER]
#set_property PACKAGE_PIN U22 [get_ports RJ45_RESET]
#set_property IOSTANDARD LVCMOS25 [get_ports RJ45_RESET]
#set_property IOSTANDARD LVCMOS25 [get_ports RJ45_TRIGGER]
