# Recreate and build this example; generated files stay under build/fpga.
# --check validates input paths without running vendor tools.
# --project-only creates the project without synthesis or implementation.
set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ../../..]]
set build_dir [file join $repo_dir build fpga MIO]
set top example

if {$argc > 1 || ($argc == 1 && [lsearch -exact {--check --project-only} $argv] < 0)} {
    error "Usage: run.tcl ?--check|--project-only?"
}
set sources [list \
    [file join $repo_dir examples/MIO/src/example.v] \
    [file join $repo_dir examples/MIO/src/mio.ucf] \
    [file join $repo_dir basil/firmware/modules/utils/reset_gen.v] \
    [file join $repo_dir basil/firmware/modules/utils/bus_to_ip.v] \
    [file join $repo_dir basil/firmware/modules/gpio/gpio.v] \
    [file join $repo_dir basil/firmware/modules/utils/fx2_to_bus.v] \
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
file delete -force example.xise example.gise
project new example.xise
project set family Spartan3
project set device xc3s1000
project set package fg320
project set speed -4
foreach source $sources {
    xfile add $source
}
project set top $top
project set "Verilog Include Directories" [join [list $modules_dir [file join $modules_dir utils]] "|"]

if {$argv ne "--project-only"} {
    if {![process run "Generate Programming File"]} {
        error "FPGA build failed; see the logs under $build_dir"
    }
}
project close
exit 0
