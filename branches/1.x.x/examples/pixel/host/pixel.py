
import yaml
import numpy as np
import time

from basil.dut import Dut
class Pixel(Dut):
    pass

##

stream = open("pixel.yaml", 'r')
cnfg = yaml.load(stream)
chip = Pixel(cnfg)

#create configuration pattern


chip['SEQ_GEN'].set_size(400) # define size of pattern
chip['SEQ_GEN'].set_repeat(1)

chip['PIXEL_RX'].set_en(True) #enable reciver

chip['SEQ_GEN'].start()

#while chip['SEQ_GEN'].is_ready == False:
#    time.sleep(0.01)
    
rxd = chip['DATA'].get_data() #get data from sram fifo
print rxd

data0 = rxd.astype(np.uint8) # Change type to unsigned int 8 bits and take from rxd only the last 8 bits
data1 = np.right_shift(rxd, 8).astype(np.uint8) # Rightshift rxd 8 bits and take again last 8 bits
data = np.reshape(np.vstack((data1, data0)), -1, order='F') # data is now a 1 dimensional array of all bytes read from the FIFO
bdata = np.unpackbits(data).reshape(-1,352)
sum =  np.sum(bdata, axis=0)
sum = sum[::-1] # reverse the array

print sum


    

