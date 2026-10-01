`timescale 1ns / 1ps

module test_SimIddr #(
    parameter       EdgeMode    = "OPPOSITE_EDGE",
    parameter       ResetType   = "SYNC",
    parameter [0:0] Init1       = 1'b0,
    parameter [0:0] Init2       = 1'b0,
    parameter [0:0] InvertClock = 1'b0,
    parameter [0:0] InvertData  = 1'b0
);
    localparam Pipelined = ({152'b0, EdgeMode} == "SAME_EDGE_PIPELINED");
    localparam OppositeEdge = ({152'b0, EdgeMode} == "OPPOSITE_EDGE");
    localparam AsyncReset = ({40'b0, ResetType} == "ASYNC");
    reg clock;
    reg enable;
    reg data;
    reg reset;
    reg set_value;
    wire q1;
    wire q2;

    IDDR #(
        .DDR_CLK_EDGE (EdgeMode),
        .INIT_Q1      (Init1),
        .INIT_Q2      (Init2),
        .IS_C_INVERTED(InvertClock),
        .IS_D_INVERTED(InvertData),
        .SRTYPE       (ResetType)
    ) dut (
        .Q1(q1),
        .Q2(q2),
        .C (clock ^ InvertClock),
        .CE(enable),
        .D (data ^ InvertData),
        .R (reset),
        .S (set_value)
    );

    task automatic check;
        input expected1;
        input expected2;
        begin
            #1;
            if ((q1 !== expected1) || (q2 !== expected2)) begin
                $display("FAIL: IDDR at %0t got %b,%b expected %b,%b", $time, q1, q2, expected1,
                         expected2);
                $finish;
            end
        end
    endtask

    initial begin
        clock     = 1'b0;
        enable    = 1'b0;
        data      = 1'b0;
        reset     = 1'b0;
        set_value = 1'b0;
        check(Init1, Init2);
        // Three distinct half-cycle pairs expose the extra SAME_EDGE stages.
        enable = 1'b1;
        data   = 1'b1;
        #4 clock = 1'b1;
        check(Pipelined ? Init1 : 1'b1, Init2);
        data = 1'b0;
        #4 clock = 1'b0;
        check(Pipelined ? Init1 : 1'b1, OppositeEdge ? 1'b0 : Init2);
        #4 clock = 1'b1;
        check(Pipelined ? 1'b1 : 1'b0, 1'b0);
        data = 1'b1;
        #4 clock = 1'b0;
        check(Pipelined ? 1'b1 : 1'b0, OppositeEdge ? 1'b1 : 1'b0);
        #4 clock = 1'b1;
        check(Pipelined ? 1'b0 : 1'b1, 1'b1);
        enable = 1'b0;
        data   = 1'b0;
        check(Pipelined ? 1'b0 : 1'b1, 1'b1);
        #4 clock = 1'b0;
        check(Pipelined ? 1'b0 : 1'b1, 1'b1);
        #4 clock = 1'b1;
        check(Pipelined ? 1'b0 : 1'b1, 1'b1);
        // Unknown input must be captured, including through the pipeline.
        enable = 1'b1;
        data   = 1'bx;
        #4 clock = 1'b0;
        check(Pipelined ? 1'b0 : 1'b1, OppositeEdge ? 1'bx : 1'b1);
        #4 clock = 1'b1;
        check(Pipelined ? 1'b1 : 1'bx, 1'bx);
        enable = 1'b0;
        // Assert reset between edges with CE low.
        reset  = 1'b1;
        check(AsyncReset ? 1'b0 : (Pipelined ? 1'b1 : 1'bx), AsyncReset ? 1'b0 : 1'bx);
        #4 clock = 1'b0;
        check(AsyncReset ? 1'b0 : (Pipelined ? 1'b1 : 1'bx),
              (AsyncReset || OppositeEdge) ? 1'b0 : 1'bx);
        #4 clock = 1'b1;
        check(1'b0, 1'b0);
        reset     = 1'b0;
        set_value = 1'b1;
        check(AsyncReset ? 1'b1 : 1'b0, AsyncReset ? 1'b1 : 1'b0);
        #4 clock = 1'b0;
        check(AsyncReset ? 1'b1 : 1'b0, (AsyncReset || OppositeEdge) ? 1'b1 : 1'b0);
        #4 clock = 1'b1;
        check(1'b1, 1'b1);
        set_value = 1'b0;
        #4 clock = 1'b0;
        check(1'b1, 1'b1);
        // Reset wins over set. Releasing it with set high is asynchronous.
        reset = 1'b1;
        #4 clock = 1'b1;
        check(1'b0, (AsyncReset || !OppositeEdge) ? 1'b0 : 1'b1);
        #4 clock = 1'b0;
        check(1'b0, 1'b0);
        set_value = 1'b1;
        check(1'b0, 1'b0);
        reset = 1'b0;
        check(AsyncReset ? 1'b1 : 1'b0, AsyncReset ? 1'b1 : 1'b0);
        #4 clock = 1'b1;
        check(1'b1, (AsyncReset || !OppositeEdge) ? 1'b1 : 1'b0);
        #4 clock = 1'b0;
        check(1'b1, 1'b1);
        // Unknown control pins hold state; unknown data is still captured.
        set_value = 1'b0;
        enable    = 1'b1;
        data      = 1'b0;
        reset     = 1'bx;
        #4 clock = 1'b1;
        check(1'b1, 1'b1);
        #4 clock = 1'b0;
        check(1'b1, 1'b1);
        reset     = 1'b0;
        set_value = 1'bx;
        #4 clock = 1'b1;
        check(1'b1, 1'b1);
        #4 clock = 1'b0;
        check(1'b1, 1'b1);
        set_value = 1'b0;
        enable    = 1'bx;
        #4 clock = 1'b1;
        check(1'b1, 1'b1);
        #4 clock = 1'b0;
        check(1'b1, 1'b1);
        // Floating reset and set pins use the primitive's weak pulldowns.
        reset     = 1'bz;
        set_value = 1'bz;
        enable    = 1'b1;
        #4 clock = 1'b1;
        check(Pipelined ? 1'b1 : 1'b0, 1'b1);
        #4 clock = 1'b0;
        check(Pipelined ? 1'b1 : 1'b0, OppositeEdge ? 1'b0 : 1'b1);
        #4 clock = 1'b1;
        check(1'b0, 1'b0);
        $display("PASS: IDDR behavior");
        $finish;
    end
endmodule

// Preserve the existing module name and its callers.
// verilog_lint: waive module-filename
module test_SimOddr #(
    parameter       EdgeMode    = "OPPOSITE_EDGE",
    parameter       ResetType   = "SYNC",
    parameter [0:0] Init        = 1'b0,
    parameter [0:0] InvertClock = 1'b0,
    parameter [0:0] InvertData1 = 1'b0,
    parameter [0:0] InvertData2 = 1'b0
);
    localparam SameEdge   = ({152'b0, EdgeMode} == "SAME_EDGE");
    localparam AsyncReset = ({40'b0, ResetType} == "ASYNC");
    reg clock;
    reg enable;
    reg data1;
    reg data2;
    reg reset;
    reg set_value;
    wire q;

    ODDR #(
        .DDR_CLK_EDGE  (EdgeMode),
        .INIT          (Init),
        .SRTYPE        (ResetType),
        .IS_C_INVERTED (InvertClock),
        .IS_D1_INVERTED(InvertData1),
        .IS_D2_INVERTED(InvertData2)
    ) dut (
        .Q (q),
        .C (clock ^ InvertClock),
        .CE(enable),
        .D1(data1 ^ InvertData1),
        .D2(data2 ^ InvertData2),
        .R (reset),
        .S (set_value)
    );

    task automatic check;
        input expected;
        begin
            #1;
            if (q !== expected) begin
                $display("FAIL: ODDR at %0t got %b expected %b", $time, q, expected);
                $finish;
            end
        end
    endtask

    initial begin
        clock     = 1'b0;
        enable    = 1'b0;
        data1     = 1'b0;
        data2     = 1'b0;
        reset     = 1'b0;
        set_value = 1'b0;
        check(Init);
        enable = 1'b1;
        data1  = 1'b1;
        #4 clock = 1'b1;
        check(1'b1);
        // SAME_EDGE must retain D2 from the rising edge.
        data2 = 1'b1;
        check(1'b1);
        #4 clock = 1'b0;
        check(SameEdge ? 1'b0 : 1'b1);
        enable = 1'b0;
        check(SameEdge ? 1'b0 : 1'b1);
        #4 clock = 1'b1;
        check(SameEdge ? 1'b0 : 1'b1);
        // Re-enabling between edges must not resurrect an old D2 word.
        enable = 1'b1;
        #4 clock = 1'b0;
        check(SameEdge ? 1'b0 : 1'b1);
        data1 = 1'b0;
        data2 = 1'b1;
        #4 clock = 1'b1;
        check(1'b0);
        data2 = 1'b0;
        #4 clock = 1'b0;
        check(SameEdge ? 1'b1 : 1'b0);
        data1 = 1'b1;
        #4 clock = 1'b1;
        check(1'b1);
        enable = 1'b0;
        check(1'b1);
        #4 clock = 1'b0;
        check(1'b1);
        #4 clock = 1'b1;
        check(1'b1);
        // Reset and set have priority over CE, with no intervening clock.
        reset = 1'b1;
        check(AsyncReset ? 1'b0 : 1'b1);
        #4 clock = 1'b0;
        check(1'b0);
        reset     = 1'b0;
        set_value = 1'b1;
        check(AsyncReset ? 1'b1 : 1'b0);
        #4 clock = 1'b1;
        check(1'b1);
        set_value = 1'b0;
        enable    = 1'b1;
        data1     = 1'bx;
        data2     = 1'bx;
        #4 clock = 1'b0;
        check(SameEdge ? 1'b1 : 1'bx);
        #4 clock = 1'b1;
        check(1'bx);
        #4 clock = 1'b0;
        check(1'bx);
        reset = 1'b1;
        #4 clock = 1'b1;
        check(1'b0);
        #4 clock = 1'b0;
        check(1'b0);
        set_value = 1'b1;
        check(1'b0);
        reset = 1'b0;
        check(AsyncReset ? 1'b1 : 1'b0);
        #4 clock = 1'b1;
        check(1'b1);
        #4 clock = 1'b0;
        check(1'b1);
        set_value = 1'b0;
        data1     = 1'b0;
        data2     = 1'b0;
        reset     = 1'bx;
        #4 clock = 1'b1;
        check(1'b1);
        #4 clock = 1'b0;
        check(1'b1);
        reset     = 1'b0;
        set_value = 1'bx;
        #4 clock = 1'b1;
        check(1'b1);
        #4 clock = 1'b0;
        check(1'b1);
        set_value = 1'b0;
        enable    = 1'bx;
        #4 clock = 1'b1;
        check(1'b1);
        #4 clock = 1'b0;
        check(1'b1);
        // Verilog treats 0->X as a rising edge and 1->X as a falling edge.
        enable = 1'b1;
        data1  = 1'b1;
        #4 clock = 1'bx;
        check(1'b1);
        #4 clock = 1'b1;
        check(1'b1);
        #4 clock = 1'bx;
        check(1'b0);
        #4 clock = 1'b0;
        check(1'b0);
        reset     = 1'bz;
        set_value = 1'bz;
        data1     = 1'b1;
        #4 clock = 1'b1;
        check(1'b1);
        #4 clock = 1'b0;
        check(1'b0);
        $display("PASS: ODDR behavior");
        $finish;
    end
endmodule
