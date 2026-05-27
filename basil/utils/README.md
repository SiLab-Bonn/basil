# buscheck examples

Run these from the root of a cloned `basil` repository. The examples assume the DAQ repositories are checked out next to `basil`, so paths use `../<daq_dir>/...`.

```bash
python -m basil.utils.buscheck ../bdaq53/bdaq53/system/bdaq53.yaml ../bdaq53/firmware/src/bdaq53.v ../bdaq53/firmware/src/bdaq53_core.v
python -m basil.utils.buscheck ../obelix1-daq/obelix1/system/DAQ.yaml ../obelix1-daq/firmware/src/obelix1.v ../obelix1-daq/firmware/src/obelix1_core.v ../obelix1-daq/obelix1/tests/test_hardware/tb_obelix_and_daq.sv
python -m basil.utils.buscheck ../tj-monopix2-daq/tjmonopix2/system/bdaq53.yaml ../tj-monopix2-daq/firmware/src/tjmonopix2_core.v
python -m basil.utils.buscheck ../frida/flow/scans/map_fpga.yaml ../frida/design/fpga/daq_core.v
```
