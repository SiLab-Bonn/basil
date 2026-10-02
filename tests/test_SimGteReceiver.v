`timescale 1ps / 1ps

module test_SimGteReceiver;
    reg i;
    reg ib;
    reg ceb;
    wire o;
    wire divided;

    IBUFDS_GTE2 dut (
        .O    (o),
        .ODIV2(divided),
        .I    (i),
        .IB   (ib),
        .CEB  (ceb)
    );
endmodule
