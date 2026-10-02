`timescale 1ps / 1ps

module test_SimDelayControl #(
    parameter StoppedLevel = 0
);
    reg c;
    reg r;
    wire ready;

    IDELAYCTRL dut (
        .RDY   (ready),
        .REFCLK(c),
        .RST   (r)
    );
endmodule
