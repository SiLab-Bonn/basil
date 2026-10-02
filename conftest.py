"""Keep pytest temporary artifacts beneath the configured build directory."""

from pathlib import Path


def pytest_configure(config):
    # Pytest creates an explicit basetemp without creating its parent directories.
    if config.option.basetemp:
        Path(config.option.basetemp).parent.mkdir(parents=True, exist_ok=True)
