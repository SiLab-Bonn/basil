#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import sys

from tests.test_SimGpio import TestSimGpio


if __name__ == '__main__':
    # https://stackoverflow.com/a/2081750
    test_loader = unittest.TestLoader()
    test_names = test_loader.getTestCaseNames(TestSimGpio)

    suite = unittest.TestSuite()

    for test_name in test_names:
        suite.addTest(TestSimGpio(testname=test_name, tb='test_SimGpio.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='sbus'))
    for test_name in test_names:
        suite.addTest(TestSimGpio(testname=test_name, tb='test_SimGpio.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='top'))

    result = unittest.TextTestRunner().run(suite)
    sys.exit(not result.wasSuccessful())
