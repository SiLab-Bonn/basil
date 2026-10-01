`timescale 1ps / 1ps

module test_SimXilinxDelays #(
    parameter       OutputDelay  = 0,
    parameter       DelayType    = "VAR_LOAD",
    parameter       PipeSelect   = "FALSE",
    parameter       SourceSelect = 0,
    parameter [0:0] Invert       = 0,
    parameter       Frequency    = 200.0
);
    reg clock = 1'b0;
    reg enable = 1'b0;
    reg increment = 1'b0;
    reg load = 1'b0;
    reg load_pipe = 1'b0;
    reg reset_pipe = 1'b0;
    reg invert_clock = 1'b0;
    reg data = 1'b0;
    reg other_data = 1'b0;
    reg [4:0] count_in = 5'd0;
    wire [4:0] count_out;
    wire delayed_data;
    integer index;
    reg [31:0] random_state = 32'h17a531;

    generate
        if (OutputDelay) begin : g_output
            ODELAYE2 #(
                .ODELAY_TYPE        (DelayType),
                .ODELAY_VALUE       (7),
                .PIPE_SEL           (PipeSelect),
                .REFCLK_FREQUENCY   (Frequency),
                .DELAY_SRC          (SourceSelect ? "CLKIN" : "ODATAIN"),
                .IS_C_INVERTED      (Invert),
                .IS_ODATAIN_INVERTED(Invert),
                .CINVCTRL_SEL       ("TRUE")
            ) dut (
                .DATAOUT    (delayed_data),
                .CNTVALUEOUT(count_out),
                .C          (clock ^ Invert),
                .CE         (enable),
                .INC        (increment),
                .LD         (load),
                .LDPIPEEN   (load_pipe),
                .REGRST     (reset_pipe),
                .CINVCTRL   (invert_clock),
                .CNTVALUEIN (count_in),
                .ODATAIN    (data ^ Invert),
                .CLKIN      (other_data)
            );
        end else begin : g_input
            IDELAYE2 #(
                .IDELAY_TYPE        (DelayType),
                .IDELAY_VALUE       (7),
                .PIPE_SEL           (PipeSelect),
                .REFCLK_FREQUENCY   (Frequency),
                .DELAY_SRC          (SourceSelect ? "DATAIN" : "IDATAIN"),
                .IS_C_INVERTED      (Invert),
                .IS_IDATAIN_INVERTED(Invert),
                .IS_DATAIN_INVERTED (Invert),
                .CINVCTRL_SEL       ("TRUE")
            ) dut (
                .DATAOUT    (delayed_data),
                .CNTVALUEOUT(count_out),
                .C          (clock ^ Invert),
                .CE         (enable),
                .INC        (increment),
                .LD         (load),
                .LDPIPEEN   (load_pipe),
                .REGRST     (reset_pipe),
                .CINVCTRL   (invert_clock),
                .CNTVALUEIN (count_in),
                .IDATAIN    (data ^ Invert),
                .DATAIN     (other_data ^ Invert)
            );
        end
    endgenerate

    always @(delayed_data) begin
        if ($time >= 5000) $display("TRACE data %0t %b", $time, delayed_data);
    end

    task automatic tick;
        begin
            #100 clock = 1'b1;
            #100 clock = 1'b0;
            #1 $display("TRACE count %0t %d", $time, count_out);
        end
    endtask

    initial begin
        #5000;
        if (count_out !== ((DelayType == "FIXED" || DelayType == "VARIABLE") ? 5'd7 : 5'd0)) begin
            $display("FAIL: initial tap count");
            $finish;
        end
        // Wrap in both directions, direct/pipelined load and pipeline reset.
        count_in  = 5'd31;
        load_pipe = 1'b1;
        tick;
        load_pipe = 1'b0;
        load      = 1'b1;
        tick;
        load      = 1'b0;
        enable    = 1'b1;
        increment = 1'b1;
        tick;
        increment = 1'b0;
        tick;
        // Unknown controls must hold counts rather than select a valid branch.
        load = 1'bx;
        tick;
        load      = 1'b0;
        increment = 1'bx;
        tick;
        increment  = 1'b0;
        reset_pipe = 1'bx;
        load_pipe  = 1'b1;
        count_in   = 5'd9;
        tick;
        reset_pipe = 1'b1;
        tick;
        reset_pipe = 1'b0;
        load_pipe  = 1'b0;
        count_in   = 5'bxxxxx;
        load       = 1'b1;
        tick;
        // Switch taps during transitions; include pulses shorter than a tap.
        for (index = 0; index < 80; index = index + 1) begin
            random_state = random_state * 32'd1664525 + 32'd1013904223;
            count_in     = random_state[4:0];
            enable       = random_state[5];
            increment    = random_state[6];
            load         = random_state[7];
            load_pipe    = random_state[8];
            reset_pipe   = random_state[9];
            data         = random_state[11];
            other_data   = random_state[12];
            #1 invert_clock = random_state[10];
            tick;
            #20 data = !data;
            other_data = !other_data;
            #20 data = !data;
            other_data = !other_data;
            #300;
        end
        #4000;
        $display("PASS: Xilinx delays");
        $finish;
    end
endmodule
