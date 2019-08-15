#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the chiller.
'''

from basil.dut import Dut

dut = Dut('julaboF32HD.yaml')
dut.init()
print("ID: {}".format(dut["chiller"].get_identifier()))
print("Status: {}".format(dut["chiller"].get_status()))

# start
# set menu->confiuration->setpoint->rs232
dut["chiller"].start_thermostat()
dut["chiller"].get_status()
