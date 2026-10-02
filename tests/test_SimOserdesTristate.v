`timescale 1ns / 1ps

module test_SimOserdesTristate #(
    parameter         DataRate      = "SDR",
    parameter integer DataWidth     = 4,
    parameter         TristateRate  = "DDR",
    parameter integer TristateWidth = 4,
    parameter         SerdesMode    = "MASTER",
    parameter         ByteControl   = "FALSE",
    parameter         ByteSource    = "FALSE"
);
    reg clk;
    reg clkdiv;
    reg reset;
    reg enable;
    reg [3:0] tristate_data;
    wire tq;
    wire tfb;
    wire byte_output;
    wire oq;

    OSERDESE2 #(
        .DATA_RATE_OQ  (DataRate),
        .DATA_WIDTH    (DataWidth),
        .DATA_RATE_TQ  (TristateRate),
        .TRISTATE_WIDTH(TristateWidth),
        .SERDES_MODE   (SerdesMode),
        .TBYTE_CTL     (ByteControl),
        .TBYTE_SRC     (ByteSource),
        .IS_T1_INVERTED(1)
    ) dut (
        .CLK      (clk),
        .CLKDIV   (clkdiv),
        .RST      (reset),
        .OCE      (1'b0),
        .D1       (1'b0),
        .D2       (1'b0),
        .D3       (1'b0),
        .D4       (1'b0),
        .D5       (1'b0),
        .D6       (1'b0),
        .D7       (1'b0),
        .D8       (1'b0),
        .SHIFTIN1 (1'b0),
        .SHIFTIN2 (1'b0),
        .T1       (!tristate_data[0]),
        .T2       (tristate_data[1]),
        .T3       (tristate_data[2]),
        .T4       (tristate_data[3]),
        .TCE      (enable),
        .TBYTEIN  (1'b0),
        .TQ       (tq),
        .TFB      (tfb),
        .OQ       (oq),
        .OFB      (),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .TBYTEOUT (byte_output)
    );

endmodule
