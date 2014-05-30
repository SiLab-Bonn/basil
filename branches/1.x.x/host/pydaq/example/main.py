import yaml
import time

import sys
sys.path.append('../')


from pydaq import *
from utils.BitLogic import *
from utils.utils import *
import BitVector
import array

#class AA(DUTLayer):
#        pass
    
stream = open("cfg.yaml", 'r')
cnfg = yaml.load(stream)
#print cnfg

chip = Dut(cnfg)
#print chip['PIXEL_SR'],chip['PIXEL_SR']._size 
#print chip['PIXEL_SR2'], chip['PIXEL_SR2']._size 

#AA(cnfg)
#chip.test()

#print chip['PIXEL_SR2']
#chip['PIXEL_SR2'][2:0] = 0;
#print chip['PIXEL_SR2']
#chip['PIXEL_SR2'][7:3] = 0;
#print chip['PIXEL_SR2']
#chip['PIXEL_SR2'][7:5] = 0;
#print chip['PIXEL_SR2']
chip['PIXEL_SR2'][8] = 1;
print 'PIX ', chip['PIXEL_SR2']._construct_reg()


#print chip['PIXEL_SR2']
#vec = chip['PIXEL_SR2']._construct_reg().vector
#print vec

print 'kkk'
bv = BitLogic( size = 8, intVal = 0)
bv[6] = 1
print bv
print bv.vector
print 'hhh', bitvector_to_array(bv)


#print chip['PIXEL_SR2']['ON'].size
#bv =  BitLogic( bitstring = '111' )
#chip['PIXEL_SR2']['ON'] = BitLogic( bitstring = '111' )

#vec = chip['PIXEL_SR2']._construct_reg().vector
#print vec
#a = array.array('B', vec)
#print a
#chip['PIXEL_SR'][2:0] = 1;
#print chip['PIXEL_SR']
#print chip['PIXEL_SR2']
#chip['PIXEL_SR'][0:2] = 1;

#for r in chip._registers:
#    print r, type(chip._registers[r]), hex(id(chip._registers[r]))
    
    

#print 'aaa0', oo[0]
#print 'aaa1', oo[1]
#print 'aaa2', oo[2]
#print 'aaa3', oo[3]
#print 'aaa4', oo[4]
#print 'aaa5', oo[5]
#print 'aaa6', oo[6]
#print 'aaa7', oo[7]

"""
chip['DVDD'].SetCurrentLimit( 10 )

chip['DVDD'].SetVoltage( 1.8 , unit = 'V' )
chip['DVDD'].Enable( True )

chip['AVDD'].SetVoltage( 1.8 , unit = 'V' )
chip['AVDD'].Enable( True )

chip['DIODE_BIAS'].SetVoltage( 1800 , unit = 'mV' )
chip['DIODE_BIAS'].Enable( True )

chip['BIAS_P'].SetCurrent( 100  , unit = 'uA') #DIVER
chip['BIAS_N'].SetCurrent( 10  , unit = 'uA')

chip['FAST_ADC_B'].SetVoltage( 1200, unit='mV')# , unit='V') /2 in mA

#print chip._transfer_layer['usb']._sidev.DownloadXilinx("./top.bit")

#while 1:
#    time.sleep(1)
print 'DVDD(V):',chip['DVDD'].GetVoltage( unit='V' ), 'V'
print 'DVDD(I):',chip['DVDD'].GetCurrent(), 'mA'
print 'AVDD(V):',chip['AVDD'].GetVoltage( unit='V' ), 'V'
print 'AVDD(I):',chip['AVDD'].GetCurrent(), 'mA'
print 'DIODE_BIAS(V):',chip['DIODE_BIAS'].GetVoltage( unit='V' ), 'V'
print 'DIODE_BIAS(I):',chip['DIODE_BIAS'].GetCurrent(), 'mA'
#
#
#print ''

chip['FADC_CONF'].Reset()

#chip['FADC_CONF']['RESET'] = 1;
#chip['FADC_CONF'].Write( ['RESET'] )
#chip['FADC_CONF']['OUTMODE'] = 7
#chip['FADC_CONF'].Write( ['OUTMODE'] )


chip['FADC_CONF'].SetData([0x00,0x10]) #RESET ADC
chip['FADC_CONF'].Start()

chip['FADC_CONF'].SetData([0x02,0x07]) #SET 16 bit mode
chip['FADC_CONF'].Start()
print 'chip[\'FADC_CONF\'].IsDone() = ', chip['FADC_CONF'].IsDone()

chip['FADC_CONF'].SetData([0x82,0x00])
chip['FADC_CONF'].Start()
print "FADC_CONF:GetData = ",chip['FADC_CONF'].GetData()[1]

#ret = chip['FADC'].Read()
#ret = chip['FADC'].Read(['OUTMODE'])

chip['PULSE_INJ'].Reset()
chip['PULSE_INJ'].SetDelay(10)

chip['DATA_FIFO'].Reset()
print 'GetSize',chip['DATA_FIFO'].GetSize()
print 'GetData',chip['DATA_FIFO'].GetData(4)
print 'GetSize',chip['DATA_FIFO'].GetSize()
chip['DATA_FIFO'].Reset()
print 'GetSize',chip['DATA_FIFO'].GetSize()

print 'GetErrorCount',chip['DATA_FIFO'].GetErrorCount()

chip['FADC_RX'].Reset()
chip['FADC_RX'].SetDataCount(0x80000)
chip['FADC_RX'].Start()
time.sleep(0.5)

print 'GetSize',hex(chip['DATA_FIFO'].GetSize())



#chip['PIXEL_SR'][0] = 1;
#chip['PIXEL_SR'].Write()
#chip['PIXEL_SR'].SetRepeat()
#chip['PIXEL_SR'].SetWait()


#chip._transfer_layer['usb']._sidev.WriteExternal( 16+3, [0,0,1]) 
#chip._transfer_layer['usb']._sidev.WriteExternal( 16+1, [0x00]) #start
#
#ret_size = chip._transfer_layer['usb']._sidev.ReadExternal( 0x21, 3)
#fifo_size = ret_size[0]*(2^16)+ret_size[1]*(2^8)+ret_size[2]
#
#ret = chip._transfer_layer['usb']._sidev.FastBlockRead(fifo_size*2)
#
#for i in range(fifo_size/2):
#    bytes = ret[i*4:(i+1)*4]
#    print i,':', bytes[2]*255+bytes[3]
"""
    
"""
def xfrange(start, stop, step):
    while start < stop:
        yield start
        start += step
        
for i in xfrange(0.8, 1.9, 0.1) :

    
    chip['DVDD'].SetVoltage( i , unit = 'V' )
    time.sleep(1)
    print i, ' DVDD(V):',chip['DVDD'].GetVoltage( unit='V' ), 'V'
    
    chip._transfer_layer['usb']._sidev.WriteExternal( 16+3, [0,0,1]) 
    chip._transfer_layer['usb']._sidev.WriteExternal( 16+1, [0x00]) #start
    
    ret_size = chip._transfer_layer['usb']._sidev.ReadExternal( 0x21, 3)
    fifo_size = ret_size[0]*(2^16)+ret_size[1]*(2^8)+ret_size[2]
    
    ret = chip._transfer_layer['usb']._sidev.FastBlockRead(fifo_size*2)
    
    for i in range(fifo_size/2):
        bytes = ret[i*4:(i+1)*4]
    print i,':', bytes[2]*255+bytes[3]
"""

"""
print ' trim_ctr',chip['trim_ctr']

chip['trim_ctr']['one'][0] = 1
print ' trim_ctr', chip['trim_ctr']

chip['trim_ctr']['two'] = 3 
print ' trim_ctr', chip['trim_ctr']

chip['trim_ctr'] = 0
print ' trim_ctr', chip['trim_ctr']

chip['trim_ctr'][1:3] = 3
print ' trim_ctr', chip['trim_ctr']

chip['trim_ctr'][0] = 1
print ' trim_ctr', chip['trim_ctr']

#chip['trim_ctr'].Set( 0 )
#chip['trim_ctr'].Write()

#chip['trim_ctr'].Set()
#chip['trim_ctr'].Get()
"""