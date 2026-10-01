"""Directed and seeded functional traces, optionally compared with installed UNISIM.

Set BASIL_UNISIM_DIR to Vivado's data/verilog/src/unisims directory. Vendor
sources are compiled separately and are never copied into the repository.
"""

from pathlib import Path

import pytest
from xilinx_sim import run_primitive_bench as compare_models


@pytest.mark.parametrize("output", [0, 1])
@pytest.mark.parametrize(
    "mode,pipe", [("FIXED", "FALSE"), ("VARIABLE", "FALSE"), ("VAR_LOAD", "FALSE"), ("VAR_LOAD_PIPE", "TRUE")]
)
@pytest.mark.parametrize("frequency,invert,source", [(200, 0, 0), (300, 1, 1), (400, 0, 1)])
def test_delay_traces(tmp_path, output, mode, pipe, frequency, invert, source):
    compare_models(
        tmp_path,
        Path(__file__).with_name("test_SimXilinxDelays.v"),
        ["IDELAYE2", "ODELAYE2"],
        [
            ("OutputDelay", output),
            ("DelayType", f'"{mode}"'),
            ("PipeSelect", f'"{pipe}"'),
            ("Frequency", frequency),
            ("Invert", invert),
            ("SourceSelect", source),
        ],
    )


def test_gte_receiver_trace(tmp_path):
    compare_models(
        tmp_path,
        """
module tb;
reg i=0, ib=1, ceb=0;
wire o, divided;
integer n;
IBUFDS_GTE2 dut(.O(o), .ODIV2(divided), .I(i), .IB(ib), .CEB(ceb));
initial begin
    #1000;
    for (n=0; n<16; n=n+1) begin
        i=1; ib=(n%3==0); #1;
        $display("TRACE rise %d %b%b", n, o, divided);
        if (n==0 && {o,divided} !== 2'b10) begin
            $display("FAIL: initial divider phase"); $finish;
        end
        ceb=1; #1;
        $display("TRACE static_disable %d %b%b", n, o, divided);
        i=0; #1;
        $display("TRACE fall %d %b%b", n, o, divided);
        ceb=(n%4==0); #1;
    end
    $display("PASS: GTE receiver"); $finish;
end
endmodule
""",
        ["IBUFDS_GTE2"],
    )


@pytest.mark.parametrize("stopped_level", [0, 1])
def test_delayctrl_trace(tmp_path, stopped_level):
    compare_models(
        tmp_path,
        f"""
module tb;
reg c=0, r=1;
wire ready;
integer n;
IDELAYCTRL dut(.RDY(ready), .REFCLK(c), .RST(r));
always @(ready) if ($time>0) $display("TRACE ready %0t %b", $time, ready);
initial begin
    #1000; r=0;
    for (n=0; n<{12 + stopped_level}; n=n+1) begin #2500; c=~c; end
    #1;
    if (ready !== 1'b1) begin $display("FAIL: clock never ready"); $finish; end
    #10000;
    if (ready !== 1'b0) begin $display("FAIL: stopped clock still ready"); $finish; end
    for (n=0; n<12; n=n+1) begin #2500; c=~c; end
    #1; r=1; #100; r=0; #100;
    if (ready !== 1'b1) begin $display("FAIL: reset release while clock valid"); $finish; end
    $display("PASS: delay controller"); $finish;
end
endmodule
""",
        ["IDELAYCTRL"],
    )


@pytest.mark.parametrize("edge", ["OPPOSITE_EDGE", "SAME_EDGE", "SAME_EDGE_PIPELINED"])
@pytest.mark.parametrize("reset_type,invert", [("SYNC", 0), ("ASYNC", 1)])
def test_ddr_seeded_trace(tmp_path, edge, reset_type, invert):
    compare_models(
        tmp_path,
        f"""
module tb;
reg c=0, ce=1, d1=0, d2=1, r=0, s=0;
wire q1,q2,q;
reg [31:0] random_state=32'h831ad;
integer n;
IDDR #(.DDR_CLK_EDGE("{edge}"), .SRTYPE("{reset_type}"), .INIT_Q1(1), .INIT_Q2(0),
.IS_C_INVERTED(1'b{invert}), .IS_D_INVERTED(1'b{invert}))
iddr(.Q1(q1),.Q2(q2),.C(c),.CE(ce),.D(d1),.R(r),.S(s));
ODDR #(.DDR_CLK_EDGE("{"SAME_EDGE" if invert else "OPPOSITE_EDGE"}"), .SRTYPE("{reset_type}"),
.INIT(1),.IS_C_INVERTED(1'b{invert}),.IS_D1_INVERTED(1'b{invert}),.IS_D2_INVERTED(1'b{invert}))
oddr(.Q(q),.C(c),.CE(ce),.D1(d1),.D2(d2),.R(r),.S(s));
initial begin
    #5000;
    for(n=0;n<200;n=n+1) begin
        random_state=random_state*32'd1664525+32'd1013904223;
        ce=(random_state[3:0]==0) ? 1'bx : random_state[4];
        r=(random_state[7:5]==0) ? 1'bx : (random_state[7:5]==1);
        s=(random_state[10:8]==0) ? 1'bz : (random_state[10:8]==1);
        d1=random_state[11]; d2=random_state[12];
        #10; $display("TRACE controls %d %b%b%b", n,q1,q2,q);
        c=~c; #10; $display("TRACE edge %d %b%b%b", n,q1,q2,q);
    end
    $display("PASS: DDR seeded trace"); $finish;
end
endmodule
""",
        ["IDDR", "ODDR"],
    )


@pytest.mark.parametrize("use_base", [0, 1])
def test_pll_output_metrics(tmp_path, use_base):
    compare_models(
        tmp_path,
        Path(__file__).with_name("test_SimXilinxPllAccuracy.v"),
        ["PLLE2_BASE", "PLLE2_ADV", "pll", "dyn_reconf", "period_count", "period_check", "freq_gen", "phase_shift"],
        [("UseBase", use_base)],
    )


@pytest.mark.parametrize(
    "rate,width",
    [
        ("BUF", 1),
        ("SDR", 1),
        ("DDR", 4),
    ],
)
@pytest.mark.parametrize("invert", [0, 1])
def test_serializer_attributes(tmp_path, rate, width, invert):
    bench = Path(__file__).with_name("test_SimXilinxSerializerAttributes.v")
    parameters = [("TristateRate", f'"{rate}"'), ("TristateWidth", width), ("Invert", invert)]
    compare_models(tmp_path, bench, ["OSERDESE2"], parameters)
