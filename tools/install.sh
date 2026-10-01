#!/usr/bin/env bash
# Download pinned prebuilt tools for local development and any CI provider.
# Usage: bash tools/install.sh verible|oss-cad-suite /absolute/install/prefix
set -euo pipefail

tool=${1:?Specify verible or oss-cad-suite}
prefix=${2:?Specify an absolute installation prefix}
case "$prefix" in
    /*) ;;
    *) echo 'Installation prefix must be absolute' >&2; exit 2 ;;
esac
case "$tool" in
    verible|oss-cad-suite) ;;
    *) echo "Unknown tool: $tool" >&2; exit 2 ;;
esac
if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
    echo 'The pinned binaries require Linux x86_64' >&2; exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mkdir -p "$script_dir/../build/tools/.tmp"
temporary=$(mktemp -d "$script_dir/../build/tools/.tmp/$tool.XXXXXX")
trap 'rm -rf "$temporary"' EXIT
python "$script_dir/sources.py" download "$tool" > "$temporary/download.txt"
mapfile -t settings < "$temporary/download.txt"
url=${settings[0]}
checksum=${settings[1]}
curl --fail --location --retry 3 "$url" --output "$temporary/tools.tar.gz"
echo "$checksum  $temporary/tools.tar.gz" | sha256sum --check
mkdir -p "$prefix"
tar -xzf "$temporary/tools.tar.gz" -C "$prefix" --strip-components=1
if [[ $tool == oss-cad-suite ]]; then
    # Cocotb uses the project's Python, whose shared library may need host libraries.
    sed -i \
        -e '/^export PYTHONEXECUTABLE=/d' \
        -e '/^export PYTHONHOME=/d' \
        -e 's|--library-path "$release_topdir_abs"/lib |--library-path "$release_topdir_abs/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu" |' \
        "$prefix/bin/vvp"
fi
