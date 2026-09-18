`timescale 1ns / 1ps
`default_nettype none

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
    wire oq;
    integer bit_index;
    reg [3:0] expected;

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
        .TBYTEOUT ()
    );

    initial begin
        clk           = 1'b0;
        clkdiv        = 1'b0;
        reset         = 1'b1;
        enable        = 1'b0;
        tristate_data = 4'b0000;
        #40;
        if (TristateRate == "BUF") begin
            // BUF must work with both clocks stopped, TCE low and reset high.
            tristate_data = 4'b0001;
            #1;
            if ((tq !== 1'b1) || (tfb !== 1'b1)) begin
                $display("FAIL: BUF does not follow T1 asynchronously");
                $finish;
            end
            tristate_data = 4'b0000;
            #1;
            if (tq !== 1'b0) begin
                $display("FAIL: BUF does not follow falling T1");
                $finish;
            end
        end else begin
            reset         = 1'b0;
            enable        = 1'b1;
            tristate_data = 4'b1001;
            expected      = tristate_data;
            #5;
            clk    = 1'b1;
            clkdiv = 1'b1;
            #0.001;
            if (tq !== 1'b0) begin
                $display("FAIL: publication changed TQ on the capture edge");
                $finish;
            end
            // Input changes after capture must not change the captured word.
            tristate_data = 4'b0110;
            if (TristateRate == "DDR") begin
                for (bit_index = 0; bit_index < 4; bit_index = bit_index + 1) begin
                    #5 clk = !clk;
                    #0.001;
                    if (tq !== expected[(TristateWidth==1)?0 : bit_index]) begin
                        $display("FAIL: DDR tristate bit %0d", bit_index);
                        $finish;
                    end
                end
            end else begin
                #5 clk = 1'b0;
                #0.001;
                if (tq !== 1'b0) begin
                    $display("FAIL: SDR TQ changed on falling CLK");
                    $finish;
                end
                #5 clk = 1'b1;
                #0.001;
                if (tq !== 1'b1) begin
                    $display("FAIL: SDR TQ missing on rising CLK");
                    $finish;
                end
            end
            // Tristate serialization must work even though OCE remains low.
            if ((oq !== 1'b0) || (tfb !== tq)) begin
                $display("FAIL: data and tristate paths are not independent");
                $finish;
            end
            enable      = 1'b0;
            expected[0] = tq;
            repeat (8) begin
                #5;
                clk    = !clk;
                clkdiv = !clkdiv;
                #0.001;
                if (tq !== expected[0]) begin
                    $display("FAIL: TCE did not hold TQ");
                    $finish;
                end
            end
            reset = 1'b1;
            #0.001;
            if (tq !== 1'b0) begin
                $display("FAIL: tristate reset");
                $finish;
            end
        end
        $display("PASS: OSERDESE2 tristate");
        $finish;
    end
endmodule

`default_nettype wire
