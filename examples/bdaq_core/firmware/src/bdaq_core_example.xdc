
create_clock -period 10.000 -name clkin -add [get_ports clkin]
create_clock -period 8.000 -name rgmii_rxc -add [get_ports rgmii_rxc]

set_false_path -from [get_clocks CLK125PLLTX] -to [get_clocks BUS_CLK_PLL]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks CLK125PLLTX]
set_false_path -from [get_clocks BUS_CLK_PLL] -to [get_clocks rgmii_rxc]
set_false_path -from [get_clocks rgmii_rxc] -to [get_clocks BUS_CLK_PLL]

#NET "Clk100"
set_property PACKAGE_PIN AA4 [get_ports clkin]
set_property IOSTANDARD LVCMOS15 [get_ports clkin]

set_property PACKAGE_PIN G9 [get_ports RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports RESET_N]
set_property PULLUP TRUE [get_ports RESET_N]

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

set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_rxd[0]"]
set_property PACKAGE_PIN H23 [get_ports "rgmii_rxd[0]"]
set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_rxd[1]"]
set_property PACKAGE_PIN H24 [get_ports "rgmii_rxd[1]"]
set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_rxd[2]"]
set_property PACKAGE_PIN J21 [get_ports "rgmii_rxd[2]"]
set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_rxd[3]"]
set_property PACKAGE_PIN H22 [get_ports "rgmii_rxd[3]"]

set_property SLEW FAST [get_ports rgmii_txc]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_txc]
set_property PACKAGE_PIN K23 [get_ports rgmii_txc]

set_property SLEW FAST [get_ports rgmii_tx_ctl]
set_property IOSTANDARD LVCMOS33 [get_ports rgmii_tx_ctl]
set_property PACKAGE_PIN J23 [get_ports rgmii_tx_ctl]

set_property SLEW FAST [get_ports "rgmii_txd[0]"]
set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_txd[0]"]
set_property PACKAGE_PIN J24 [get_ports "rgmii_txd[0]"]
set_property SLEW FAST [get_ports "rgmii_txd[1]"]
set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_txd[1]"]
set_property PACKAGE_PIN J25 [get_ports "rgmii_txd[1]"]
set_property SLEW FAST [get_ports "rgmii_txd[2]"]
set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_txd[2]"]
set_property PACKAGE_PIN L22 [get_ports "rgmii_txd[2]"]
set_property SLEW FAST [get_ports "rgmii_txd[3]"]
set_property IOSTANDARD LVCMOS33 [get_ports "rgmii_txd[3]"]
set_property PACKAGE_PIN K22 [get_ports "rgmii_txd[3]"]

# LEDs
#LED 0..3 are onboard LEDs
set_property PACKAGE_PIN U9 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[0]}]
set_property PACKAGE_PIN V12 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[1]}]
set_property PACKAGE_PIN V13 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[2]}]
set_property PACKAGE_PIN W13 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[3]}]
#LED 4..7 are LEDs on the BDAQ53 base board
set_property PACKAGE_PIN E21 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN E22 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN D21 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN C22 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property SLEW SLOW [get_ports LED*]

# SPI configuration flash
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
