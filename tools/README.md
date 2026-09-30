# HDL checks

HDL configuration lives in `[tool.basil-hdl]` in `pyproject.toml`: Verible rules
and formatting flags, Verilator options, shared source paths, Slang settings,
and native tool installation pins. Slang and TOML parser dependencies live in
`[project.optional-dependencies.hdl-lint]`. The scripts in this directory read
those settings and translate them into native tool arguments. Run commands
from the repository root so source paths resolve correctly.

Run these commands from the Basil checkout. Each returns a nonzero status on
failure and can be used unchanged in GitHub Actions, GitLab CI, or a local shell:

```sh
python tools/lint_verilog.py verible-format
python tools/lint_verilog.py verible-lint
python tools/lint_verilog.py verilator
python tools/lint_verilog.py slang
```

With no filenames, the runner checks all owned `.v` and `.sv` files known to
Git, including untracked files that are not ignored. It excludes SiTCP vendor
trees. Verilator and Slang elaborate independent designs with their source
dependencies. `.v` uses Verilog-2005; `.sv` uses SystemVerilog.
Verilator currently reports warnings but fails only on errors (`[tool.basil-hdl.verilator]`).
Formatting checks print a diff without changing files.

The local pre-commit hooks invoke the same runner. Formatting uses `--fix` to
update staged files; CI only checks formatting. Run individual hooks with
`pre-commit run verible-format --all-files` (or `verible-lint`, `verilator-lint`,
`slang-lint`). Verible and Verilator must be on PATH. Pre-commit installs the
Python runner dependencies in isolated environments, including pinned Slang
bindings. Its YAML dependency pins must match the `hdl-lint` extra because
pre-commit local environments cannot install extras from this checkout.

## Installing the pinned tools

Current pins: Verible `v0.0-4053-g89d4d98a`, Verilator `5.046`, pyslang `11.0.0`.
The installer verifies archive checksums, downloads Linux x86_64 Verible binaries,
and builds Verilator from source. It has no dependency on a CI action or Docker.
Verilator builds require autoconf, bison, flex, a C++ compiler, help2man, make,
Perl, libfl and zlib development packages. Downloads require curl, tar and
sha256sum. The scripts use Python 3.11+ or Python 3.10 with `tomli` installed.
For Python 3.10, install `tomli==2.2.1` before invoking the scripts. Install into
an absolute, writable prefix:

```sh
bash tools/install_hdl_tools.sh verible "$PWD/build/hdl-tools"
bash tools/install_hdl_tools.sh verilator "$PWD/build/hdl-tools"
export PATH="$PWD/build/hdl-tools/bin:$PATH"
python tools/hdl_config.py requirements > build/hdl-requirements.txt
python -m pip install -r build/hdl-requirements.txt
```

Native hooks use the installed versions; pre-commit does not enforce the
Verible or Verilator version. Use these installers to match CI. Change Slang
dependencies in the `hdl-lint` extra and the corresponding pre-commit hook;
CI reads its dependencies from the extra.

## GitLab runner example

GitHub uses four independent matrix jobs. A GitLab configuration can use the
same commands in four jobs as well. For example, with a Debian
Python image and a Docker executor:

```yaml
.hdl:
  image: python:3.12-bookworm
  stage: test
  before_script:
    - apt-get update
    - apt-get install -y --no-install-recommends git curl ca-certificates

verible-format:
  extends: .hdl
  script:
    - bash tools/install_hdl_tools.sh verible "$PWD/build/hdl-tools"
    - export PATH="$PWD/build/hdl-tools/bin:$PATH"
    - python tools/lint_verilog.py verible-format

verible-lint:
  extends: .hdl
  script:
    - bash tools/install_hdl_tools.sh verible "$PWD/build/hdl-tools"
    - export PATH="$PWD/build/hdl-tools/bin:$PATH"
    - python tools/lint_verilog.py verible-lint

verilator-lint:
  extends: .hdl
  script:
    - apt-get install -y --no-install-recommends autoconf bison flex g++ help2man make perl libfl-dev zlib1g-dev
    - bash tools/install_hdl_tools.sh verilator "$PWD/build/hdl-tools"
    - export PATH="$PWD/build/hdl-tools/bin:$PATH"
    - python tools/lint_verilog.py verilator

slang-lint:
  extends: .hdl
  script:
    - python tools/hdl_config.py requirements > /tmp/hdl-requirements.txt
    - python -m pip install -r /tmp/hdl-requirements.txt
    - python tools/lint_verilog.py slang
```

Runner setup and PATH handling are the only provider-specific parts. These jobs
need no reviewdog, PR comment permissions, or external linter action. The GitLab
example is documentation; there is no active GitLab pipeline in this checkout.
