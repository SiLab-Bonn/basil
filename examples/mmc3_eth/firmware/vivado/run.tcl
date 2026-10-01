# Recreate and build this example; generated files stay under build/fpga.
# --check validates input paths without running vendor tools.
# --project-only creates the project without synthesis or implementation.
set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ../../../..]]
set build_dir [file join $repo_dir build fpga mmc3_eth]
set top mmc3_eth_throughput_test

if {$argc > 1 || ($argc == 1 && [lsearch -exact {--check --project-only} $argv] < 0)} {
    error "Usage: run.tcl ?--check|--project-only?"
}
set sources [list \
    [file join $repo_dir examples/mmc3_eth/firmware/src/SiTCP/SiTCP_XC7K_32K_BBT_V110.edf] \
    [file join $repo_dir examples/mmc3_eth/firmware/src/SiTCP/SiTCP_XC7K_32K_BBT_V110.V] \
    [file join $repo_dir examples/mmc3_eth/firmware/src/SiTCP/TIMER.v] \
    [file join $repo_dir examples/mmc3_eth/firmware/src/SiTCP/WRAP_SiTCP_GMII_XC7K_32K.V] \
    [file join $repo_dir basil/firmware/modules/utils/bus_to_ip.v] \
    [file join $repo_dir basil/firmware/modules/gpio/gpio.v] \
    [file join $repo_dir examples/mmc3_eth/firmware/src/mmc3_eth_core.v] \
    [file join $repo_dir basil/firmware/modules/utils/rbcp_to_bus.v] \
    [file join $repo_dir basil/firmware/modules/utils/rgmii_io.v] \
    [file join $repo_dir examples/mmc3_eth/firmware/src/mmc3_eth.v] \
    [file join $repo_dir examples/mmc3_eth/firmware/src/mmc3.xdc] \
]
foreach source $sources {
    if {![file isfile $source]} {
        error "Missing input: $source (see docs/fpga_builds.rst for required vendor inputs)"
    }
}
if {$argv eq "--check"} {
    puts "Input paths verified for $top"
    exit 0
}

file mkdir $build_dir
cd $build_dir
set modules_dir [file join $repo_dir basil firmware modules]

create_project -force $top [file join $build_dir project] -part xc7k160tfbg676-1
set_property include_dirs [list $modules_dir [file join $modules_dir utils]] [current_fileset]
set constraints {}
foreach source $sources {
    if {[file extension $source] eq ".xdc"} {
        lappend constraints $source
    } else {
        add_files -norecurse $source
    }
}
add_files -fileset constrs_1 -norecurse $constraints
set_property top $top [current_fileset]
update_compile_order -fileset sources_1

if {$argv ne "--project-only"} {
    launch_runs synth_1
    wait_on_run synth_1
    if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
        error "Synthesis failed; see the run logs under $build_dir"
    }
    launch_runs impl_1 -to_step write_bitstream
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
        error "Implementation failed; see the run logs under $build_dir"
    }
    file mkdir output
    file copy -force [file join [get_property DIRECTORY [get_runs impl_1]] $top.bit] output/
}
close_project
exit 0
