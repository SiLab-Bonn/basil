#!/usr/bin/env python   

from distutils.core import setup

f = open('VERSION', 'r')
basil_version = f.readline().strip()
f.close()

setup(
    name='Basil',
    version=basil_version,
    package_dir={'basil': '', 'basil.HL': 'HL', 'basil.RL': 'RL', 'basil.TL': 'TL', 'basil.UL': 'UL', 'basil.utils': 'utils'},
    packages=['basil', 'basil', 'basil.HL', 'basil.RL', 'basil.TL', 'basil.UL', 'basil.utils'],
    #packages=[''],
    description='SILAB modular readout framework',
    url='https://silab-redmine.physik.uni-bonn.de/projects/basil',
    license='BSD 3-Clause ("BSD New" or "BSD Simplified") License',
    long_description =''
)
