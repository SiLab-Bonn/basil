# Recreate and build this example; generated files stay under build/fpga.
# --check validates input paths without running vendor tools.
# --project-only creates the project without synthesis or implementation.
set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ../../../..]]
set build_dir [file join $repo_dir build fpga lx9]
set top top

if {$argc > 1 || ($argc == 1 && [lsearch -exact {--check --project-only} $argv] < 0)} {
    error "Usage: run.tcl ?--check|--project-only?"
}
set sources [list \
    [file join $repo_dir examples/lx9/device/src/top.v] \
    [file join $repo_dir examples/lx9/device/src/SiTCP/WRAP_SiTCP_GMII_XC6S_16K.V] \
    [file join $repo_dir examples/lx9/device/src/SiTCP/SiTCP_XC6S_16K_BBT_V80.ngc] \
    [file join $repo_dir examples/lx9/device/src/SiTCP/SiTCP_XC6S_16K_BBT_V80.V] \
    [file join $repo_dir basil/firmware/modules/utils/rbcp_to_bus.v] \
    [file join $repo_dir basil/firmware/modules/gpio/gpio.v] \
    [file join $repo_dir basil/firmware/modules/utils/bus_to_ip.v] \
    [file join $repo_dir examples/lx9/device/src/top.ucf] \
    [file join $repo_dir basil/firmware/modules/seq_gen/seq_gen_core.v] \
    [file join $repo_dir basil/firmware/modules/seq_gen/seq_gen.v] \
    [file join $repo_dir basil/firmware/modules/utils/cdc_pulse_sync.v] \
    [file join $repo_dir basil/firmware/modules/utils/generic_fifo.v] \
    [file join $repo_dir basil/firmware/modules/rrp_arbiter/rrp_arbiter.v] \
    [file join $repo_dir basil/firmware/modules/fast_spi_rx/fast_spi_rx_core.v] \
    [file join $repo_dir basil/firmware/modules/fast_spi_rx/fast_spi_rx.v] \
    [file join $repo_dir basil/firmware/modules/utils/cdc_syncfifo.v] \
    [file join $repo_dir basil/firmware/modules/utils/fifo_32_to_8.v] \
    [file join $repo_dir examples/lx9/device/src/SiTCP/TIMER.v] \
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

# Recreate only the generated project database; source files are never copied.
file delete -force lx9.xise lx9.gise
project new lx9.xise
project set family Spartan6
project set device xc6slx9
project set package csg324
project set speed -2
foreach source $sources {
    xfile add $source
}
project set top $top
project set "Verilog Include Directories" [join [list $modules_dir [file join $modules_dir utils]] "|"]
project set {Enable Internal Done Pipe} {true}
project set {Extra Effort (Highest PAR level only)} {Normal}
project set {Optimization Effort spartan6} {High}
project set {Pack I/O Registers into IOBs} {Yes}
project set {Pack I/O Registers/Latches into IOBs} {For Inputs and Outputs}
project set {Placer Extra Effort Map} {Normal}
project set {Register Balancing} {Yes}
project set {Max Fanout} {100000}

if {$argv ne "--project-only"} {
    if {![process run "Generate Programming File"]} {
        error "FPGA build failed; see the logs under $build_dir"
    }
}
project close
exit 0
