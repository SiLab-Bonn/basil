`timescale 1ps / 1ps

module test_SimXilinxSerializerAttributes #(
    parameter       TristateRate  = "DDR",
    parameter       TristateWidth = 1,
    parameter [0:0] Invert        = 1'b0
);
    reg clock = 1'b0;
    reg divided_clock = 1'b0;
    reg reset = 1'b0;
    reg data_enable = 1'b0;
    reg tristate_enable = 1'b0;
    reg data = 1'b0;
    reg tristate_data = 1'b1;
    wire output_data;
    wire output_feedback;
    wire output_tristate;
    wire tristate_feedback;
    wire byte_output;

    always #5000 clock = !clock;
    always #10000 divided_clock = !divided_clock;
    OSERDESE2 #(
        .DATA_WIDTH        (4),
        .DATA_RATE_TQ      (TristateRate),
        .TRISTATE_WIDTH    (TristateWidth),
        .INIT_OQ           (1'b1),
        .INIT_TQ           (1'b0),
        .SRVAL_OQ          (1'b0),
        .SRVAL_TQ          (1'b1),
        .IS_CLK_INVERTED   (Invert),
        .IS_CLKDIV_INVERTED(Invert),
        .IS_D1_INVERTED    (1'b1),
        .IS_D2_INVERTED    (1'b1),
        .IS_D3_INVERTED    (1'b1),
        .IS_D4_INVERTED    (1'b1),
        .IS_D5_INVERTED    (1'b1),
        .IS_D6_INVERTED    (1'b1),
        .IS_D7_INVERTED    (1'b1),
        .IS_D8_INVERTED    (1'b1),
        .IS_T1_INVERTED    (1'b1),
        .IS_T2_INVERTED    (1'b1),
        .IS_T3_INVERTED    (1'b1),
        .IS_T4_INVERTED    (1'b1)
    ) dut (
        .CLK      (clock ^ Invert),
        .CLKDIV   (divided_clock ^ Invert),
        .RST      (reset),
        .OCE      (data_enable),
        .TCE      (tristate_enable),
        .D1       (data),
        .D2       (data),
        .D3       (data),
        .D4       (data),
        .D5       (data),
        .D6       (data),
        .D7       (data),
        .D8       (data),
        .T1       (tristate_data),
        .T2       (tristate_data),
        .T3       (tristate_data),
        .T4       (tristate_data),
        .TBYTEIN  (1'b0),
        .SHIFTIN1 (1'b0),
        .SHIFTIN2 (1'b0),
        .OQ       (output_data),
        .OFB      (output_feedback),
        .TQ       (output_tristate),
        .TFB      (tristate_feedback),
        .TBYTEOUT (byte_output),
        .SHIFTOUT1(),
        .SHIFTOUT2()
    );

    task automatic check;
        input expected_data;
        input expected_tristate;
        begin
            if ({output_data,output_feedback,output_tristate,tristate_feedback,byte_output} !==
                {expected_data,expected_data,expected_tristate,expected_tristate,1'b1}) begin
                $display("FAIL: serializer attributes OQ=%b OFB=%b TQ=%b TFB=%b byte=%b",
                         output_data, output_feedback, output_tristate, tristate_feedback,
                         byte_output);
                $finish;
            end
            $display("TRACE attributes %b%b%b", output_data, output_tristate, byte_output);
        end
    endtask

    initial begin
        #200000;
        check(1'b1, 1'b0);
        reset = 1'b1;
        #100000;
        check(1'b0, (TristateRate == "BUF") ? 1'b0 : 1'b1);
        reset           = 1'b0;
        data_enable     = 1'b1;
        tristate_enable = 1'b1;
        #100000;
        check(1'b1, 1'b0);
        data_enable     = 1'b0;
        tristate_enable = 1'b0;
        data            = 1'b1;
        tristate_data   = 1'b0;
        #100000;
        check(1'b1, (TristateRate == "BUF") ? 1'b1 : 1'b0);
        $display("PASS: serializer attributes");
        $finish;
    end
endmodule
