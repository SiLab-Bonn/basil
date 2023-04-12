from basil.dut import Dut
import os
import sys

print(os.path.dirname(sys.executable))
# Sentio Prober Control
dut = Dut('SentioProber_config.yaml')
dut.init()

# print(dut['Prober'].separate())
print(dut['Prober'].set_position(160000, -40000))
# print(dut['Prober'].move_position(100,-50))
# print(dut['Prober'].get_position())
# print(dut['Prober'].goto_next_die())
# print(dut['Prober'].get_die())
# print(dut['Prober'].goto_first_die())
# print(dut['Prober'].contact())
# print(dut['Prober'].load()) # DO NOT USE
# print(dut['Prober'].separate())
