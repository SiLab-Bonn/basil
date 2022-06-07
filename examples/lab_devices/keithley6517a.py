###################################################
# This is an example for keithley6517a electrometer
# Last Modified: Mi 01 Jun 2022 07:30:23  CEST
###################################################

import time
from basil.dut import Dut
##################
# Initialisation #
##################

dut = Dut('keithley6517a_pyvisa.yaml')
dut.init()

#########################
# End of Initialisation #
#########################

#############################
# Settings for Electrometer #
#############################
# dut['EMeter'].connect_meter()         # connect the source and meter (default: OFF) (better done manually unless you are sure what you are doing)
dut['EMeter'].select_current()          # select current measurement
time.sleep(0.5)

# Perform zero correction
# set the smallest range for zero check
dut['EMeter'].set_current_range(20e-12)     # unit is A (everywhere)
time.sleep(0.5)
dut['EMeter'].zero_correct_on()
time.sleep(0.5)
# set an appropriate range for measurements
dut['EMeter'].set_current_range(20e-6)
time.sleep(0.5)
dut['EMeter'].zero_check_off()

# check and configure the filter
time.sleep(0.5)
dut['EMeter'].set_Iavefilter_type('REP')            # "REP" means repeating
dut['EMeter'].set_Iavefilter_count('10')            # take 10 values for averaging
time.sleep(0.5)
dut['EMeter'].I_filter_on()                           # turn on the filter
time.sleep(0.5)
# set trigger status
dut['EMeter'].trigger_conti_off()                   # turn off the continuous trigger
time.sleep(0.5)
dut['EMeter'].set_source_range('MAX')   # set the output limit of the voltage source to 1000V (MAX)

###################
# End of settings #
###################

###############
# measurement #
###############
# set voltage of the source
dut['EMeter'].set_voltage(1)      # unit is V
# measure current (because the "current measurement" has been selected)
#   Same as many output format of the lab devices, the useful info has to be extracted
#   using string operations, and finally needs to be conerted to float
II = float(dut['EMeter'].get_read().split(',')[0][:-4])

print(II)

######################
# End of measurement #
######################

# turn the zero check back on after measurements, then the measurement circuit can be
#   modified while the zero check is on (recommended by the manual)
dut['EMeter'].zero_check_on()
