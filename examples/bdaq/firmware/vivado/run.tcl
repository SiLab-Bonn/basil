
# -----------------------------------------------------------
# Copyright (c) SILAB , Physics Institute, University of Bonn
# -----------------------------------------------------------
#
#   This script creates Vivado projects and bitfiles for the supported hardware platforms
#
#   Start vivado in tcl mode by typing:
#       vivado -mode tcl -source run.tcl
#


set basil_dir [exec python -c "import basil, os; print(str(os.path.dirname(basil.__file__)))"]
set include_dirs [list $basil_dir/firmware/modules $basil_dir/firmware/modules/utils]

file mkdir output reports


proc read_design_files {} {
    read_verilog ../src/bdaq53_eth.v
    read_verilog ../src/bdaq53_eth_core.v

    read_edif ../SiTCP/SiTCP_XC7K_32K_BBT_V110.ngc
    read_verilog ../SiTCP/TIMER.v
    read_verilog ../SiTCP/SiTCP_XC7K_32K_BBT_V110.V
    read_verilog ../SiTCP/WRAP_SiTCP_GMII_XC7K_32K.V
}


proc run_bit { part board connector xdc_file size option} {
    create_project -force -part $part $board$option$connector designs

    read_design_files
    read_xdc $xdc_file
    read_xdc ../src/SiTCP.xdc

    global include_dirs

    synth_design -top bdaq53_eth_throughput_test -include_dirs $include_dirs -verilog_define "$board=1" -verilog_define "$connector=1" -verilog_define "SYNTHESIS=1" -verilog_define "$option=1"
    opt_design
    place_design
    phys_opt_design
    route_design
    report_utilization
    report_timing -file "reports/report_timing.$board$option$connector.log"
    write_bitstream -force -file output/$board$option$connector
    write_cfgmem -format mcs -size $size -interface SPIx4 -loadbit "up 0x0 output/$board$option$connector.bit" -force -file output/$board$option$connector
    close_project

    exec tar -C ./output -cvzf output/$board$option$connector.tar.gz $board$option$connector.bit $board$option$connector.mcs
}


#########

#
# Create projects and bitfiles
#

#       FPGA type           board name	connector  	constraints file     flash size  option
run_bit xc7k160tffg676-2    BDAQ53      ""          ../src/bdaq53.xdc       64        ""


exit
