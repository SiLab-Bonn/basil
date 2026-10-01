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
    localparam integer Frame = (DataRate == "DDR") ? 20 : 40;
    integer pattern_index;
    integer serial_edges = 0;
    integer word_end_phase = -1;
    reg held;

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

    initial begin
        clk = 1'b0;
        forever #5 clk = !clk;
    end
    initial begin
        clkdiv = 1'b0;
        #5;
        forever begin
            clkdiv = 1'b1;
            #(Frame / 2) clkdiv = 1'b0;
            #(Frame / 2);
        end
    end

    always @(clk) serial_edges = serial_edges + 1;

    task automatic sample;
        output value;
        begin
            @(clk);
            #1 value = tq;
        end
    endtask

    task automatic check_pattern;
        input [3:0] expected;
        reg [3:0] received;
        reg value;
        integer attempt;
        integer bit_index;
        integer frame_index;
        begin
            repeat (4) @(posedge clkdiv);
            received = 0;
            attempt  = 0;
            if (TristateWidth == 4) begin
                if (word_end_phase < 0) begin
                    while ((attempt < 4) || (received !== expected)) begin
                        sample (value);
                        received = {value, received[3:1]};
                        attempt  = attempt + 1;
                        if (attempt > 12) begin
                            $display("FAIL: could not find tristate word %b", expected);
                            $finish;
                        end
                    end
                    word_end_phase = serial_edges % 4;
                end else begin
                    sample (value);
                    while (serial_edges % 4 != word_end_phase) sample (value);
                end
                for (frame_index = 0; frame_index < 8; frame_index = frame_index + 1) begin
                    for (bit_index = 0; bit_index < 4; bit_index = bit_index + 1) begin
                        sample (value);
                        if (value !== expected[bit_index]) begin
                            $display("FAIL: tristate bit %0d", bit_index);
                            $finish;
                        end
                    end
                end
            end else begin
                #1;
                if (tq !== expected[0]) begin
                    $display("FAIL: tristate T1 value");
                    $finish;
                end
            end
            if ((oq !== 1'b0) || (tfb !== tq)) begin
                $display("FAIL: data/tristate independence or feedback");
                $finish;
            end
            $display("TRACE tristate %b", expected);
        end
    endtask

    initial begin
        reset         = 1'b1;
        enable        = 1'b0;
        tristate_data = 4'b0000;
        repeat (4) @(posedge clkdiv);
        #1;
        if (byte_output !== 1'b1) begin
            $display("FAIL: disabled byte grouping output");
            $finish;
        end
        if (TristateRate == "BUF") begin
            // BUF follows T1 even with TCE low and reset high.
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
            reset  = 1'b0;
            enable = 1'b1;
            for (pattern_index = 0; pattern_index < 4; pattern_index = pattern_index + 1) begin
                @(negedge clkdiv);
                #1;
                case (pattern_index)
                    0: tristate_data = 4'b1001;
                    1: tristate_data = 4'b0010;
                    2: tristate_data = 4'b1101;
                    default: tristate_data = 4'b0110;
                endcase
                check_pattern(tristate_data);
            end
            enable = 1'b0;
            repeat (4) @(posedge clkdiv);
            #1 held = tq;
            repeat (8) begin
                @(clk);
                #1;
                if (tq !== held) begin
                    $display("FAIL: TCE did not hold TQ");
                    $finish;
                end
            end
            enable = 1'b1;
            reset  = 1'b1;
            repeat (2) @(posedge clkdiv);
            #1;
            if (tq !== 1'b0) begin
                $display("FAIL: tristate reset");
                $finish;
            end
        end
        $display("PASS: OSERDESE2 tristate");
        $finish;
    end

    initial begin
        #100000;
        $display("FAIL: tristate timeout");
        $finish;
    end
endmodule
