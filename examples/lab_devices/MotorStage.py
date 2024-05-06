#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' This script shows how to use a Motor Stage
'''

import time
from basil.dut import Dut

dut = Dut('mercury_pyserial.yaml')
dut.init()

############## setup (for c-862) #######
#needed if mercury is connected the first time after power up
#MN Motor=on
#LL: switch logic active low (hardware)
dut["MotorStage"].motor_on(address=1)
time.sleep(0.1)
dut["MotorStage"].LL(address=1)
time.sleep(0.1)
##################################### examples

#print(dut["MotorStage"].get_channel(address=1),"status") # prints status code
#time.sleep(2)

########### example  of an absoulute movement using sleep

print(dut["MotorStage"].get_position(address=1),"position before") #print position before movement
time.sleep(1)
#dut["MotorStage"].set_position(10000,address=1) #absolute movement
#dut["MotorStage"].abort(address=1)#abort
dut["MotorStage"].find_edge(1,address=1) #find edge 0=postive 1=negative
dut["MotorStage"].wait_FE(address=1)
print(dut["MotorStage"].get_position(address=1),"position after") #print position after movement

########### example of an relative movement using wait_pos

#move_r=20000     #relative movement of 20000
#target = dut["MotorStage"].get_position(address=1)+move_r #wait_pos needs absolute target

#dut["MotorStage"].move_relative(move_r,address=1) #relative movement
#dut["MotorStage"].wait_pos(target,500,1) #wait/print movement

########### abort any movement abruptly:
#dut["MotorStage"].abort(address=1)
