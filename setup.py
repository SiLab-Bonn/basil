#!/usr/bin/env python

from distutils.core import setup
from setuptools import find_packages

f = open('VERSION', 'r')
basil_version = f.readline().strip()
f.close()

author = 'Tomasz Hemperek, Jens Janssen'
author_email = 'hemperek@uni-bonn.de, janssen@physik.uni-bonn.de'

setup(
    name='Basil-daq',
    version=basil_version,
    description='Basil: SILAB modular readout framework',
    url='https://github.com/SiLab-Bonn/basil',
    license='BSD 3-Clause ("BSD New" or "BSD Simplified") License',
    long_description='Basil is a modular Rapid Data Acquisition System Design and Testing Framework. It consists of different hardware components, FPGA firmware modules and a Python based control software.',
    requires=['bitarray (>=0.8.1)', 'pyyaml', 'numpy'],
    author=author,
    maintainer=author,
    author_email=author_email,
    packages=find_packages(),
    include_package_data=True,  # accept all data files and directories matched by MANIFEST.in or found in source control
    platforms='any'
)
