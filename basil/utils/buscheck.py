"""Compare basil YAML bus addresses with Verilog bus address parameters.

Usage:
    python -m basil.utils.buscheck path/to/config.yaml path/to/top.v [more files]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

VERILOG_LITERAL = re.compile(r"\b\d+'[sS]?([bBoOdDhH])([0-9a-fA-F_xXzZ]+)")
VERILOG_PARAM = re.compile(
    r"\b(?:localparam|parameter)\b(?:\s+(?:integer|int|logic|reg|wire))?"
    r"(?:\s*\[[^]]+\])?\s+([A-Za-z_]\w*)\s*=\s*([^;,]+)",
    re.S,
)
VERILOG_INSTANCE = re.compile(
    r"(?<!module )\b([A-Za-z_]\w*)\s*#\s*\((.*?)\)\s+([A-Za-z_]\w*)\s*\(",
    re.S,
)
VERILOG_LOOP = re.compile(
    r"for\s*\(\s*(?:genvar\s+)?([A-Za-z_]\w*)\s*=\s*([^;]+);"
    r"\s*\1\s*<\s*([^;]+);\s*\1\s*=\s*\1\s*\+\s*([^;)]+)\s*\)",
    re.S,
)
VERILOG_ARGUMENT = re.compile(r"\.([A-Za-z_]\w*)\s*\(")


# Step 2: Parse Basil YAML files into address-map entries.
def parse_yaml(paths: list[Path]) -> list[dict]:
    entries = []
    # Multiple YAML files may describe one combined design.
    for path in paths:
        data = yaml.safe_load(path.read_text()) or {}
        for driver in data.get("hw_drivers", []):
            # Non-dictionary entries cannot be Basil hardware driver definitions.
            if not isinstance(driver, dict):
                continue

            name = str(driver.get("name", "unnamed"))
            kind = str(driver.get("type", ""))
            # A driver can expose a control address and, for FIFO-like blocks, a separate data address.
            for base_key, high_key, suffix in (
                ("base_addr", "high_addr", ""),
                ("base_data_addr", "high_data_addr", ":data"),
            ):
                # Drivers without this address key are not part of this bus map.
                if base_key not in driver:
                    continue
                high = None
                # Basil YAML usually only gives base_addr, but allow explicit high_addr when present.
                if high_key in driver:
                    high = int(str(driver[high_key]).replace("_", ""), 0)
                entries.append(
                    {
                        "source": str(path),
                        "name": name + suffix,
                        "kind": kind,
                        "base": int(str(driver[base_key]).replace("_", ""), 0),
                        "high": high,
                        "line": None,
                    }
                )
    return entries


# Step 3 helper: Evaluate simple Verilog arithmetic used in address parameters.
def eval_expr(expr: str, values: dict[str, int]) -> int | None:
    expr = expr.strip()
    # Convert Verilog literals like 32'h1000 into Python integers before evaluation.
    match = VERILOG_LITERAL.search(expr)
    while match:
        base = {"b": 2, "o": 8, "d": 10, "h": 16}[match.group(1).lower()]
        digits = match.group(2).replace("_", "")
        digits = digits.replace("x", "0").replace("X", "0")
        digits = digits.replace("z", "0").replace("Z", "0")
        expr = expr[: match.start()] + str(int(digits, base)) + expr[match.end() :]
        match = VERILOG_LITERAL.search(expr)

    # Substitute already-resolved parameters, then reject anything not simple arithmetic.
    for name, value in values.items():
        expr = re.sub(rf"\b{name}\b", str(value), expr)
    if not re.fullmatch(r"[0-9\s()+\-*/%<>&|^~.]+", expr):
        return None

    try:
        return int(eval(expr, {"__builtins__": {}}, {}))
    except (SyntaxError, NameError, TypeError, ValueError, ZeroDivisionError):
        return None


# Step 3 helper: Remove Verilog comments before regex parsing.
def strip_comments(text: str) -> str:
    text = re.sub(r"//.*", "", text)
    # Preserve newlines inside block comments so line numbers still point at the source.
    block_comment = re.search(r"/\*.*?\*/", text, flags=re.S)
    while block_comment:
        replacement = "".join("\n" if char == "\n" else " " for char in block_comment.group(0))
        text = text[: block_comment.start()] + replacement + text[block_comment.end() :]
        block_comment = re.search(r"/\*.*?\*/", text, flags=re.S)
    return text


# Step 3 helper: Read resolvable Verilog parameter/localparam values.
def read_values(text: str) -> dict[str, int]:
    values = {}
    pending = []
    for match in VERILOG_PARAM.finditer(text):
        pending.append((match.group(1), match.group(2).strip()))

    # Resolve parameters iteratively because later parameters may depend on earlier ones.
    for _ in range(len(pending) + 1):
        changed = False
        for name, expr in pending:
            # Skip values that were resolved in a previous pass.
            if name in values:
                continue
            value = eval_expr(expr, values)
            # Unresolved expressions may depend on parameters that are not known yet.
            if value is not None:
                values[name] = value
                changed = True
        # Stop once a full pass fails to resolve anything new.
        if not changed:
            break
    return values


# Step 3 helper: Read simple generate-for loop ranges.
def read_loops(text: str, values: dict[str, int]) -> dict[str, list[int]]:
    loops = {}
    # Only simple generate-for loops can be expanded without a real Verilog parser.
    for match in VERILOG_LOOP.finditer(text):
        loop_name, start_expr, stop_expr, step_expr = match.groups()
        start = eval_expr(start_expr, values)
        stop = eval_expr(stop_expr, values)
        step = eval_expr(step_expr, values)
        # Ignore loop bounds that cannot be resolved from local parameters.
        if start is not None and stop is not None and step is not None and step > 0:
            loops[loop_name] = list(range(start, stop, step))
    return loops


# Step 3 helper: Read named Verilog instance parameter assignments.
def read_params(param_text: str) -> dict[str, str]:
    params = {}
    # Parameter values may contain parentheses, so scan to the matching closing parenthesis.
    for arg in VERILOG_ARGUMENT.finditer(param_text):
        depth = 1
        pos = arg.end()
        while pos < len(param_text) and depth:
            depth += int(param_text[pos] == "(") - int(param_text[pos] == ")")
            pos += 1
        # Ignore malformed argument lists where no matching parenthesis was found.
        if depth == 0:
            params[arg.group(1).upper()] = param_text[arg.end() : pos - 1].strip()
    return params


# Step 3 helper: Expand simple generated instances into concrete loop values.
def loop_variants(
    param_text: str, values: dict[str, int], loops: dict[str, list[int]]
) -> list[tuple[str, dict[str, int]]]:
    variants = [("", values)]
    # Start with the non-generated case, then add expanded variants for matching loops.
    for loop_name, loop_values in loops.items():
        if loop_name in param_text:
            for value in loop_values:
                variants.append((f"[{loop_name}={value}]", values | {loop_name: value}))
    return variants


# Step 3 helper: Read Verilog module instantiations with BASEADDR parameters.
def read_entries(path: Path, text: str, values: dict[str, int], loops: dict[str, list[int]]) -> list[dict]:
    entries = []
    for match in VERILOG_INSTANCE.finditer(text):
        # The instantiation regex can also see module declarations; skip those.
        if re.search(r"\bmodule\s+$", text[max(0, match.start() - 32) : match.start()]):
            continue

        kind, param_text, name = match.group(1), match.group(2), match.group(3)
        params = read_params(param_text)
        line = text.count("\n", 0, match.start()) + 1

        # Each instance can have a normal bus address and optionally a separate data address.
        for suffix, variant_values in loop_variants(param_text, values, loops):
            for base_key, high_key, name_suffix in (
                ("BASEADDR", "HIGHADDR", ""),
                ("BASEADDR_DATA", "HIGHADDR_DATA", ":data"),
            ):
                # Ignore instances that do not participate in the Basil bus address map.
                if base_key not in params:
                    continue
                base = eval_expr(params[base_key], variant_values)
                high = eval_expr(params[high_key], variant_values) if high_key in params else None
                # Keep unresolved addresses out of the map rather than guessing.
                if base is None:
                    continue
                entries.append(
                    {
                        "source": str(path),
                        "name": name + suffix + name_suffix,
                        "kind": kind,
                        "base": base,
                        "high": high,
                        "line": line,
                    }
                )
    return entries


# Step 4/5 helper: Format one address entry for reports and problem messages.
def fmt_range(entry: dict) -> str:
    # Basil YAML often gives only a base address; print that as a single address.
    if entry["high"] is None or entry["high"] == entry["base"]:
        return f"0x{entry['base']:x}"
    return f"0x{entry['base']:x}-0x{entry['high']:x}"


# Step 4 helper: Find overlaps inside one address map.
def compare_overlaps(title: str, entries: list[dict]) -> list[str]:
    problems = []
    # Compare every pair in one map to catch accidental overlapping decode ranges.
    for index, a in enumerate(entries):
        a_end = a["base"] if a["high"] is None else a["high"]
        for b in entries[index + 1 :]:
            b_end = b["base"] if b["high"] is None else b["high"]
            # Ranges overlap if each range starts before the other range ends.
            if a["base"] <= b_end and b["base"] <= a_end:
                problems.append(f"{title} overlap: {a['name']} {fmt_range(a)} overlaps {b['name']} {fmt_range(b)}")
    return problems


# Step 4 helper: Check each YAML address exists in Verilog.
def compare_yaml_to_verilog(yaml_entries: list[dict], verilog_entries: list[dict]) -> list[str]:
    problems = []
    # Index Verilog entries by base address so YAML entries can be checked directly.
    verilog_by_base = {}
    for entry in verilog_entries:
        verilog_by_base.setdefault(entry["base"], []).append(entry)

    for entry in yaml_entries:
        same_base = verilog_by_base.get(entry["base"], [])
        # If no Verilog entry has this base address, the YAML map cannot match.
        if not same_base:
            problems.append(f"missing in Verilog: {entry['name']} {fmt_range(entry)}")
            continue

        # If both sides provide high addresses, require them to agree.
        exact = False
        for other in same_base:
            if entry["high"] is None or other["high"] is None or other["high"] == entry["high"]:
                exact = True
        if not exact:
            ranges = ", ".join(fmt_range(other) for other in same_base)
            problems.append(f"range mismatch: YAML {entry['name']} {fmt_range(entry)}; Verilog has {ranges}")
    return problems


# Step 4 helper: Check each Verilog address exists in YAML.
def compare_verilog_to_yaml(yaml_entries: list[dict], verilog_entries: list[dict]) -> list[str]:
    problems = []
    # Report Verilog blocks that have no YAML entry at the same base address.
    for entry in verilog_entries:
        found = False
        for other in yaml_entries:
            if other["base"] == entry["base"]:
                found = True
        if not found:
            problems.append(f"missing in YAML: {entry['name']} {fmt_range(entry)}")
    return problems


# Step 5: Print the address maps and any mismatches.
def print_report(yaml_entries: list[dict], verilog_entries: list[dict], problems: list[str]) -> None:
    # Print YAML first, then Verilog, so mismatches can be compared visually.
    for title, entries in (("YAML", yaml_entries), ("Verilog", verilog_entries)):
        print(f"{title}:")
        if not entries:
            print("  (none)")
            continue

        # Sort by address for a stable address-map table.
        rows = []
        for entry in entries:
            rows.append((entry["base"], entry["name"], entry))
        rows.sort()

        for _, _, entry in rows:
            where = entry["source"]
            if entry["line"] is not None:
                where += f":{entry['line']}"
            print(f"  {fmt_range(entry):>23}  {entry['name']:<32} {entry['kind']:<28} {where}")

    # A non-empty problem list also controls the process exit status in main().
    if problems:
        print("Problems:")
        for problem in problems:
            print(f"  - {problem}")
    else:
        print("Address maps match.")


# Step 1 helper: Classify command-line paths by file type.
def split_paths(paths):
    yaml_paths = []
    verilog_paths = []
    unknown_paths = []
    # The CLI accepts an arbitrary ordering of YAML and Verilog paths.
    for path in paths:
        suffix = path.suffix.lower()
        if suffix in {".yaml", ".yml"}:
            yaml_paths.append(path)
        elif suffix in {".v", ".sv", ".vh", ".svh"}:
            verilog_paths.append(path)
        else:
            unknown_paths.append(path)
    return yaml_paths, verilog_paths, unknown_paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="+", type=Path, help="YAML and Verilog/SystemVerilog files to compare")
    args = parser.parse_args(argv)

    # Step 1: Split and validate command-line file arguments.
    yaml_paths, verilog_paths, unknown_paths = split_paths(args.files)
    # Fail early if the command line cannot produce a meaningful comparison.
    if unknown_paths:
        parser.error("unknown file type: " + ", ".join(str(path) for path in unknown_paths))
    if not yaml_paths or not verilog_paths:
        parser.error("provide at least one YAML file and one Verilog/SystemVerilog file")
    # Validate paths after type checks so missing files still get a clear error.
    for path in args.files:
        if not path.is_file():
            parser.error(f"file not found: {path}")

    # Step 2: Parse Basil YAML address entries.
    yaml_entries = parse_yaml(yaml_paths)

    # Step 3: Parse Verilog address entries.
    verilog_entries = []
    for path in verilog_paths:
        text = strip_comments(path.read_text())
        values = read_values(text)
        loops = read_loops(text, values)
        verilog_entries += read_entries(path, text, values, loops)

    # Generated branches can produce duplicate addresses; keep one row per range.
    unique = {}
    for entry in verilog_entries:
        unique.setdefault((entry["source"], entry["base"], entry["high"]), entry)
    verilog_entries = list(unique.values())

    # Step 4: Compare YAML and Verilog address maps.
    problems = []
    problems += compare_overlaps("YAML", yaml_entries)
    problems += compare_overlaps("Verilog", verilog_entries)
    problems += compare_yaml_to_verilog(yaml_entries, verilog_entries)
    problems += compare_verilog_to_yaml(yaml_entries, verilog_entries)

    # Step 5: Print the report and return a shell-friendly status code.
    print_report(yaml_entries, verilog_entries, problems)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
