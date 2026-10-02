# Recreate and build this example; generated files stay under build/fpga.
# --check validates input paths without running vendor tools.
# --project-only creates the project without synthesis or implementation.
set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ../..]]
set build_dir [file join $repo_dir build fpga MMC3]
set top mmc3_top

if {$argc > 1 || ($argc == 1 && [lsearch -exact {--check --project-only} $argv] < 0)} {
    error "Usage: run.tcl ?--check|--project-only?"
}
set sources [list \
    [file join $repo_dir basil/firmware/modules/utils/flag_domain_crossing.v] \
    [file join $repo_dir basil/firmware/modules/fei4_rx/sync_master.v] \
    [file join $repo_dir basil/firmware/modules/fei4_rx/rec_sync.v] \
    [file join $repo_dir basil/firmware/modules/fei4_rx/decode_8b10b.v] \
    [file join $repo_dir basil/firmware/modules/utils/cdc_syncfifo.v] \
    [file join $repo_dir basil/firmware/modules/utils/generic_fifo.v] \
    [file join $repo_dir basil/firmware/modules/fei4_rx/receiver_logic.v] \
    [file join $repo_dir basil/firmware/modules/utils/cdc_pulse_sync.v] \
    [file join $repo_dir basil/firmware/modules/utils/three_stage_synchronizer.v] \
    [file join $repo_dir basil/firmware/modules/fei4_rx/fei4_rx_core.v] \
    [file join $repo_dir basil/firmware/modules/cmd_seq/cmd_seq_core.v] \
    [file join $repo_dir basil/firmware/modules/utils/bus_to_ip.v] \
    [file join $repo_dir basil/firmware/modules/bram_fifo/bram_fifo_core.v] \
    [file join $repo_dir basil/firmware/modules/gpio/gpio.v] \
    [file join $repo_dir basil/firmware/modules/fx3_if/FX3_IF.v] \
    [file join $repo_dir basil/firmware/modules/fei4_rx/fei4_rx.v] \
    [file join $repo_dir basil/firmware/modules/cmd_seq/cmd_seq.v] \
    [file join $repo_dir basil/firmware/modules/bram_fifo/bram_fifo.v] \
    [file join $repo_dir examples/MMC3/src/mmc3_top.v] \
    [file join $repo_dir examples/MMC3/src/mmc3.xdc] \
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
