`timescale 1ns / 1ps

module test_SimIddr #(
    parameter       EdgeMode    = "OPPOSITE_EDGE",
    parameter       ResetType   = "SYNC",
    parameter [0:0] Init1       = 1'b0,
    parameter [0:0] Init2       = 1'b0,
    parameter [0:0] InvertClock = 1'b0,
    parameter [0:0] InvertData  = 1'b0
);
    reg clock;
    reg enable;
    reg data;
    reg reset;
    reg set_value;
    wire q1;
    wire q2;

    IDDR #(
        .DDR_CLK_EDGE (EdgeMode),
        .INIT_Q1      (Init1),
        .INIT_Q2      (Init2),
        .IS_C_INVERTED(InvertClock),
        .IS_D_INVERTED(InvertData),
        .SRTYPE       (ResetType)
    ) dut (
        .Q1(q1),
        .Q2(q2),
        .C (clock ^ InvertClock),
        .CE(enable),
        .D (data ^ InvertData),
        .R (reset),
        .S (set_value)
    );

endmodule

// verilog_lint: waive module-filename
module test_SimOddr #(
    parameter       EdgeMode    = "OPPOSITE_EDGE",
    parameter       ResetType   = "SYNC",
    parameter [0:0] Init        = 1'b0,
    parameter [0:0] InvertClock = 1'b0,
    parameter [0:0] InvertData1 = 1'b0,
    parameter [0:0] InvertData2 = 1'b0
);
    reg clock;
    reg enable;
    reg data1;
    reg data2;
    reg reset;
    reg set_value;
    wire q;

    ODDR #(
        .DDR_CLK_EDGE  (EdgeMode),
        .INIT          (Init),
        .SRTYPE        (ResetType),
        .IS_C_INVERTED (InvertClock),
        .IS_D1_INVERTED(InvertData1),
        .IS_D2_INVERTED(InvertData2)
    ) dut (
        .Q (q),
        .C (clock ^ InvertClock),
        .CE(enable),
        .D1(data1 ^ InvertData1),
        .D2(data2 ^ InvertData2),
        .R (reset),
        .S (set_value)
    );

endmodule
