#!/usr/bin/env python   

from distutils.core import setup
from setuptools import find_packages  # , setup

f = open('VERSION', 'r')
basil_version = f.readline().strip()
f.close()

setup(
    name='Basil',
    version=basil_version,
    description='Basil: SILAB modular readout framework',
    url='https://silab-redmine.physik.uni-bonn.de/projects/basil',
    license='BSD 3-Clause ("BSD New" or "BSD Simplified") License',
    long_description='',
    requires=['bitarray (>=0.8.1)','pyyaml', 'numpy'],
    packages=find_packages(exclude=['*.tests', '*.test']),  # ['basil', 'basil.HL', 'basil.RL', 'basil.TL', 'basil.UL', 'basil.utils']
#    package_data={'': ['*.txt', 'VERSION'], 'docs': ['*'], 'examples': ['*']},  #  you do not need to use this option if you are using include_package_data
    include_package_data=True,  # accept all data files and directories matched by MANIFEST.in or found in source control
)
