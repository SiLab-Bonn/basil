# Recreate and build this example; generated files stay under build/fpga.
# --check validates input paths without running vendor tools.
# --project-only creates the project without synthesis or implementation.
set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ../../../..]]
set build_dir [file join $repo_dir build fpga mio_pixel]
set top pixel

if {$argc > 1 || ($argc == 1 && [lsearch -exact {--check --project-only} $argv] < 0)} {
    error "Usage: run.tcl ?--check|--project-only?"
}
set sources [list \
    [file join $repo_dir examples/mio_pixel/firmware/src/clk_gen.v] \
    [file join $repo_dir examples/mio_pixel/firmware/src/pixel.ucf] \
    [file join $repo_dir examples/mio_pixel/firmware/src/pixel.v] \
    [file join $repo_dir basil/firmware/modules/seq_gen/seq_gen.v] \
    [file join $repo_dir basil/firmware/modules/seq_gen/seq_gen_core.v] \
    [file join $repo_dir basil/firmware/modules/fast_spi_rx/fast_spi_rx.v] \
    [file join $repo_dir basil/firmware/modules/fast_spi_rx/fast_spi_rx_core.v] \
    [file join $repo_dir basil/firmware/modules/rrp_arbiter/rrp_arbiter.v] \
    [file join $repo_dir basil/firmware/modules/sram_fifo/sram_fifo.v] \
    [file join $repo_dir basil/firmware/modules/sram_fifo/sram_fifo_core.v] \
    [file join $repo_dir basil/firmware/modules/tdc_s3/tdc_s3.v] \
    [file join $repo_dir basil/firmware/modules/tdc_s3/tdc_s3_core.v] \
    [file join $repo_dir basil/firmware/modules/utils/generic_fifo.v] \
    [file join $repo_dir basil/firmware/modules/utils/reset_gen.v] \
    [file join $repo_dir basil/firmware/modules/utils/bus_to_ip.v] \
    [file join $repo_dir basil/firmware/modules/utils/cdc_syncfifo.v] \
    [file join $repo_dir basil/firmware/modules/utils/cdc_pulse_sync.v] \
    [file join $repo_dir basil/firmware/modules/utils/flag_domain_crossing.v] \
    [file join $repo_dir basil/firmware/modules/utils/three_stage_synchronizer.v] \
    [file join $repo_dir basil/firmware/modules/gpio/gpio.v] \
    [file join $repo_dir basil/firmware/modules/utils/ddr_des.v] \
    [file join $repo_dir basil/firmware/modules/utils/IDDR_s3.v] \
    [file join $repo_dir basil/firmware/modules/utils/fx2_to_bus.v] \
    [file join $repo_dir basil/firmware/modules/utils/ODDR_s3.v] \
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
file delete -force pixel.xise pixel.gise
project new pixel.xise
project set family Spartan3
project set device xc3s1000
project set package fg320
project set speed -5
foreach source $sources {
    xfile add $source
}
project set top $top
project set "Verilog Include Directories" [join [list $modules_dir [file join $modules_dir utils]] "|"]
project set {Enable Internal Done Pipe} {true}
project set {Extra Effort (Highest PAR level only)} {None}
project set {Pack I/O Registers into IOBs} {Auto}
project set {Pack I/O Registers/Latches into IOBs} {Off}
project set {Register Balancing} {No}
project set {Max Fanout} {100000}

if {$argv ne "--project-only"} {
    if {![process run "Generate Programming File"]} {
        error "FPGA build failed; see the logs under $build_dir"
    }
}
project close
exit 0
