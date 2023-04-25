###################################################
# This is an example for keithley6517a electrometer
# Last Modified: Do 09 Jun 2022 12:21:44  CEST
###################################################

# Manual https://download.tek.com/manual/6517A_900_01C.pdf

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

def current_measurement():
    # Use electrometer to measure current with configuration of fig 2-9, p.2-11 of manual

    # Connect the internal meter to the voltage source as shwon in fig 2-9
    dut['EMeter'].connect_meter()

    # Setup the electrometer for current measurement
    dut['EMeter'].setup_current_measurement(current_range=2e-10,  # Also 'MIN'/'MAX' e.g. 20e-12/12e-3 A or any number in between or None for autorange
                                            voltage_range='MIN',  # Also 'MIN'/'MAX' e.g. 100/1000 V or any number in between
                                            current_limit=1e-10,  # Current limit for protection DUT
                                            filter=('REP', 5))  # Average filter to apply e.g. REPeat measurement 5 times andy yield average 
    # Turn the output on
    dut['EMeter'].on()

    # Loop over voltages
    for i in range(5):
        dut['Emeter'].set_voltage(i)
        time.sleep(1) # Bias voltage needs time to settle for precise measurement -> maybe needs to be increased
        print(f"{dut['EMeter'].get_current()} A @ {i} V")

    # Ramp down
    for j in range(4, -1, -1):
        dut['Emeter'].set_voltage(j)

    # Turn the output off
    dut['EMeter'].off()


if __name__ == '__main__':
    current_measurement()
