`timescale 1ns / 1ps
`default_nettype none

module test_SimOserdes #(
    parameter         DataRate  = "DDR",
    parameter integer DataWidth = 8,
    parameter         Invert    = 1'b0,
    parameter integer DivPhase  = 0
);
    localparam integer Step = (DataRate == "DDR") ? 5 : 10;
    localparam integer Frame = Step * DataWidth;
    reg clk;
    reg clkdiv;
    reg reset;
    reg enable;
    reg [9:0] data;
    wire serial_data;
    wire shift1;
    wire shift2;
    integer sent;
    integer frame_index;
    integer bit_index;
    integer pass_index;
    reg [9:0] expected;
    reg held;

    function automatic [9:0] pattern;
        input integer index;
        begin
            case (index % 4)
                0: pattern = 10'h101;
                1: pattern = 10'h202;
                2: pattern = 10'h155;
                default: pattern = 10'h2AA;
            endcase
        end
    endfunction

    initial begin
        clk = 1'b0;
        forever #5 clk = !clk;
    end
    initial begin
        clkdiv = 1'b0;
        #(5 + DivPhase);
        forever begin
            clkdiv = 1'b1;
            #(Frame / 2);
            clkdiv = 1'b0;
            #(Frame / 2);
        end
    end

    // Send distinct words to detect mixed data and cascade bits.
    always @(negedge clkdiv) begin
        if (reset) begin
            sent = 0;
            data = pattern(0);
        end else if (enable) begin
            sent = sent + 1;
            data = pattern(sent);
        end
    end

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

    initial begin
        reset  = 1'b1;
        enable = 1'b1;
        sent   = 0;
        data   = pattern(0);
        for (pass_index = 0; pass_index < 2; pass_index = pass_index + 1) begin
            repeat (2) @(negedge clkdiv);
            #1 reset = 1'b0;
            @(posedge clkdiv);
            // Check D1 on the first serial edge after capture.
            if (DataRate == "DDR") @(clk);
            else @(posedge clk);
            #0.001;
            for (frame_index = 0; frame_index < 16; frame_index = frame_index + 1) begin
                expected = pattern(frame_index);
                for (bit_index = 0; bit_index < DataWidth; bit_index = bit_index + 1) begin
                    if (serial_data !== expected[bit_index]) begin
                        $display("FAIL: frame=%0d bit=%0d got=%b expected=%b", frame_index,
                                 bit_index, serial_data, expected[bit_index]);
                        $finish;
                    end
                    #Step;
                end
            end
            // OCE must hold the output even while both clocks run.
            enable = 1'b0;
            held   = serial_data;
            repeat (2 * DataWidth) begin
                #Step;
                if (serial_data !== held) begin
                    $display("FAIL: OCE did not hold output");
                    $finish;
                end
            end
            reset = 1'b1;
            #0.001;
            if (serial_data !== 1'b0) begin
                $display("FAIL: asynchronous reset");
                $finish;
            end
            enable = 1'b1;
        end
        $display("PASS: OSERDESE2 words");
        $finish;
    end

    initial begin
        #100000;
        $display("FAIL: serializer timeout");
        $finish;
    end
endmodule

`default_nettype wire
