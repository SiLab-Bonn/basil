`timescale 1ps / 1ps

module test_SimDdrTrace #(
    parameter       EdgeMode  = "OPPOSITE_EDGE",
    parameter       ResetType = "SYNC",
    parameter [0:0] Invert    = 1'b0
);
    reg c;
    reg ce;
    reg d1;
    reg d2;
    reg r;
    reg s;
    wire q1;
    wire q2;
    wire q;

    IDDR #(
        .DDR_CLK_EDGE (EdgeMode),
        .SRTYPE       (ResetType),
        .INIT_Q1      (1),
        .INIT_Q2      (0),
        .IS_C_INVERTED(Invert),
        .IS_D_INVERTED(Invert)
    ) iddr (
        .Q1(q1),
        .Q2(q2),
        .C (c),
        .CE(ce),
        .D (d1),
        .R (r),
        .S (s)
    );
    ODDR #(
        .DDR_CLK_EDGE  (Invert ? "SAME_EDGE" : "OPPOSITE_EDGE"),
        .SRTYPE        (ResetType),
        .INIT          (1),
        .IS_C_INVERTED (Invert),
        .IS_D1_INVERTED(Invert),
        .IS_D2_INVERTED(Invert)
    ) oddr (
        .Q (q),
        .C (c),
        .CE(ce),
        .D1(d1),
        .D2(d2),
        .R (r),
        .S (s)
    );
endmodule
