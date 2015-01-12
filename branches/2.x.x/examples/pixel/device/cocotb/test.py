import os
import time

if os.getenv("SIMULATION_HOST"):
    import basil.utils.sim.SiLibUsb as SiLibUSB
else:
    import SiLibUSB
sidev = SiLibUSB.SiUSBDevice()

print "FWVersion: " + str(sidev.GetFWVersion())
print "Name: " + str(sidev.GetName())
print "BoardId: " +str(sidev.GetBoardId())


print "Programming FPGA ..."
print "FPGA OK?:", sidev.DownloadXilinx("../ise/pixel.bit")

SEQ_GEN_BASEADDR = 0x1000
FAST_SR_AQ  = 0x0100
FIFO_BASE_ADD = 0x0020
GPIO_BASE_ADD = 0x0000

#blink some diodes
# GPIO 0 = reset
# 1 = ?
# 2 = set
# 0xff is enable, 0x00 is disable
sidev.WriteExternal( GPIO_BASE_ADD + 2,  [0xff])
time.sleep(0.5) 
sidev.WriteExternal( GPIO_BASE_ADD + 2,  [0x00])
time.sleep(0.5) 
sidev.WriteExternal( GPIO_BASE_ADD + 2,  [0xff])


#enable FAST_SR_AQ
#sidev.WriteExternal( FAST_SR_AQ + 2,  [0x01]);

#put some data into SEQ memory
#sidev.WriteExternal( SEQ_GEN_BASEADDR + 16,  [0x00]*100 ); 
#sidev.WriteExternal( SEQ_GEN_BASEADDR + 16 + 16,  [0xff]*16 );
#sidev.WriteExternal( SEQ_GEN_BASEADDR + 16 + 16 + 7,  [0xfe]*2 ); #to have some pattern 
sidev.WriteExternal( SEQ_GEN_BASEADDR + 16,  [0x00]*100 ); 
sidev.WriteExternal( SEQ_GEN_BASEADDR + 16,  [0b10101010, 0b01010101, 0b10101010, 0b11111111] ); 
#set size
sidev.WriteExternal( SEQ_GEN_BASEADDR + 3,  [100,0]); 
#set repeat
sidev.WriteExternal( SEQ_GEN_BASEADDR + 7,  [0]); 
#start
sidev.WriteExternal( SEQ_GEN_BASEADDR + 1,  [0x00]);  
  
while not (sidev.ReadExternal( SEQ_GEN_BASEADDR + 1,  1)[0] & 0x01):
    print "Done?"
    
print "DONE!"
    
ret = sidev.ReadExternal( FIFO_BASE_ADD + 3,  4);
fifo_size =  ret[0] + ret[1] * 256 + ret[2] * 65536    
print 'fifo_size:', ret, fifo_size

print "Read Fast: size=", fifo_size , sidev.FastBlockRead((fifo_size/2)*4)

