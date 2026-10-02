
# -----------------------------------------------------------
# Copyright (c) SILAB , Physics Institute, University of Bonn
# -----------------------------------------------------------
#
#   This script creates Vivado projects and bitfiles for the supported hardware platforms
#
#   Start vivado in tcl mode by typing:
#       Run Vivado from build/fpga/bdaq53 with this script as an absolute -source path.
#

# Use current environment python instead of vivado included python
if {[info exists ::env(PYTHONPATH)]} {
    unset ::env(PYTHONPATH)
}
if {[info exists ::env(PYTHONHOME)]} {
    unset ::env(PYTHONHOME)
}
# Get rid of Vivado python (since Vivado 2021) in PATH and use python from calling shell
set env(PATH) [join [lsearch -inline -all -not -regexp [split $::env(PATH) ":"] (.*)lnx64\/python(.*)] ":"]

# Resolve inputs before moving all generated output into the repository build tree.
set firmware_dir [file dirname [file dirname [file normalize [info script]]]]
set repo_dir [file normalize [file join $firmware_dir ../../..]]
set build_dir [file join $repo_dir build fpga bdaq53]
file mkdir $build_dir
cd $build_dir

set basil_dir [exec python -c "import basil, os; print(str(os.path.dirname(basil.__file__)))"]
set include_dirs [list $basil_dir/firmware/modules $basil_dir/firmware/modules/utils]

file mkdir output reports


proc read_design_files {} {
    global firmware_dir
    read_verilog $firmware_dir/src/bdaq53_eth.v
    read_verilog $firmware_dir/src/bdaq53_eth_core.v

    read_edif $firmware_dir/SiTCP/SiTCP_XC7K_32K_BBT_V110.ngc
    read_verilog $firmware_dir/SiTCP/TIMER.v
    read_verilog $firmware_dir/SiTCP/SiTCP_XC7K_32K_BBT_V110.V
    read_verilog $firmware_dir/SiTCP/WRAP_SiTCP_GMII_XC7K_32K.V
}


proc run_bit { part board connector xdc_file size option} {
    global firmware_dir
    create_project -force -part $part $board$option$connector designs

    read_design_files
    read_xdc $xdc_file
    read_xdc $firmware_dir/src/SiTCP.xdc

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
run_bit xc7k160tffg676-2    BDAQ53      ""          $firmware_dir/src/bdaq53.xdc       64        ""


exit
