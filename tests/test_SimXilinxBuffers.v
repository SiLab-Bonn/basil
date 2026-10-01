`timescale 1ns / 1ps

module test_SimXilinxBuffers;
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

    task automatic check_differential;
        input expected;
        input expected_bias;
        begin
            #1;
            if ((differential_input !== expected) || (differential_clock_input !== expected) ||
                (biased_input !== expected_bias)) begin
                $display("FAIL: differential inputs I=%b IB=%b O=%b clock=%b biased=%b", positive,
                         negative, differential_input, differential_clock_input, biased_input);
                $finish;
            end
        end
    endtask

    initial begin
        positive        = 1'b1;
        negative        = 1'b0;
        tristate        = 1'b0;
        external_enable = 1'b0;
        external_data   = 1'b0;
        check_differential(1'b1, 1'b1);
        if ({clock_output, input_output, clock_input_output, output_output,
             differential_output, differential_output_n, io, pad_readback} !== 8'b11111011) begin
            $display("FAIL: buffer output or positional port order");
            $finish;
        end
        // Equal driven inputs retain the preceding valid differential level.
        negative = 1'b1;
        check_differential(1'b1, 1'b1);
        positive = 1'b0;
        check_differential(1'b0, 1'b0);
        negative = 1'b0;
        check_differential(1'b0, 1'b0);
        // Floating termination drives low only with DQS_BIAS enabled.
        positive = 1'bz;
        negative = 1'bz;
        check_differential(1'bx, 1'b0);
        if ({clock_output, input_output, clock_input_output, output_output,
             differential_output, differential_output_n} !== 6'bxxxxxx) begin
            $display("FAIL: floating buffer input must become unknown");
            $finish;
        end
        if ((io !== 1'bx) || (pad_readback !== 1'bx)) begin
            $display("FAIL: enabled IOBUF with floating input must drive unknown");
            $finish;
        end
        positive = 1'b0;
        check_differential(1'bx, 1'b0);
        positive = 1'bz;
        negative = 1'b1;
        check_differential(1'bx, 1'b0);
        positive = 1'bx;
        check_differential(1'bx, 1'bx);
        positive = 1'b1;
        negative = 1'b0;
        check_differential(1'b1, 1'b1);
        tristate        = 1'b1;
        external_enable = 1'b1;
        external_data   = 1'b0;
        #1;
        if ((io !== 1'b0) || (pad_readback !== 1'b0)) begin
            $display("FAIL: IOBUF external low input");
            $finish;
        end
        external_data = 1'b1;
        #1;
        if ((io !== 1'b1) || (pad_readback !== 1'b1)) begin
            $display("FAIL: IOBUF external high input");
            $finish;
        end
        external_enable = 1'b0;
        #1;
        if ((io !== 1'bz) || (pad_readback !== 1'bx)) begin
            $display("FAIL: IOBUF released pad");
            $finish;
        end
        $display("PASS: Xilinx buffers");
        $finish;
    end
endmodule
