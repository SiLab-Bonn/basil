from setuptools import setup, find_packages
from os import path, walk

author = 'Tomasz Hemperek, Jens Janssen, David-Leon Pohl'
author_email = 'hemperek@uni-bonn.de, janssen@physik.uni-bonn.de, pohl@physik.uni-bonn.de'

# https://packaging.python.org/guides/single-sourcing-package-version/
# Use
#     import get_distribution
#     get_distribution('package_name').version
# to programmatically access a version number.
# Also add
#     include VERSION
# MANIFEST.in
with open('VERSION') as version_file:
    version = version_file.read().strip()

# Requirements for core functionality from requirements.txt
# Also add
#     include requirements.txt
# MANIFEST.in
with open('requirements.txt') as f:
    install_requires = f.read().splitlines()


def package_files(directory):
    paths = []
    for (fpath, directories, filenames) in walk(directory):
        for filename in filenames:
            paths.append(path.join('..', fpath, filename))
    return paths


setup(
    name='basil_daq',
    version=version,
    python_requires='>=2.7,!=3.0.*,!=3.1.*,!=3.2.*,!=3.3.*,!=3.4.*,!=3.5.*,!=3.6.*',
    description='Basil - a data acquisition and system testing framework',
    url='https://github.com/SiLab-Bonn/basil',
    license='BSD 3-Clause ("BSD New" or "BSD Simplified") License',
    long_description='Basil is a modular data acquisition system and system testing framework in Python.\nIt also provides generic FPGA firmware modules for different hardware platforms and drivers for wide range of lab appliances.',
    install_requires=install_requires,
    author=author,
    maintainer=author,
    author_email=author_email,
    packages=find_packages(),
    include_package_data=True,  # accept all data files and directories matched by MANIFEST.in or found in source control
    package_data={'': ['*.yaml'], 'basil': package_files('basil/firmware')},
    platforms='any'
)
