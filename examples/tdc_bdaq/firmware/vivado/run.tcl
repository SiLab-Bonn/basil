
# -----------------------------------------------------------
# Copyright (c) SILAB , Physics Institute, University of Bonn
# -----------------------------------------------------------
#
#   This script creates Vivado projects and bitfiles for the supported hardware platforms
#
#   vivado -mode tcl -source run.tcl
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

set basil_dir [exec python -c "import basil, os; print(str(os.path.dirname(basil.__file__)))"]
set include_dirs [list $basil_dir/firmware/modules $basil_dir/firmware/modules/utils]

file mkdir output reports


proc read_design_files {} {
    read_verilog ../src/tdc_bdaq.v

    read_edif ../SiTCP/SiTCP_XC7K_32K_BBT_V110.ngc
    read_verilog ../SiTCP/TIMER.v
    read_verilog ../SiTCP/SiTCP_XC7K_32K_BBT_V110.V
    read_verilog ../SiTCP/WRAP_SiTCP_GMII_XC7K_32K.V
}


proc run_bit { part board xdc_file size option} {
    set prjname $board$option\_TDL_TDC

    create_project -force -part $part $prjname designs
    read_design_files
    read_xdc $xdc_file
    read_xdc ../src/tdc_bdaq.xdc
    read_xdc ../src/SiTCP.xdc

    global include_dirs

    synth_design -top tdc_bdaq -include_dirs $include_dirs -verilog_define "$board=1" -verilog_define "SYNTHESIS=1" -verilog_define "$option=1"
    opt_design
    place_design
    phys_opt_design
    route_design
    report_utilization -file "reports/report_utilization_$prjname.log"
    report_timing -file "reports/report_timing_$prjname.log"
    write_bitstream -force -file output/$prjname
    write_cfgmem -format mcs -size $size -interface SPIx4 -loadbit "up 0x0 output/$prjname.bit" -force -file output/$prjname
    close_project

    exec tar -C ./output -cvzf output/$prjname.tar.gz $prjname.bit $prjname.mcs
}


# Create projects and bitfiles

#       FPGA type           board name  constraints file    flash size  option
run_bit xc7k160tffg676-2    BDAQ53      ../src/bdaq53.xdc   64          ""

exit
