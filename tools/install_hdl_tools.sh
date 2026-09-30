#!/usr/bin/env bash
# Install pinned native tools without CI-provider-specific actions.
# Usage: bash tools/install_hdl_tools.sh verible|verilator /absolute/install/prefix
set -euo pipefail

tool=${1:?Specify verible or verilator}
prefix=${2:?Specify an absolute installation prefix}
case "$prefix" in
    /*) ;;
    *) echo 'Installation prefix must be absolute' >&2; exit 2 ;;
esac
case "$tool" in
    verible)
        if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
            echo 'The pinned Verible binary requires Linux x86_64' >&2; exit 2
        fi
        ;;
    verilator)
        ;;
    *) echo "Unknown tool: $tool" >&2; exit 2 ;;
esac

temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python "$script_dir/hdl_config.py" download "$tool" > "$temporary/download.txt"
mapfile -t settings < "$temporary/download.txt"
url=${settings[0]}
checksum=${settings[1]}
curl --fail --location --retry 3 "$url" --output "$temporary/source.tar.gz"
echo "$checksum  $temporary/source.tar.gz" | sha256sum --check
mkdir -p "$prefix" "$temporary/source"
tar -xzf "$temporary/source.tar.gz" -C "$temporary/source" --strip-components=1
if [[ $tool == verible ]]; then
    cp -a "$temporary/source/." "$prefix/"
else
    cd "$temporary/source"
    unset VERILATOR_ROOT
    autoconf
    ./configure --prefix="$prefix"
    # Limit peak compiler memory; callers can tune build concurrency.
    make -j "${HDL_BUILD_JOBS:-2}"
    make install
fi
