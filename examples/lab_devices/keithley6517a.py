###################################################
# This is an example for keithley6517a electrometer
# Last Modified: Mi 01 Jun 2022 07:30:23  CEST
###################################################

import time
from basil.dut import Dut
from basil.TL.Visa import visa

##################
# Initialisation #
##################

dut = Dut('keithley6517a_pyvisa.yaml')
dut.init()
time.sleep(0.3)

#########################
# End of Initialisation #
#########################

#############################
# Settings for Electrometer #
#############################

# check and configure the filter
time.sleep(0.5)
dut['EMeter'].set_Iavefilter_type('REP')            # "REP" means repeating
dut['EMeter'].set_Iavefilter_count('10')            # take 10 values for averaging
time.sleep(0.5)
dut['EMeter'].I_filter_on()                           # turn on the filter
print("Filter : ", dut['EMeter'].get_I_filter())      # display the status of the filter
time.sleep(0.5)
avecou = int(dut['EMeter'].get_Iavefilter_count())  # display the number of values for averaging
print('averaging over:', avecou)
time.sleep(0.5)

# set trigger status
dut['EMeter'].trigger_conti_off()                   # turn off the continuous trigger
time.sleep(0.5)

time.sleep(0.3)
dut['EMeter'].select_current()          # measure current
dut['EMeter'].connect_meter()           # connect the source and meter, resulting in a simpler circuit
dut['EMeter'].set_source_range('MAX')   # set the output limit of the voltage source to 1000V (MAX)

# Perform zero check
# set the smallest range for zero check
dut['EMeter'].set_current_range(20e-12)     # unit is A (everywhere)
time.sleep(0.5)
dut['EMeter'].zero_check_on()
time.sleep(1)
dut['EMeter'].zero_correct_off()
time.sleep(1)
# set an appropriate range for measurements
dut['EMeter'].set_current_range(20e-6)
time.sleep(1)
dut['EMeter'].zero_correct_on()
time.sleep(1)
dut['EMeter'].zero_check_off()

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
