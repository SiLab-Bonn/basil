#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import sys

from tests.test_SimSpi import TestSimSpi


if __name__ == '__main__':
    # https://stackoverflow.com/a/2081750
    test_loader = unittest.TestLoader()
    test_names = test_loader.getTestCaseNames(TestSimSpi)

    suite = unittest.TestSuite()

# TODO: add sbus versions of used modules
#    for test_name in test_names:
#        suite.addTest(TestSimSpi(testname=test_name, tb='test_SimSpi.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='sbus'))
    for test_name in test_names:
        suite.addTest(TestSimSpi(testname=test_name, tb='test_SimSpi.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='top'))

    result = unittest.TextTestRunner().run(suite)
    sys.exit(not result.wasSuccessful())
