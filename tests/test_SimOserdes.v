`timescale 1ns / 1ps

module test_SimOserdes #(
    parameter         DataRate  = "DDR",
    parameter integer DataWidth = 8,
    parameter         Invert    = 1'b0,
    parameter integer DivPhase  = 0
);
    reg clk;
    reg clkdiv;
    reg reset;
    reg enable;
    reg [9:0] data;
    wire serial_data;
    wire shift1;
    wire shift2;

    OSERDESE2 #(
        .DATA_RATE_OQ      (DataRate),
        .DATA_WIDTH        (DataWidth),
        .DATA_RATE_TQ      ("SDR"),
        .TRISTATE_WIDTH    (1),
        .IS_CLK_INVERTED   (Invert),
        .IS_CLKDIV_INVERTED(Invert),
        .IS_D1_INVERTED    (Invert)
    ) dut (
        .CLK      (clk ^ Invert),
        .CLKDIV   (clkdiv ^ Invert),
        .RST      (reset),
        .OCE      (enable),
        .D1       (data[0] ^ Invert),
        .D2       (data[1]),
        .D3       (data[2]),
        .D4       (data[3]),
        .D5       (data[4]),
        .D6       (data[5]),
        .D7       (data[6]),
        .D8       (data[7]),
        .SHIFTIN1 (shift1),
        .SHIFTIN2 (shift2),
        .T1       (1'b0),
        .T2       (1'b0),
        .T3       (1'b0),
        .T4       (1'b0),
        .TCE      (1'b0),
        .TBYTEIN  (1'b0),
        .OQ       (serial_data),
        .OFB      (),
        .TQ       (),
        .TFB      (),
        .TBYTEOUT (),
        .SHIFTOUT1(),
        .SHIFTOUT2()
    );

    generate
        if (DataWidth == 10) begin : g_cascade
            OSERDESE2 #(
                .DATA_RATE_OQ  ("DDR"),
                .DATA_WIDTH    (10),
                .SERDES_MODE   ("SLAVE"),
                .DATA_RATE_TQ  ("SDR"),
                .TRISTATE_WIDTH(1)
            ) slave (
                .CLK      (clk),
                .CLKDIV   (clkdiv),
                .RST      (reset),
                .OCE      (enable),
                .D1       (1'b0),
                .D2       (1'b0),
                .D3       (data[8]),
                .D4       (data[9]),
                .D5       (1'b0),
                .D6       (1'b0),
                .D7       (1'b0),
                .D8       (1'b0),
                .SHIFTIN1 (1'b0),
                .SHIFTIN2 (1'b0),
                .T1       (1'b0),
                .T2       (1'b0),
                .T3       (1'b0),
                .T4       (1'b0),
                .TCE      (1'b0),
                .TBYTEIN  (1'b0),
                .SHIFTOUT1(shift1),
                .SHIFTOUT2(shift2),
                .OQ       (),
                .OFB      (),
                .TQ       (),
                .TFB      (),
                .TBYTEOUT ()
            );
        end else begin : g_no_cascade
            assign shift1 = 1'b0;
            assign shift2 = 1'b0;
        end
    endgenerate

endmodule
