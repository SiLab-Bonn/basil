# ------------------------------------------------------------
# SiTCP throughput test
# Reads data for a couple of seconds and displays the data rate
#
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
import unittest
import os
import math

from basil.dut import Dut

STARTUP_FREQUENCY = 156250000
FREQUENCY_MAX = 810e6
FREQUENCY_MIN = 10e6
    
def frequency_change(f0):
	change_freq = 1

	#Read the registers, to extract HS_DIV, N1 and RFREQ
	chip['i2c'].write(0xba, [7])
	old_value = chip['i2c'].read(0xba, 6) 
	
	HS_DIV = (old_value[0] & 0xE0) >> 5
	HS_DIV += 4 
	
	N1 = ((old_value[0] & 0x1F) << 2) | ((old_value[1] & 0xC0) >> 6) 
	N1 += 1

	RFREQ = ((old_value[1] & 0x3F) << 32) | old_value[2] << 24 | old_value[3] << 16 | old_value[4] << 8 | old_value[5]	
	m_RFREQ = RFREQ / pow(2,28)

	#Calculate fxtal
	try:
		fxtal = ( f0 * HS_DIV * N1 ) / m_RFREQ
	except ZeroDivisionError:
		print("Couldn't calculate fxtal. The connection with the device may not work")
		fxtal = 1
			
	#Choose the new frequency
	print("Which frequency do you wish to have ? (in Hz)")
	
	try:
		f_new = float(raw_input('f1 = '))
	except ValueError:
		print "Not a number"	
	else:
		if FREQUENCY_MIN <= f_new <= FREQUENCY_MAX:
			pass
		else:
			print("Value outside of range")
			if f_new > FREQUENCY_MAX:
				print "The frequency is too high"
				change_freq = 0
			else:
				print "The frequency is too low"
				change_freq = 0
		
	#If the frequency change is between +/- 3500ppm, then we only need to change the RFREQ
	if 0.9965 <= f_new/f0 <= 1.0035 and 0x0000000000 <= math.floor(RFREQ * f_new/f0) <= 0x3FFFFFFFFF and change_freq == 1:
		modifyRFREQ(f0,f_new,(RFREQ * f_new/f0), N1, HS_DIV)
		print "New frequency written\n"
		return int(f_new)
	#Else we need to change RFREQ and the output divider
	elif change_freq == 1:
		HS_DIV_available = [11, 9, 7, 6, 5, 4]
		N1_available = range(2, 129, 2)
		N1_available.insert(0, 1)
		for hs in HS_DIV_available:
			for n in N1_available:
				fdco = f_new * hs * n
				if( (fdco >= 4.85e9) & (fdco <= 5.67e9) ):    #fdco range defined by manufacturer
					HS_DIV_new = hs
					N1_new = n
					break

		#Calculate the new fdco
		fdco = f_new * HS_DIV_new * N1_new
		#To get the new RFREQ
		RFREQ_new = int(math.floor((fdco / fxtal)*pow(2,28)))

		modifyRegister(HS_DIV_new, N1_new, RFREQ_new)
		print "New frequency written\n"
		return int(f_new)
	print "No new frequency\n"
	return f0
	

def modifyRFREQ(f0, f1, RFREQ_new, N1, HS_DIV):
	#Preparation of the array that needs to be send
	chip['Si570']["HS_DIV"] = HS_DIV-4
	chip['Si570']["N1"] = N1-1
	chip['Si570']["RFREQ"] = int(RFREQ_new)

	chip['i2c'].write(0xba, [135])
	M_freeze = chip['i2c'].read(0xba, 1)

	#Freeze the "M" value
	chip['i2c'].write(0xba, [135] + [M_freeze[0] | 0b100000])
	#Write the new frequency configuration	
	chip['i2c'].write(0xba, [7] + chip['Si570'].tobytes().tolist())
	#Unfreeze the "M" value
	chip['i2c'].write(0xba, [135] + [M_freeze[0] & 0b011111])

def modifyRegister(HS_DIV_new, N1_new, RFREQ_new):
	#Preparation of the array that needs to be send	
	chip['Si570']["HS_DIV"] = HS_DIV_new-4	
	chip['Si570']["N1"] = N1_new-1
	chip['Si570']["RFREQ"] = RFREQ_new
		
	chip['i2c'].write(0xba, [137])
	dco_freeze = chip['i2c'].read(0xba, 1)

	chip['i2c'].write(0xba, [135])
	new_freq_flag = chip['i2c'].read(0xba, 1)

	#Freeze the DCO
	chip['i2c'].write(0xba, [137] + [dco_freeze[0] | 0b10000])
	#Write the new frequency configuration	
	chip['i2c'].write(0xba, [7] + chip['Si570'].tobytes().tolist())
	#Unfreeze the DCO
	chip['i2c'].write(0xba, [137] + [dco_freeze[0] & 0b01111])
	#Assert the NewFreq bit	
	chip['i2c'].write(0xba, [135] + [new_freq_flag[0] | 0b01000000])

def read_registers(f0):
	chip['i2c'].write(0xba, [7])
	old_value = chip['i2c'].read(0xba, 6) 
	
	HS_DIV = (old_value[0] & 0xE0) >> 5
	HS_DIV += 4 
	
	N1 = ((old_value[0] & 0x1F) << 2) | ((old_value[1] & 0xC0) >> 6) 
	N1 += 1

	RFREQ = ((old_value[1] & 0x3F) << 32) | old_value[2] << 24 | old_value[3] << 16 | old_value[4] << 8 | old_value[5]

		
	print '\nf = ' + str(f0) + ' Hz'
	print 'HS_DIV = ' + str(HS_DIV)
	print 'N1 = ' + str(N1)
	print 'RFREQ = ' + hex(RFREQ)
	


def reset_registers(f0):
	chip['i2c'].write(0xba, [135])
	RECALL = chip['i2c'].read(0xba, 1)

	chip['i2c'].write(0xba, [135] + [RECALL[0] | 0b1])

	f = open("frequency","r+")
	f0 = int(f.readline())
	f.close()
	return f0

def reset_frequency():
	f = open("frequency","r+")
	f0 = f.readline()
	if f0 < 100000000:
		f.write('0' + str(f0))
	else:
		f.write(str(f0))
	f.close()

	return f0


def initialize_frequency(f0):
	f = open("frequency", "w")
	if f0 < 100000000:
		f.write( '0' + str(f0) + '\n' + '0' + str(f0) )
	else:
		f.write( str(f0) + '\n' + str(f0) )
	f.close()
	return f0	


def change_current_file_frequency(f0):

	f = open("frequency","r+")
	f.readline()
	if f0 < 100000000:
		f.write('0' + str(f0))
	else:
		f.write(str(f0))
	f.close()

	return f0

def change_startup_file_frequency(f0):
	f = open("frequency","r+")
	if f0 < 100000000:
		f.write('0' + str(f0))
	else:
		f.write(str(f0))	
	f.write('\n')
	f.close()

if __name__ == '__main__':
        chip = Dut("mmc3_i2c.yaml")
        chip.init() 

	test_over = 0
	try:
		f = open("frequency", "r+")
		f.readline()
		f0 = int(f.readline())
		f.close()
	except IOError:
		f0 = initialize_frequency(STARTUP_FREQUENCY)
	
	while(test_over != 1):
		print 'Current frequency : ' + str(f0) + ' Hz'
		print "0 - leave"
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
			f0 = frequency_change(f0)
			change_current_file_frequency(str(int(f0)))
		elif choice == 2:
			read_registers(f0)
		elif choice == 3:
			f0 = reset_registers(STARTUP_FREQUENCY)
			reset_frequency()
		elif choice == 4:
			print "1 - Change the current frequency"
			print "2 - Configure the startup frequency"
			
			try:
				choice = int(raw_input('Choice = '))
			except ValueError:
				print "Not a number"
				choice = -1


			try:			
				f_new = int(raw_input('New frequency = '))
		   		if FREQUENCY_MIN <= f_new <= FREQUENCY_MAX:
					if choice == 1:
						f0 = change_current_file_frequency(f_new)
					elif choice == 2:
						change_startup_file_frequency(f_new)
			except ValueError:
				print "Not a number"
