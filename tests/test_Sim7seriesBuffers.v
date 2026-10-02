`timescale 1ns / 1ps

module test_Sim7seriesBuffers;
    reg positive;
    reg negative;
    reg tristate;
    reg external_enable;
    reg external_data;
    wire clock_output;
    wire input_output;
    wire clock_input_output;
    wire output_output;
    wire differential_output;
    wire differential_output_n;
    wire differential_input;
    wire biased_input;
    wire differential_clock_input;
    wire pad_readback;
    wire io;

    // Positional connections specifically catch the BUFG and IOBUF order bugs.
    BUFG clock_buffer (
        // This positional connection is the behavior under test.
        // verilog_lint: waive module-port
        clock_output,
        positive
    );
    IOBUF bidirectional_buffer (
        // This positional connection is the behavior under test.
        // verilog_lint: waive module-port
        pad_readback,
        io,
        positive,
        tristate
    );
    IBUF input_buffer (
        .O(input_output),
        .I(positive)
    );
    IBUFG clock_input_buffer (
        .O(clock_input_output),
        .I(positive)
    );
    OBUF output_buffer (
        .O(output_output),
        .I(positive)
    );
    OBUFDS differential_output_buffer (
        .O (differential_output),
        .OB(differential_output_n),
        .I (positive)
    );
    IBUFDS differential_buffer (
        .O (differential_input),
        .I (positive),
        .IB(negative)
    );
    IBUFDS #(
        .DQS_BIAS("TRUE")
    ) biased_buffer (
        .O (biased_input),
        .I (positive),
        .IB(negative)
    );
    IBUFGDS differential_clock_buffer (
        .O (differential_clock_input),
        .I (positive),
        .IB(negative)
    );
    assign io = external_enable ? external_data : 1'bz;

endmodule
