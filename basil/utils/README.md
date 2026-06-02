# Basil Bus Checker

Run the checker with one or more Basil YAML files followed by the Verilog/SystemVerilog files that define the bus address parameters:

```bash
python -m basil.utils.buscheck path/to/config.yaml path/to/top.v path/to/core.sv
```

The command exits with status `1` for address-map problems such as overlaps, YAML entries missing in Verilog, or range mismatches. Verilog modules missing from YAML are printed as warnings only, because they may be accessed directly instead of through Basil YAML.
