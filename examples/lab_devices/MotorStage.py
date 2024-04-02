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
#####################################


def wait_pos(target,precision,address): #waits/prints position until desired precision is reached 
    print("Moving motore from:",dut["MotorStage"].get_position(address),"to" ,target) #absolute target
    done=False
    while done is False:
        pos=dut["MotorStage"].get_position(address)
        print("motor at",pos,"moving to",target)
        if abs(pos-target)<= precision:
            done=True
        else:
            time.sleep(0.5)
    return pos


######################examples

#print(dut["MotorStage"].get_channel(address=1),"status") # prints status code
#time.sleep(2)

########### example  of an absoulute movement using sleep

print(dut["MotorStage"].get_position(address=1),"position before") #print position before movement

dut["MotorStage"].set_position(10000,address=1) #absolute movement

time.sleep(10) #wait for movement

print(dut["MotorStage"].get_position(address=1),"position after") #print position after movement

########### example of an relative movement using wait_pos

#move_r=20000     #relative movement of 20000
#target = dut["MotorStage"].get_position(address=1)+move_r #wait_pos needs absolute target

#dut["MotorStage"].move_relative(move_r,address=1) #relative movement
#wait_pos(target,500,1) #wait/print movement

########### abort any movement abruptly:
#dut["MotorStage"].abort(address=1)
