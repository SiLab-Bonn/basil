###################################################
# This is an example for keithley6517a electrometer
# Last Modified: Mi 08 Jun 2022 11:23:04  CEST
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


def Rem_Set(CurrentRange, SourceRange):
    '''
    The function to set up the device remotely. Following setting commands will be sequentially
        executed. This procedure can be manually done using the front panel of the device.
    '''
    dut['EMeter'].connect_meter()         # connect the source and meter (default: OFF) (better done manually unless you are sure what you are doing)
    dut['EMeter'].select_current()          # select current measurement
    time.sleep(0.1)
    # Perform zero correction
    # set the smallest range for zero check
    dut['EMeter'].set_current_range(20e-12)     # unit is A (everywhere)
    time.sleep(0.1)
    dut['EMeter'].zero_correct_on()
    time.sleep(0.1)
    # set an appropriate range for measurements
    dut['EMeter'].set_current_range(CurrentRange)
    time.sleep(0.1)
    dut['EMeter'].zero_check_off()

    # check and configure the filter
    time.sleep(0.1)
    dut['EMeter'].set_Iavefilter_type('REP')            # "REP" means repeating
    dut['EMeter'].set_Iavefilter_count('10')            # take 10 values for averaging
    time.sleep(0.1)
    dut['EMeter'].I_filter_on()                           # turn on the filter
    time.sleep(0.1)
    # set trigger status
    dut['EMeter'].trigger_conti_off()                   # turn off the continuous trigger
    time.sleep(0.1)
    dut['EMeter'].set_source_range(SourceRange)   # set the output limit of the voltage source to 1000V (MAX)


# Apply the settings remotely
Rem_Set(2e-6, 'MAX')

###################
# End of settings #
###################

###############
# measurement #
###############
dut['EMeter'].on()                # turn on the source output
# set voltage of the source
dut['EMeter'].set_voltage(1)      # unit is V
time.sleep(0.1)
# measure current (because the "current measurement" has been selected)
#   Same as many output format of the lab devices, the useful info has to be extracted
#   using string operations, and finally needs to be conerted to float
II = float(dut['EMeter'].get_read().split(',')[0][:-4])
print(II)
time.sleep(0.1)
dut['EMeter'].set_voltage(0)
time.sleep(0.1)
dut['EMeter'].off()                # turn off the source output
######################
# End of measurement #
######################

# turn the zero check back on after measurements, then the measurement circuit can be
#   modified while the zero check is on (recommended by the manual)
dut['EMeter'].zero_check_on()
