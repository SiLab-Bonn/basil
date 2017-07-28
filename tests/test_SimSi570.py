#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
import unittest
import os
import math

from basil.HL.si570 import si570
#from basil.dut import Dut

STARTUP_FREQUENCY = 156250000
FREQUENCY_MAX = 810e6
FREQUENCY_MIN = 10e6

if __name__ == '__main__':
	si = si570() 
	#chip = Dut(mmc3_i2c)
    	#chip.init() 


	test_over = 0
	try:
		f = open("frequency", "r+")
		f.readline()
		f0 = int(f.readline())
		f.close()
	except IOError:
		f0 = si.initialize_frequency(STARTUP_FREQUENCY)

	while(test_over != 1):
		print 'Current frequency : ' + str(f0) + ' Hz'
		print "0 - Leave"
		print "1 - Change the frequency of the Si570"
		print "2 - Read current register"
		print "3 - Reset registers"
		print "4 - Configure the file frequency (This will not change the current frequency output)"

		try:
			choice = int(raw_input('Choice = '))
		except ValueError:
			print "Not a number"
			choice = -1

		if choice == 0:
			test_over = 1
		elif choice == 1:
			f0 = si.frequency_change(f0)
			si.change_current_file_frequency(str(int(f0)))
		elif choice == 2:
			si.read_registers(f0)
		elif choice == 3:
			f0 = si.reset_registers(STARTUP_FREQUENCY)
			si.reset_frequency()
		elif choice == 4:
			print "0 - Leave"
			print "1 - Change the current frequency"
			print "2 - Configure the startup frequency"
			
			try:
				choice = int(raw_input('Choice = '))
			except ValueError:
				print "Not a number"
				choice = -1
			if choice == 1 or choice == 2:
				try:			
					f_new = int(raw_input('New frequency = '))
			   		if FREQUENCY_MIN <= f_new <= FREQUENCY_MAX:
						if choice == 1:
							f0 = si.change_current_file_frequency(f_new)
						elif choice == 2:
							si.change_startup_file_frequency(f_new)
				except ValueError:
					print "Not a number"
			
				
