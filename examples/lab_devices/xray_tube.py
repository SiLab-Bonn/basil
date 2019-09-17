import time
from basil.dut import Dut

# Initialize x-ray tube
devices = Dut('xray_tube_pyserial.yaml')
devices.init()

# Set high voltage and current
devices["xray_tube"].set_voltage(10)  # 40 kV
devices["xray_tube"].set_current(50)  # 50 mA
print(devices["xray_tube"].get_actual_voltage())  # in kV
print(devices["xray_tube"].get_actual_current())  # in mA

devices["xray_tube"].set_high_voltage_on()  # Turn on HV
devices["xray_tube"].set_timer(dur=3600)  # 3600 s
devices["xray_tube"].activate_timer()  # Activate the timer (clock symbol on display)
devices["xray_tube"].open_shutter()  # Starts actual irradiation (and timer, if set)

time.sleep(10)
# Print remaining irradiation time in seconds
print(devices["xray_tube"].get_actual_time())

# Print status of HV (bit 6 of status word 0)
print(devices["xray_tube"].get_status(0)[1])
