# Building the documentation

Basil documentation is built with Sphinx from the files in this directory.
The build imports the local `basil` Python package for autodoc, so install the package itself in addition to the documentation dependencies.

## System dependency

Install Graphviz so Sphinx can render diagrams from `sphinx.ext.graphviz`.

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install graphviz
```

On Fedora/RHEL:

```bash
sudo dnf install graphviz
```

## Python environment

From the repository root, create and activate a virtual environment with any supported Python version (Python 3.10 or newer):

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
```

Install using the `docs` optional dependency target:

```bash
python -m pip install -e ".[docs]"
```

## Build

Build the HTML documentation:

```bash
python -m sphinx -b html docs docs/_build/html
```

For a stricter local check that fails on warnings:

```bash
python -m sphinx -b html -W --keep-going docs docs/_build/html
```

Open `docs/_build/html/index.html` in a browser to view the result.
