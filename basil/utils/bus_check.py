#!/usr/bin/env python3
"""
Basil Bus Address Map Generator and Verification Tool

This utility:
1. Parses Verilog modules to extract default BASEADDR/HIGHADDR parameters
2. Parses YAML configuration files to extract configured addresses
3. Cross-checks Verilog defaults against YAML configurations
4. Detects address range overlaps
5. Generates markdown tables and ASCII diagrams of the address map

Usage:
    # As a module
    python -m basil.utils.check_bus

    # With custom paths
    python -m basil.utils.check_bus --verilog-glob "basil/firmware/modules/**/*.v" \
        --yaml-glob "examples/**/*.yaml"

    # As pre-commit hook
    python -m basil.utils.check_bus --quiet
"""

import argparse
import glob
import re
import sys
from pathlib import Path
from collections import defaultdict

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


def parse_verilog_modules(verilog_glob, base_dir=None):
    """
    Extract module names and address parameters from Verilog files.

    This parses:
    1. Module declarations with BASEADDR/HIGHADDR parameters
    2. Localparam/parameter definitions (e.g., SEQ_GEN_BASEADDR = 32'h10000)
    3. Module instantiations with .BASEADDR()/.HIGHADDR() parameter assignments

    Args:
        verilog_glob: Glob pattern for Verilog files
        base_dir: Base directory for relative paths (default: current dir)

    Returns:
        dict: {module_name: {baseaddr, highaddr, file, line, instantiation_name, type}}
    """
    if base_dir is None:
        base_dir = Path.cwd()
    else:
        base_dir = Path(base_dir)

    modules = {}

    for v_path in Path(base_dir).glob(verilog_glob):
        if not v_path.is_file():
            continue

        try:
            with open(v_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except (IOError, UnicodeDecodeError):
            continue

        # First pass: Find all localparam/parameter definitions that look like addresses
        # These are typically named *BASEADDR or *HIGHADDR
        # Build a dict of name -> raw value string first
        localparam_defs = {}
        param_pattern = re.compile(
            r'^(?:\s*)?(?:localparam|parameter)\s+(?:integer\s+)?(\w+)\s*=\s*([^;]+);',
            re.MULTILINE | re.IGNORECASE
        )

        for match in param_pattern.finditer(content):
            param_name = match.group(1)
            param_value_expr = match.group(2).strip()

            # Only care about params that look like address parameters
            if 'ADDR' in param_name.upper():
                localparam_defs[param_name] = param_value_expr

        # Now resolve all localparam values (handle references to other localparams)
        localparams = {}
        for param_name, param_value_expr in localparam_defs.items():
            value = resolve_verilog_expression(param_value_expr, content, localparams)
            if value is not None:
                localparams[param_name] = value
            else:
                # Try to parse directly as a literal
                try:
                    localparams[param_name] = parse_verilog_value(param_value_expr)
                except (ValueError, AttributeError):
                    pass

        # Second pass: Find all module declarations with BASEADDR/HIGHADDR parameters
        module_pattern = re.compile(
            r'module\s+(\w+)\s*#\s*\((.*?)\)\s*\([^)]*\)',
            re.DOTALL
        )

        for match in module_pattern.finditer(content):
            module_name = match.group(1)
            params_block = match.group(2)

            # Extract BASEADDR and HIGHADDR
            baseaddr = None
            highaddr = None

            for param_match in re.finditer(
                r'parameter\s+(BASEADDR|HIGHADDR)\s*=\s*(\w+)',
                params_block,
                re.IGNORECASE
            ):
                param_name = param_match.group(1).upper()
                param_value_str = param_match.group(2)
                value = parse_verilog_value(param_value_str)

                if param_name == "BASEADDR":
                    baseaddr = value
                elif param_name == "HIGHADDR":
                    highaddr = value

            if baseaddr is not None:
                modules[module_name] = {
                    'file': str(v_path.relative_to(base_dir)),
                    'baseaddr': baseaddr,
                    'highaddr': highaddr if highaddr is not None else baseaddr,
                    'type': 'verilog',
                    'instantiation_name': None
                }

        # Third pass: Find module instantiations with BASEADDR/HIGHADDR
        # We need to search inside module bodies only, not module declarations.
        # Strategy: Find each module body (between 'module' and 'endmodule'),
        # then search for instantiations within it.

        module_body_pattern = re.compile(
            r'module\s+\w+[^;]*;(.+?)endmodule',
            re.DOTALL
        )

        for body_match in module_body_pattern.finditer(content):
            module_body = body_match.group(1)
            body_offset = body_match.start(1)

            # Find instantiations within this module body
            # Pattern: module_type #( ... ) instance_name (
            inst_decl_pattern = re.compile(
                r'(\w+)\s*#\s*\((.*?)\)\s+(\w+)\s*\(',
                re.DOTALL
            )

            for match in inst_decl_pattern.finditer(module_body):
                module_type = match.group(1)
                params_block = match.group(2)
                instance_name = match.group(3)

                # Now parse the params_block for BASEADDR and HIGHADDR
                baseaddr = None
                highaddr = None

                # Look for .BASEADDR(value) or .BASEADDR (value)
                baseaddr_match = re.search(
                    r'\.BASEADDR\s*\(([^)]+)\)',
                    params_block,
                    re.IGNORECASE
                )
                if baseaddr_match:
                    baseaddr_expr = baseaddr_match.group(1).strip()
                    baseaddr = resolve_verilog_expression(baseaddr_expr, content, localparams)

                # Look for .HIGHADDR(value) or .HIGHADDR (value)
                highaddr_match = re.search(
                    r'\.HIGHADDR\s*\(([^)]+)\)',
                    params_block,
                    re.IGNORECASE
                )
                if highaddr_match:
                    highaddr_expr = highaddr_match.group(1).strip()
                    highaddr = resolve_verilog_expression(highaddr_expr, content, localparams)

                if baseaddr is not None:
                    modules[instance_name] = {
                        'file': str(v_path.relative_to(base_dir)),
                        'baseaddr': baseaddr,
                        'highaddr': highaddr if highaddr is not None else baseaddr,
                        'type': module_type,
                        'instantiation_name': instance_name
                    }

    return modules


def resolve_verilog_expression(expr, content, localparams=None):
    """
    Resolve a Verilog expression to an integer value.

    Handles:
    - Literal values: 32'h10000, 16'h0000, etc.
    - Localparam references: SEQ_GEN_BASEADDR
    - Simple identifiers that might be defined elsewhere

    Args:
        expr: The expression string to resolve
        content: Full Verilog file content for localparam lookup
        localparams: Optional dict of already-parsed localparams for faster lookup

    Returns:
        int or None if cannot be resolved
    """
    expr = expr.strip()

    # If it's a simple identifier, look for localparam definitions first
    # (before trying literal parse, which would return 0 for identifiers)
    if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', expr):
        # Check pre-parsed localparams first
        if localparams and expr in localparams:
            return localparams[expr]

        # Look for localparam or parameter definitions in content
        param_pattern = re.compile(
            rf'^(?:localparam|parameter)\s+(?:integer\s+)?{expr}\s*=\s*([^;]+);',
            re.MULTILINE | re.IGNORECASE
        )
        match = param_pattern.search(content)
        if match:
            param_value_expr = match.group(1).strip()
            # Recursively resolve the value expression
            return resolve_verilog_expression(param_value_expr, content, localparams)

    # Try to parse as a literal value
    try:
        value = parse_verilog_value(expr)
        # parse_verilog_value returns 0 for unparseable identifiers,
        # so we need to distinguish between actual 0 and failed parse
        if value == 0 and not re.match(r'^\s*(0+|0x0+|\d+\'[hdb]0+)\s*$', expr, re.IGNORECASE):
            return None
        return value
    except (ValueError, AttributeError):
        pass

    return None


def parse_verilog_value(value_str):
    """
    Parse a Verilog parameter value string into an integer.

    Handles formats like:
    - 16'h0000
    - 8'hFF
    - 32'd1024
    - 1024
    - 32'h10000
    """
    value_str = value_str.strip()

    # Hex with width prefix: 16'h0000, 8'hFF, 32'h10000
    hex_match = re.match(r'\d+\'h([0-9a-fA-F]+)', value_str)
    if hex_match:
        return int(hex_match.group(1), 16)

    # Decimal with width prefix: 32'd1024
    dec_match = re.match(r'\d+\'d(\d+)', value_str)
    if dec_match:
        return int(dec_match.group(1), 10)

    # Binary with width prefix: 8'b1010
    bin_match = re.match(r'\d+\'b([01]+)', value_str)
    if bin_match:
        return int(bin_match.group(1), 2)

    # Plain hex: h0000, 'h0000
    if value_str.startswith("h") or value_str.startswith("'h"):
        hex_str = value_str[2:] if value_str.startswith("h") else value_str[1:]
        return int(hex_str, 16)

    # Plain decimal
    try:
        return int(value_str, 10)
    except ValueError:
        # If we can't parse it, return 0
        return 0


def parse_yaml_configs(yaml_glob, base_dir=None):
    """
    Extract hw_drivers and their addresses from YAML files.

    Args:
        yaml_glob: Glob pattern for YAML files
        base_dir: Base directory for relative paths

    Returns:
        dict: {driver_type: [{name, base_addr, size, high_addr, file, line}]}
    """
    if not HAS_YAML:
        print("Error: PyYAML is required. Install with: pip install pyyaml", file=sys.stderr)
        sys.exit(1)

    if base_dir is None:
        base_dir = Path.cwd()
    else:
        base_dir = Path(base_dir)

    drivers = defaultdict(list)

    for yaml_path in Path(base_dir).glob(yaml_glob):
        if not yaml_path.is_file():
            continue

        try:
            with open(yaml_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
        except (yaml.YAMLError, IOError):
            continue

        if not config or not isinstance(config, dict):
            continue

        if 'hw_drivers' in config:
            for idx, driver in enumerate(config['hw_drivers']):
                if not isinstance(driver, dict):
                    continue
                if 'base_addr' not in driver or 'type' not in driver:
                    continue

                driver_type = driver['type']
                base_addr = driver['base_addr']
                # Handle both 'size' and 'mem_size' - mem_size is the address range, size is register size
                size = driver.get('size', driver.get('mem_size', 0))

                # Handle string hex addresses like "0x10000"
                if isinstance(base_addr, str):
                    if base_addr.startswith('0x'):
                        base_addr = int(base_addr, 16)
                    else:
                        base_addr = int(base_addr, 10)

                if isinstance(size, str):
                    if size.startswith('0x'):
                        size = int(size, 16)
                    else:
                        size = int(size, 10)

                high_addr = base_addr + size - 1 if size > 0 else base_addr

                entry = {
                    'file': str(yaml_path.relative_to(base_dir)),
                    'name': driver.get('name', f'unnamed_{idx}'),
                    'type': driver_type,
                    'base_addr': base_addr,
                    'size': size,
                    'high_addr': high_addr,
                    'yaml_type': 'hw_driver'
                }
                drivers[driver_type].append(entry)

    return drivers


def generate_address_map(verilog_modules, yaml_drivers):
    """
    Generate address map from Verilog and cross-check against YAML.

    The table is built from Verilog modules. For each Verilog module, we try to
    find a matching YAML driver by module type. If found, we verify the addresses
    match. If not found, we warn that the YAML config is missing.

    Args:
        verilog_modules: Dict of Verilog modules from parse_verilog_modules
        yaml_drivers: Dict of YAML drivers from parse_yaml_configs

    Returns:
        tuple: (address_map_list, issues_list)
    """
    address_map = []
    issues = []

    # Build lookup structures for YAML drivers
    # yaml_by_type: {module_type: [driver1, driver2, ...]}
    yaml_by_type = {}
    for driver_type, driver_list in yaml_drivers.items():
        yaml_by_type[driver_type] = driver_list

    # Track which YAML drivers have been matched to Verilog
    matched_yaml = set()

    # Process Verilog modules - this is the primary data source
    for module_name, module_info in verilog_modules.items():
        module_type = module_info.get('type', module_name)
        v_base = module_info['baseaddr']
        v_high = module_info['highaddr']
        v_size = v_high - v_base + 1

        # Try to find matching YAML driver(s) by module type
        yaml_matches = yaml_by_type.get(module_type, [])

        # Find the best match: same base address
        best_match = None
        for yd in yaml_matches:
            if yd['base_addr'] == v_base:
                best_match = yd
                matched_yaml.add(id(yd))
                break

        # If no exact base address match, take the first one of this type
        if not best_match and yaml_matches:
            best_match = yaml_matches[0]
            matched_yaml.add(id(best_match))

        # Build the table row
        row = {
            'module': module_name,
            'type': module_type,
            'base_addr': v_base,
            'high_addr': v_high,
            'size': v_size,
            'verilog_file': module_info['file'],
            'yaml_name': best_match['name'] if best_match else None,
            'yaml_file': best_match['file'] if best_match else None,
            'yaml_base': best_match['base_addr'] if best_match else None,
            'yaml_high': best_match['high_addr'] if best_match else None,
            'status': 'OK'
        }

        # Determine status and generate issues
        if not best_match:
            row['status'] = 'MISSING_YAML'
            issues.append({
                'type': 'missing_yaml',
                'severity': 'warning',
                'module': module_name,
                'module_type': module_type,
                'verilog_file': module_info['file'],
                'verilog_addr': (v_base, v_high),
                'message': f"Verilog module '{module_name}' ({module_type}) has no matching YAML config"
            })
        elif best_match['base_addr'] != v_base or best_match['high_addr'] != v_high:
            row['status'] = 'MISMATCH'
            issues.append({
                'type': 'address_mismatch',
                'severity': 'warning',
                'module': module_name,
                'module_type': module_type,
                'verilog_file': module_info['file'],
                'yaml_file': best_match['file'],
                'verilog_addr': (v_base, v_high),
                'yaml_addr': (best_match['base_addr'], best_match['high_addr']),
                'message': f"Verilog module '{module_name}' ({module_type}) address mismatch"
            })
        else:
            row['status'] = 'OK'

        address_map.append(row)

    # Warn about YAML drivers that weren't matched to any Verilog module
    for driver_type, driver_list in yaml_drivers.items():
        for driver in driver_list:
            if id(driver) not in matched_yaml:
                issues.append({
                    'type': 'unmatched_yaml',
                    'severity': 'info',
                    'module': driver['name'],
                    'module_type': driver_type,
                    'yaml_file': driver['file'],
                    'yaml_addr': (driver['base_addr'], driver['high_addr']),
                    'message': f"YAML driver '{driver['name']}' ({driver_type}) at {format_address(driver['base_addr'])}-{format_address(driver['high_addr'])} not found in Verilog"
                })

    return address_map, issues


def check_overlaps(address_map):
    """
    Check for address range overlaps in the Verilog address map.

    Args:
        address_map: List of address entries

    Returns:
        list: List of overlap issues
    """
    overlaps = []

    for i, entry1 in enumerate(address_map):
        for j, entry2 in enumerate(address_map):
            if i >= j:
                continue

            # Check if ranges truly overlap (not just adjacent)
            if (entry1['base_addr'] < entry2['high_addr'] and
                entry2['base_addr'] < entry1['high_addr']):

                # Only report if they're different instances
                if entry1['module'] != entry2['module']:
                    overlaps.append({
                        'type': 'address_overlap',
                        'severity': 'error',
                        'module1': entry1['module'],
                        'module2': entry2['module'],
                        'range1': (entry1['base_addr'], entry1['high_addr']),
                        'range2': (entry2['base_addr'], entry2['high_addr']),
                        'file1': entry1['verilog_file'],
                        'file2': entry2['verilog_file'],
                        'message': f"Address overlap between {entry1['module']} and {entry2['module']}"
                    })

    return overlaps


def format_address(addr, width=8):
    """Format an address as hex with consistent width."""
    return f"0x{addr:0{width}X}"


def generate_markdown_table(address_map):
    """Generate an aligned plain-text table of the address map."""
    if not address_map:
        return "No address entries found."

    # Sort by base_addr
    sorted_map = sorted(address_map, key=lambda x: x['base_addr'])

    # Calculate column widths
    headers = ["Instance", "Module", "Base Address", "High Address", "Size", "File", "YAML Match"]
    rows = []
    for entry in sorted_map:
        size = entry['size']
        size_str = f"{size:,}" if size > 0 else "N/A"

        # Build YAML match info
        if entry['status'] == 'OK':
            yaml_match = entry['yaml_name'] if entry.get('yaml_name') else "OK"
        elif entry['status'] == 'MISSING_YAML':
            yaml_match = "MISSING"
        elif entry['status'] == 'MISMATCH':
            yaml_match = f"MISMATCH ({format_address(entry['yaml_base'])}-{format_address(entry['yaml_high'])})"
        else:
            yaml_match = "?"

        rows.append([
            entry['module'],
            entry['type'],
            format_address(entry['base_addr']),
            format_address(entry['high_addr']),
            size_str,
            entry['verilog_file'],
            yaml_match
        ])

    # Determine max width for each column
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            col_widths[i] = max(col_widths[i], len(cell))

    # Build formatted output
    lines = []
    # Header row
    header_row = "  ".join(h.ljust(col_widths[i]) for i, h in enumerate(headers))
    lines.append(header_row)
    lines.append("-" * len(header_row))
    # Data rows
    for row in rows:
        lines.append("  ".join(cell.ljust(col_widths[i]) for i, cell in enumerate(row)))

    return "\n".join(lines)


def generate_ascii_diagram(address_map):
    """Generate an ASCII memory map diagram from Verilog entries."""
    if not address_map:
        return "No address entries found for diagram."

    # Sort all entries by base address
    sorted_map = sorted(address_map, key=lambda x: x['base_addr'])

    lines = []
    lines.append("Basil Bus Address Map Diagram")
    lines.append("=" * 70)
    lines.append("")

    for entry in sorted_map:
        base = entry['base_addr']
        high = entry['high_addr']
        size = entry['size']

        # Format size with appropriate units
        if size >= 1024 * 1024:
            size_str = f"{size / (1024 * 1024):.2f}MB"
        elif size >= 1024:
            size_str = f"{size / 1024:.2f}KB"
        else:
            size_str = f"{size}B" if size > 0 else "N/A"

        base_hex = format_address(base)
        high_hex = format_address(high)

        # Show status indicator
        status = entry.get('status', '?')
        if status == 'OK':
            indicator = "[OK]"
        elif status == 'MISSING_YAML':
            indicator = "[NO YAML]"
        elif status == 'MISMATCH':
            indicator = "[MISMATCH]"
        else:
            indicator = "[?]"

        label = f"{entry['module']} [{entry['type']}]"

        lines.append(
            f"{indicator:10s} {base_hex} - {high_hex} : "
            f"{label} ({size_str})"
        )

    return "\n".join(lines)


def print_issues(issues, overlaps, quiet=False):
    """Print issues found during analysis."""
    all_issues = issues + overlaps

    if not all_issues:
        if not quiet:
            print("OK: No issues found - Verilog and YAML addresses are consistent!")
        return 0

    error_count = sum(1 for i in all_issues if i['severity'] == 'error')
    warning_count = sum(1 for i in all_issues if i['severity'] == 'warning')
    info_count = sum(1 for i in all_issues if i['severity'] == 'info')

    if not quiet:
        print(f"\nFound {error_count} error(s), {warning_count} warning(s), {info_count} info(s)")
        print()

    for issue in all_issues:
        severity_label = {
            'error': '[ERROR]',
            'warning': '[WARN] ',
            'info': '[INFO] '
        }.get(issue['severity'], '[     ]')

        if not quiet or issue['severity'] in ['error', 'warning']:
            print(f"{severity_label} {issue['type'].replace('_', ' ').title()}")
            print(f"  {issue['message']}")

            if 'module' in issue:
                print(f"  Module: {issue['module']}")
            if 'yaml_file' in issue:
                print(f"  YAML file: {issue['yaml_file']}")
            if 'verilog_file' in issue:
                print(f"  Verilog file: {issue['verilog_file']}")
            if 'verilog_addr' in issue:
                v_base, v_high = issue['verilog_addr']
                print(f"  Verilog address: {format_address(v_base)} - {format_address(v_high)}")
            if 'verilog_default' in issue:
                v_base, v_high = issue['verilog_default']
                print(f"  Verilog default: {format_address(v_base)} - {format_address(v_high)}")
            if 'yaml_addr' in issue:
                y_base, y_high = issue['yaml_addr']
                print(f"  YAML address: {format_address(y_base)} - {format_address(y_high)}")
            if 'yaml_configured' in issue:
                y_base, y_high = issue['yaml_configured']
                print(f"  YAML configured: {format_address(y_base)} - {format_address(y_high)}")
            if 'range1' in issue:
                r1_base, r1_high = issue['range1']
                r2_base, r2_high = issue['range2']
                print(f"  Range 1: {format_address(r1_base)} - {format_address(r1_high)}")
                print(f"  Range 2: {format_address(r2_base)} - {format_address(r2_high)}")
            print()

    return 1 if error_count > 0 else 0


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Generate and verify Basil bus address map",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Check all Basil files
  python -m basil.utils.check_bus

  # Check specific paths
  python -m basil.utils.check_bus --verilog-glob "basil/firmware/modules/**/*.v" \\
      --yaml-glob "examples/**/*.yaml"

  # As pre-commit hook (exits with error code on issues)
  python -m basil.utils.check_bus --quiet

  # Examples:
  python check_bus.py --verilog-glob "firmware/src/**/*.v" --yaml-glob "**/*.yaml" --base-dir ~/libs/tj-monopix2-daq
  python check_bus.py --verilog-glob "firmware/src/**/*.v" --yaml-glob "**/*.yaml" --base-dir ~/libs/obelix1-daq
  python check_bus.py --verilog-glob "design/fpga/daq_core.v" --yaml-glob "flow/scans/map_fpga.yaml" --base-dir /local/frida
"""
    )

    parser.add_argument(
        '--verilog-glob',
        default='basil/firmware/modules/**/*.v',
        help='Glob pattern for Verilog files (relative to base-dir)'
    )
    parser.add_argument(
        '--yaml-glob',
        default='**/*.yaml',
        help='Glob pattern for YAML configuration files (relative to base-dir)'
    )
    parser.add_argument(
        '--base-dir',
        default='.',
        help='Base directory for glob patterns (default: current directory)'
    )
    parser.add_argument(
        '--output',
        type=str,
        default=None,
        help='Output file for address map (default: stdout)'
    )
    # Note: Overlap checking is always enabled
    parser.add_argument(
        '--quiet',
        action='store_true',
        help='Suppress non-error output (useful for pre-commit hooks)'
    )
    parser.add_argument(
        '--no-color',
        action='store_true',
        help='Disable colored output'
    )

    args = parser.parse_args()

    # Resolve base directory
    base_dir = Path(args.base_dir).resolve()

    # Parse Verilog modules
    verilog_modules = parse_verilog_modules(args.verilog_glob, base_dir)

    # Parse YAML configurations
    yaml_drivers = parse_yaml_configs(args.yaml_glob, base_dir)
    yaml_driver_count = sum(len(v) for v in yaml_drivers.values())

    # Generate address map and check for issues
    address_map, issues = generate_address_map(verilog_modules, yaml_drivers)

    # Always check for overlaps
    overlaps = check_overlaps(address_map)

    # Generate output - just the table
    output_lines = []
    output_lines.append("# Basil Bus Address Map")
    output_lines.append("")
    output_lines.append(generate_markdown_table(address_map))

    # Write output
    output_text = "\n".join(output_lines)

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output_text)
        if not args.quiet:
            print(f"\nAddress map written to: {args.output}")
    else:
        print(output_text)

    # Print issues and return appropriate exit code
    exit_code = print_issues(issues, overlaps, quiet=args.quiet)

    # Summary is implicit in the output

    sys.exit(exit_code)


if __name__ == '__main__':
    main()
