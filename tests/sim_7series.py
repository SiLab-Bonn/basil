"""Build and exercise 7series primitive models against Basil and optional UNISIM."""

import json
import os
import shutil
from pathlib import Path

import cocotb
import pytest
from cocotb.triggers import Edge, FallingEdge, ReadOnly, RisingEdge, Timer, with_timeout
from cocotb.utils import get_sim_time

UTILS = Path(__file__).resolve().parents[1] / "basil/firmware/modules/utils"


def run_primitive_bench(tmp_path, bench, primitives, parameters=()):
    from cocotb_tools.runner import Verilog, get_runner

    if not shutil.which("iverilog") or not shutil.which("vvp"):
        pytest.skip("Icarus Verilog is not installed")
    source = Path(bench)
    top = source.stem
    parameters = dict(parameters)
    settings = {name: value.strip('"') if isinstance(value, str) else value for name, value in parameters.items()}
    globals_source = tmp_path / "glbl.v"
    globals_source.write_text(
        "`timescale 1ps/1ps\nmodule glbl; reg GSR = 1'b1; wire GTS = 1'b0; "
        "wire PLL_LOCKG = 1'b1; initial #1000 GSR = 1'b0; endmodule\n"
    )
    libraries = [("basil", UTILS)]
    if os.environ.get("BASIL_UNISIM_DIR"):
        libraries.append(("unisim", Path(os.environ["BASIL_UNISIM_DIR"])))
    traces = []
    for label, library in libraries:
        work = tmp_path / label
        work.mkdir()
        sources = [source.resolve(), globals_source]
        for name in primitives:
            directory = library.parent / "retarget" if label == "unisim" and name in {"IBUFG", "IBUFGDS"} else library
            model = directory / (name + ".v")
            if model.exists():
                sources.append(model)
        simulator = "icarus"
        arguments = ["-g2005", "-s", "glbl"]
        if label == "unisim" and "OSERDESE2" in primitives:
            assert shutil.which("xrun"), "UNISIM serializer comparisons require Xcelium (xrun) on PATH"
            simulator = "xcelium"
            arguments = ["-64bit", "-top", "glbl"]
            secureip = library.parents[2] / "secureip/oserdese2"
            # These are AMD's external encrypted models, never repository copies.
            sources += [Verilog(secureip / "oserdese2_001.vp"), Verilog(secureip / "oserdese2_002.vp")]
        runner = get_runner(simulator)
        runner.build(
            sources=sources,
            parameters=parameters,
            hdl_toplevel=top,
            build_dir=work / "sim_build",
            build_args=arguments,
            always=True,
            log_file=work / "build.log",
        )
        (work / "parameters.json").write_text(json.dumps(settings))
        trace = work / "trace.json"
        runner.test(
            hdl_toplevel=top,
            hdl_toplevel_lang="verilog",
            test_module="sim_7series",
            test_dir=work,
            log_file=work / "run.log",
        )
        traces.append(json.loads(trace.read_text()))
    if len(traces) == 2:
        assert traces[0] == traces[1]


def drive(dut, **signals):
    for name, value in signals.items():
        getattr(dut, name).value = value


def assert_outputs(dut, **expected):
    for name, value in expected.items():
        actual = str(getattr(dut, name).value).upper()
        assert actual == str(value).upper(), f"{name}: got {actual}, expected {value} at {get_sim_time(unit='ps')} ps"


async def iddr(dut, params, trace):
    asynchronous = params["ResetType"] == "ASYNC"
    pipelined = params["EdgeMode"] == "SAME_EDGE_PIPELINED"
    opposite = params["EdgeMode"] == "OPPOSITE_EDGE"
    init1, init2 = params["Init1"], params["Init2"]

    async def check(expected1, expected2):
        await Timer(1, unit="ns")
        assert_outputs(dut, q1=expected1, q2=expected2)

    drive(dut, clock=0)
    drive(dut, enable=0)
    drive(dut, data=0)
    drive(dut, reset=0)
    drive(dut, set_value=0)
    await check(init1, init2)
    drive(dut, enable=1)
    drive(dut, data=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check((init1 if pipelined else 1), init2)
    drive(dut, data=0)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((init1 if pipelined else 1), (0 if opposite else init2))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check((1 if pipelined else 0), 0)
    drive(dut, data=1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((1 if pipelined else 0), (1 if opposite else 0))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check((0 if pipelined else 1), 1)
    drive(dut, enable=0)
    drive(dut, data=0)
    await check((0 if pipelined else 1), 1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((0 if pipelined else 1), 1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check((0 if pipelined else 1), 1)
    drive(dut, enable=1)
    drive(dut, data="X")
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((0 if pipelined else 1), ("X" if opposite else 1))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check((1 if pipelined else "X"), "X")
    drive(dut, enable=0)
    drive(dut, reset=1)
    await check((0 if asynchronous else (1 if pipelined else "X")), (0 if asynchronous else "X"))
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((0 if asynchronous else (1 if pipelined else "X")), (0 if asynchronous or opposite else "X"))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(0, 0)
    drive(dut, reset=0)
    drive(dut, set_value=1)
    await check((1 if asynchronous else 0), (1 if asynchronous else 0))
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((1 if asynchronous else 0), (1 if asynchronous or opposite else 0))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1, 1)
    drive(dut, set_value=0)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1, 1)
    drive(dut, reset=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(0, (0 if asynchronous or not opposite else 1))
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(0, 0)
    drive(dut, set_value=1)
    await check(0, 0)
    drive(dut, reset=0)
    await check((1 if asynchronous else 0), (1 if asynchronous else 0))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1, (1 if asynchronous or not opposite else 0))
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1, 1)
    drive(dut, set_value=0)
    drive(dut, enable=1)
    drive(dut, data=0)
    drive(dut, reset="X")
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1, 1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1, 1)
    drive(dut, reset=0)
    drive(dut, set_value="X")
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1, 1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1, 1)
    drive(dut, set_value=0)
    drive(dut, enable="X")
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1, 1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1, 1)
    drive(dut, reset="Z")
    drive(dut, set_value="Z")
    drive(dut, enable=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check((1 if pipelined else 0), 1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((1 if pipelined else 0), (0 if opposite else 1))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(0, 0)


async def oddr(dut, params, trace):
    asynchronous = params["ResetType"] == "ASYNC"
    same = params["EdgeMode"] == "SAME_EDGE"
    init = params["Init"]

    async def check(expected):
        await Timer(1, unit="ns")
        assert_outputs(dut, q=expected)

    drive(dut, clock=0)
    drive(dut, enable=0)
    drive(dut, data1=0)
    drive(dut, data2=0)
    drive(dut, reset=0)
    drive(dut, set_value=0)
    await check(init)
    drive(dut, enable=1)
    drive(dut, data1=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    drive(dut, data2=1)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((0 if same else 1))
    drive(dut, enable=0)
    await check((0 if same else 1))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check((0 if same else 1))
    drive(dut, enable=1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((0 if same else 1))
    drive(dut, data1=0)
    drive(dut, data2=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(0)
    drive(dut, data2=0)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((1 if same else 0))
    drive(dut, data1=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    drive(dut, enable=0)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    drive(dut, reset=1)
    await check((0 if asynchronous else 1))
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(0)
    drive(dut, reset=0)
    drive(dut, set_value=1)
    await check((1 if asynchronous else 0))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    drive(dut, set_value=0)
    drive(dut, enable=1)
    drive(dut, data1="X")
    drive(dut, data2="X")
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check((1 if same else "X"))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check("X")
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check("X")
    drive(dut, reset=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(0)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(0)
    drive(dut, set_value=1)
    await check(0)
    drive(dut, reset=0)
    await check((1 if asynchronous else 0))
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1)
    drive(dut, set_value=0)
    drive(dut, data1=0)
    drive(dut, data2=0)
    drive(dut, reset="X")
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1)
    drive(dut, reset=0)
    drive(dut, set_value="X")
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1)
    drive(dut, set_value=0)
    drive(dut, enable="X")
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(1)
    drive(dut, enable=1)
    drive(dut, data1=1)
    await Timer(4, unit="ns")
    drive(dut, clock="X")
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock="X")
    await check(0)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(0)
    drive(dut, reset="Z")
    drive(dut, set_value="Z")
    drive(dut, data1=1)
    await Timer(4, unit="ns")
    drive(dut, clock=1)
    await check(1)
    await Timer(4, unit="ns")
    drive(dut, clock=0)
    await check(0)


async def buffers(dut, params, trace):
    drive(dut, positive=1, negative=0, tristate=0, external_enable=0, external_data=0)

    async def differential(expected, bias):
        await Timer(1, unit="ns")
        assert_outputs(dut, differential_input=expected, differential_clock_input=expected, biased_input=bias)

    await differential(1, 1)
    assert_outputs(
        dut,
        clock_output=1,
        input_output=1,
        clock_input_output=1,
        output_output=1,
        differential_output=1,
        differential_output_n=0,
        io=1,
        pad_readback=1,
    )
    drive(dut, negative=1)
    await differential(1, 1)
    drive(dut, positive=0)
    await differential(0, 0)
    drive(dut, negative=0)
    await differential(0, 0)
    drive(dut, positive="Z", negative="Z")
    await differential("X", 0)
    assert_outputs(
        dut,
        clock_output="X",
        input_output="X",
        clock_input_output="X",
        output_output="X",
        differential_output="X",
        differential_output_n="X",
        io="X",
        pad_readback="X",
    )
    drive(dut, positive=0)
    await differential("X", 0)
    drive(dut, positive="Z", negative=1)
    await differential("X", 0)
    drive(dut, positive="X")
    await differential("X", "X")
    drive(dut, positive=1, negative=0)
    await differential(1, 1)
    drive(dut, tristate=1, external_enable=1, external_data=0)
    await Timer(1, unit="ns")
    assert_outputs(dut, io=0, pad_readback=0)
    drive(dut, external_data=1)
    await Timer(1, unit="ns")
    assert_outputs(dut, io=1, pad_readback=1)
    drive(dut, external_enable=0)
    await Timer(1, unit="ns")
    assert_outputs(dut, io="Z", pad_readback="X")


async def delays(dut, params, trace):
    drive(
        dut,
        clock=0,
        enable=0,
        increment=0,
        load=0,
        load_pipe=0,
        reset_pipe=0,
        invert_clock=0,
        data=0,
        other_data=0,
        count_in=0,
    )

    async def monitor():
        while True:
            await Edge(dut.delayed_data)
            await ReadOnly()
            time = int(get_sim_time(unit="ps"))
            if time >= 5000:
                trace.append(["data", time, str(dut.delayed_data.value).upper()])

    monitor_task = cocotb.start_soon(monitor())

    async def tick():
        await Timer(100, unit="ps")
        dut.clock.value = 1
        await Timer(100, unit="ps")
        dut.clock.value = 0
        await Timer(1, unit="ps")
        trace.append(["count", int(get_sim_time(unit="ps")), str(dut.count_out.value).upper()])

    await Timer(5000, unit="ps")
    assert int(dut.count_out.value) == (7 if params["DelayType"] in {"FIXED", "VARIABLE"} else 0)
    drive(dut, count_in=31, load_pipe=1)
    await tick()
    drive(dut, load_pipe=0, load=1)
    await tick()
    drive(dut, load=0, enable=1, increment=1)
    await tick()
    drive(dut, increment=0)
    await tick()
    drive(dut, load="X")
    await tick()
    drive(dut, load=0, increment="X")
    await tick()
    drive(dut, increment=0, reset_pipe="X", load_pipe=1, count_in=9)
    await tick()
    drive(dut, reset_pipe=1)
    await tick()
    drive(dut, reset_pipe=0, load_pipe=0, count_in="XXXXX", load=1)
    await tick()
    random_state = 0x17A531
    for _ in range(80):
        random_state = (random_state * 1664525 + 1013904223) & 0xFFFFFFFF

        def bit(index):
            return (random_state >> index) & 1

        drive(
            dut,
            count_in=random_state & 31,
            enable=bit(5),
            increment=bit(6),
            load=bit(7),
            load_pipe=bit(8),
            reset_pipe=bit(9),
            data=bit(11),
            other_data=bit(12),
        )
        await Timer(1, unit="ps")
        dut.invert_clock.value = bit(10)
        await tick()
        for _ in range(2):
            await Timer(20, unit="ps")
            drive(dut, data=1 - int(dut.data.value), other_data=1 - int(dut.other_data.value))
        await Timer(300, unit="ps")
    await Timer(4000, unit="ps")
    monitor_task.cancel()


async def gte_receiver(dut, params, trace):
    drive(dut, i=0, ib=1, ceb=0)
    await Timer(1000, unit="ps")
    for index in range(16):
        drive(dut, i=1, ib=int(index % 3 == 0))
        await Timer(1, unit="ps")
        trace.append(["rise", index, str(dut.o.value) + str(dut.divided.value)])
        if index == 0:
            assert_outputs(dut, o=1, divided=0)
        drive(dut, ceb=1)
        await Timer(1, unit="ps")
        trace.append(["static_disable", index, str(dut.o.value) + str(dut.divided.value)])
        drive(dut, i=0)
        await Timer(1, unit="ps")
        trace.append(["fall", index, str(dut.o.value) + str(dut.divided.value)])
        drive(dut, ceb=int(index % 4 == 0))
        await Timer(1, unit="ps")


async def delay_control(dut, params, trace):
    drive(dut, c=0, r=1)

    async def monitor():
        while True:
            await Edge(dut.ready)
            await ReadOnly()
            time = int(get_sim_time(unit="ps"))
            if time:
                trace.append(["ready", time, str(dut.ready.value)])

    monitor_task = cocotb.start_soon(monitor())

    async def clock_edges(count):
        for _ in range(count):
            await Timer(2500, unit="ps")
            dut.c.value = 1 - int(dut.c.value)

    await Timer(1000, unit="ps")
    dut.r.value = 0
    await clock_edges(12 + params["StoppedLevel"])
    await Timer(1, unit="ps")
    assert_outputs(dut, ready=1)
    await Timer(10000, unit="ps")
    assert_outputs(dut, ready=0)
    await clock_edges(12)
    await Timer(1, unit="ps")
    dut.r.value = 1
    await Timer(100, unit="ps")
    dut.r.value = 0
    await Timer(100, unit="ps")
    assert_outputs(dut, ready=1)
    monitor_task.cancel()


async def ddr_trace(dut, params, trace):
    drive(dut, c=0, ce=1, d1=0, d2=1, r=0, s=0)
    await Timer(5000, unit="ps")
    random_state = 0x831AD
    for index in range(200):
        random_state = (random_state * 1664525 + 1013904223) & 0xFFFFFFFF
        reset_bits = (random_state >> 5) & 7
        set_bits = (random_state >> 8) & 7
        drive(
            dut,
            ce="X" if random_state & 15 == 0 else (random_state >> 4) & 1,
            r="X" if reset_bits == 0 else int(reset_bits == 1),
            s="Z" if set_bits == 0 else int(set_bits == 1),
            d1=(random_state >> 11) & 1,
            d2=(random_state >> 12) & 1,
        )
        await Timer(10, unit="ps")
        trace.append(["controls", index, str(dut.q1.value) + str(dut.q2.value) + str(dut.q.value)])
        dut.c.value = 1 - int(dut.c.value)
        await Timer(10, unit="ps")
        trace.append(["edge", index, str(dut.q1.value) + str(dut.q2.value) + str(dut.q.value)])


async def toggle_clock(signal, half_period_ns):
    signal.value = 0
    while True:
        await Timer(half_period_ns, unit="ns")
        signal.value = 1 - int(signal.value)


async def pll_metrics(dut, params, trace):
    drive(dut, clock=0, reset=1, powerdown=0)
    clock_task = cocotb.start_soon(toggle_clock(dut.clock, 5))
    last = [0] * 6
    periods = [0] * 6
    high_times = [0] * 6

    async def monitor():
        previous = "XXXXXX"
        while True:
            await Edge(dut.clocks)
            await ReadOnly()
            current = str(dut.clocks.value).upper()
            time = int(get_sim_time(unit="ps"))
            for index in range(6):
                bit = current[-1 - index]
                old = previous[-1 - index]
                if bit == "1" and old != "1":
                    periods[index] = time - last[index]
                    last[index] = time
                elif bit == "0" and old != "0":
                    high_times[index] = time - last[index]
            previous = current

    monitor_task = cocotb.start_soon(monitor())
    await Timer(200000, unit="ps")
    dut.reset.value = 0
    await Timer(20000000, unit="ps")
    assert_outputs(dut, locked=1)
    for index in range(6):
        assert periods[index] == (index + 1) * 2000, (index, periods)
        trace.append(["output", index, periods[index], high_times[index]])
    phase = (last[2] + 6000 - last[0]) % 2000
    assert phase == 1500, phase
    assert high_times[1] == 1000, high_times
    trace.append(["phase", phase])
    dut.powerdown.value = 1
    await Timer(200000, unit="ps")
    assert_outputs(dut, locked=0)
    monitor_task.cancel()
    clock_task.cancel()


async def clock_primitives(dut, params, trace):
    drive(dut, powerdown=0, refclk=0, refclk_n=1, pll_reset=1)
    stopped = False
    counts = [0, 0]

    async def reference_clock():
        while True:
            await Timer(5, unit="ns")
            if not stopped:
                drive(dut, refclk=1 - int(dut.refclk.value), refclk_n=1 - int(dut.refclk_n.value))

    async def count_edges(signal, index):
        while True:
            await RisingEdge(signal)
            counts[index] += 1

    clock_task = cocotb.start_soon(reference_clock())
    counter_tasks = [cocotb.start_soon(count_edges(dut.pll_clk0, 0)), cocotb.start_soon(count_edges(dut.pll_clk1, 1))]

    async def locked():
        if str(dut.pll_locked.value) != "1":
            await with_timeout(RisingEdge(dut.pll_locked), 5000, "ns")

    async def frequencies():
        before = counts.copy()
        await Timer(200, unit="ns")
        delta = [counts[index] - before[index] for index in range(2)]
        assert 19 <= delta[0] <= 21, delta
        assert 79 <= delta[1] <= 81, delta

    await Timer(1, unit="ns")
    assert str(dut.gte_clk.value) == str(dut.refclk.value)
    await Timer(29, unit="ns")
    dut.pll_reset.value = 0
    await locked()
    await frequencies()
    for level in (0, 1):
        await (RisingEdge(dut.refclk) if level else FallingEdge(dut.refclk))
        await Timer(1, unit="ps")
        stopped = True
        await Timer(40, unit="ns")
        assert_outputs(dut, pll_locked=0)
        stopped = False
        await Timer(100, unit="ns")
        assert_outputs(dut, pll_locked=0)
        dut.pll_reset.value = 1
        await Timer(30, unit="ns")
        dut.pll_reset.value = 0
        await locked()
        await frequencies()
    dut.powerdown.value = 1
    await Timer(40, unit="ns")
    assert_outputs(dut, pll_locked=0, pll_clk0=0)
    dut.powerdown.value = 0
    await locked()
    dut.pll_reset.value = 1
    await Timer(40, unit="ns")
    assert_outputs(dut, pll_locked=0, pll_clk0=0)
    dut.pll_reset.value = 0
    await locked()
    clock_task.cancel()
    for task in counter_tasks:
        task.cancel()


async def divided_clock(signal, frame_ns, first_rise_ns=5):
    signal.value = 0
    await Timer(first_rise_ns, unit="ns")
    signal.value = 1
    while True:
        await Timer(frame_ns / 2, unit="ns")
        signal.value = 1 - int(signal.value)


async def repeat_edges(signal, count):
    for _ in range(count):
        await RisingEdge(signal)


async def serializer_words(dut, params, trace):
    width = params["DataWidth"]
    rate = params["DataRate"]
    step = 5 if rate == "DDR" else 10
    patterns = [0x101, 0x202, 0x155, 0x2AA]
    drive(dut, clk=0, clkdiv=0, reset=1, enable=1, data=patterns[0])
    tasks = [
        cocotb.start_soon(toggle_clock(dut.clk, 5)),
        cocotb.start_soon(divided_clock(dut.clkdiv, step * width, 5 + params["DivPhase"])),
    ]

    async def sample():
        await (Edge(dut.clk) if rate == "DDR" else RisingEdge(dut.clk))
        # Sample after the vendor's output propagation delay.
        await Timer(1, unit="ns")
        return int(dut.serial_data.value)

    def phase():
        return (int(get_sim_time(unit="ps")) // (step * 1000)) % width

    for _ in range(2):
        word_phase = None
        await repeat_edges(dut.clkdiv, 4)
        await Timer(1, unit="ns")
        dut.reset.value = 0
        for expected in patterns:
            await FallingEdge(dut.clkdiv)
            await Timer(1, unit="ns")
            dut.data.value = expected
            await repeat_edges(dut.clkdiv, 4)
            if word_phase is None:
                received = 0
                for attempt in range(1, 3 * width + 1):
                    received = (received >> 1) | ((await sample()) << (width - 1))
                    if attempt >= width and received == expected & ((1 << width) - 1):
                        word_phase = phase()
                        break
                assert word_phase is not None, f"Could not find serialized word {expected:x}"
            else:
                await sample()
                while phase() != word_phase:
                    await sample()
            for _ in range(8):
                for index in range(width):
                    actual = await sample()
                    assert actual == (expected >> index) & 1, (expected, index, actual)
            trace.append(["word", expected])
        dut.enable.value = 0
        await repeat_edges(dut.clkdiv, 4)
        await Timer(1, unit="ns")
        held = str(dut.serial_data.value)
        for _ in range(2 * width):
            await Timer(step, unit="ns")
            assert str(dut.serial_data.value) == held, "OCE did not hold output"
        drive(dut, enable=1, reset=1)
        await repeat_edges(dut.clkdiv, 2)
        await Timer(1, unit="ns")
        assert_outputs(dut, serial_data=0)
        drive(dut, enable=1, data=patterns[0])
    for task in tasks:
        task.cancel()


async def serializer_tristate(dut, params, trace):
    width = params["TristateWidth"]
    rate = params["TristateRate"]
    frame = 20 if params["DataRate"] == "DDR" else 40
    drive(dut, clk=0, clkdiv=0, reset=1, enable=0, tristate_data=0)
    tasks = [cocotb.start_soon(toggle_clock(dut.clk, 5)), cocotb.start_soon(divided_clock(dut.clkdiv, frame))]

    async def sample():
        await Edge(dut.clk)
        await Timer(1, unit="ns")
        return int(dut.tq.value)

    def phase():
        return (int(get_sim_time(unit="ps")) // 5000) % 4

    await repeat_edges(dut.clkdiv, 4)
    await Timer(1, unit="ns")
    assert_outputs(dut, byte_output=1)
    if rate == "BUF":
        dut.tristate_data.value = 1
        await Timer(1, unit="ns")
        assert_outputs(dut, tq=1, tfb=1)
        dut.tristate_data.value = 0
        await Timer(1, unit="ns")
        assert_outputs(dut, tq=0)
    else:
        drive(dut, reset=0, enable=1)
        word_phase = None
        for expected in (0b1001, 0b0010, 0b1101, 0b0110):
            await FallingEdge(dut.clkdiv)
            await Timer(1, unit="ns")
            dut.tristate_data.value = expected
            await repeat_edges(dut.clkdiv, 4)
            if width == 4:
                if word_phase is None:
                    received = 0
                    for attempt in range(1, 13):
                        received = (received >> 1) | ((await sample()) << 3)
                        if attempt >= 4 and received == expected:
                            word_phase = phase()
                            break
                    assert word_phase is not None, f"Could not find tristate word {expected:04b}"
                else:
                    await sample()
                    while phase() != word_phase:
                        await sample()
                for _ in range(8):
                    for index in range(4):
                        actual = await sample()
                        assert actual == (expected >> index) & 1, (expected, index, actual)
            else:
                await Timer(1, unit="ns")
                assert_outputs(dut, tq=expected & 1)
            assert_outputs(dut, oq=0, tfb=str(dut.tq.value))
            trace.append(["tristate", expected])
        dut.enable.value = 0
        await repeat_edges(dut.clkdiv, 4)
        await Timer(1, unit="ns")
        held = str(dut.tq.value)
        for _ in range(8):
            await sample()
            assert str(dut.tq.value) == held, "TCE did not hold TQ"
        drive(dut, enable=1, reset=1)
        await repeat_edges(dut.clkdiv, 2)
        await Timer(1, unit="ns")
        assert_outputs(dut, tq=0)
    for task in tasks:
        task.cancel()


async def serializer_attributes(dut, params, trace):
    rate = params["TristateRate"]
    drive(dut, clock=0, divided_clock=0, reset=0, data_enable=0, tristate_enable=0, data=0, tristate_data=1)
    tasks = [cocotb.start_soon(toggle_clock(dut.clock, 5)), cocotb.start_soon(toggle_clock(dut.divided_clock, 10))]

    def check(data, tristate):
        assert_outputs(
            dut,
            output_data=data,
            output_feedback=data,
            output_tristate=tristate,
            tristate_feedback=tristate,
            byte_output=1,
        )
        trace.append(["attributes", data, tristate, 1])

    await Timer(200000, unit="ps")
    check(1, 0)
    dut.reset.value = 1
    await Timer(100000, unit="ps")
    check(0, 0 if rate == "BUF" else 1)
    await RisingEdge(dut.divided_clock)
    await Timer(1000, unit="ps")
    drive(dut, reset=0, data_enable=1, tristate_enable=1)
    await Timer(100000, unit="ps")
    check(1, 0)
    drive(dut, data_enable=0, tristate_enable=0, data=1, tristate_data=0)
    await Timer(100000, unit="ps")
    check(1, 1 if rate == "BUF" else 0)
    for task in tasks:
        task.cancel()


SCENARIOS = {
    "test_SimIddr": iddr,
    "test_SimOddr": oddr,
    "test_Sim7seriesBuffers": buffers,
    "test_Sim7seriesDelays": delays,
    "test_SimGteReceiver": gte_receiver,
    "test_SimDelayControl": delay_control,
    "test_SimDdrTrace": ddr_trace,
    "test_Sim7seriesPllAccuracy": pll_metrics,
    "test_Sim7seriesClockPrimitives": clock_primitives,
    "test_SimOserdes": serializer_words,
    "test_SimOserdesTristate": serializer_tristate,
    "test_Sim7seriesSerializerAttributes": serializer_attributes,
}


@cocotb.test(timeout_time=100, timeout_unit="us")
async def functional(dut):
    params = json.loads(Path("parameters.json").read_text())
    trace = []
    await SCENARIOS[dut._name](dut, params, trace)
    Path("trace.json").write_text(json.dumps(trace))
