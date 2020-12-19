#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import sys

from tests.test_SimFifo8to32 import TestSimFifo8to32


if __name__ == '__main__':
    # https://stackoverflow.com/a/2081750
    test_loader = unittest.TestLoader()
    test_names = test_loader.getTestCaseNames(TestSimFifo8to32)

    suite = unittest.TestSuite()

# TODO: add sbus versions of used modules
#    for test_name in test_names:
#        suite.addTest(TestSimFifo8to32(testname=test_name, tb='test_SimFifo8to32.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='sbus'))
    for test_name in test_names:
        suite.addTest(TestSimFifo8to32(testname=test_name, tb='test_SimFifo8to32.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='top'))

    result = unittest.TextTestRunner().run(suite)
    sys.exit(not result.wasSuccessful())
