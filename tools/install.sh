#!/usr/bin/env bash
# Download pinned prebuilt tools for local development and any CI provider.
# Usage: bash tools/install.sh
set -euo pipefail

# Step 1: Check the arguments and platform, then prepare the build directory.
if (( $# )); then
    echo 'Usage: bash tools/install.sh' >&2; exit 2
fi
if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
    echo 'The pinned binaries require Linux x86_64' >&2; exit 2
fi
cd "$(dirname "$0")/.."
mkdir -p build/tools

# Step 2: Create verible-download.txt from the pinned settings in pyproject.toml.
# sources.py writes the URL on line 1 and checksum on line 2; read both below.
python tools/sources.py download verible > build/tools/verible-download.txt
{
    read -r verible_url
    read -r verible_checksum
} < build/tools/verible-download.txt

# Step 3: Download and verify Verible before extracting it.
echo 'Installing Verible into build/tools/verible'
curl --fail --location --retry 3 "$verible_url" --output build/tools/verible.tar.gz
echo "$verible_checksum  build/tools/verible.tar.gz" | sha256sum --check
mkdir -p build/tools/verible
tar -xzf build/tools/verible.tar.gz -C build/tools/verible --strip-components=1

# Step 4: Create oss-cad-suite-download.txt from the pinned settings in pyproject.toml.
# sources.py writes the URL on line 1 and checksum on line 2; read both below.
python tools/sources.py download oss-cad-suite > build/tools/oss-cad-suite-download.txt
{
    read -r oss_cad_url
    read -r oss_cad_checksum
} < build/tools/oss-cad-suite-download.txt

# Step 5: Download and verify OSS CAD Suite before extracting it.
echo 'Installing OSS CAD Suite into build/tools/oss-cad-suite'
curl --fail --location --retry 3 "$oss_cad_url" --output build/tools/oss-cad-suite.tar.gz
echo "$oss_cad_checksum  build/tools/oss-cad-suite.tar.gz" | sha256sum --check
mkdir -p build/tools/oss-cad-suite
tar -xzf build/tools/oss-cad-suite.tar.gz -C build/tools/oss-cad-suite --strip-components=1

# Step 6: Let Cocotb use the project's Python and the host's shared libraries.
# Keep the wrapper variable literal in the replacement.
# shellcheck disable=SC2016
sed -i \
    -e '/^export PYTHONEXECUTABLE=/d' \
    -e '/^export PYTHONHOME=/d' \
    -e 's|--library-path "$release_topdir_abs"/lib |--library-path "$release_topdir_abs/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu" |' \
    build/tools/oss-cad-suite/bin/vvp

# Step 7: Delete the downloaded archives and the two download.txt files we created.
# These files are only needed during installation; remove them after success.
rm build/tools/verible.tar.gz build/tools/verible-download.txt \
    build/tools/oss-cad-suite.tar.gz build/tools/oss-cad-suite-download.txt
