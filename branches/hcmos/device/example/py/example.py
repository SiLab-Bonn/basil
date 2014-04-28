
import SiLibUSB
sidev = SiLibUSB.SiUSBDevice()

#print "FWVersion: " + str(sidev.GetFWVersion())
#print "Name: " + str(sidev.GetName())
#print "BoardId: " +str(sidev.GetBoardId())


GPIO_BASE_ADDRESS = 0x8800
GPIO_SOFT_RST = 0
GPIO_INPUT = 1;
GPIO_OUTPUT_DATA = 2; 
GPIO_DIRECTION = 3; 

print "Programming FPGA ..."
#print "FPGA OK?:", sidev.DownloadXilinx("../ise/example.bit")
print "FPGA OK?:", sidev.DownloadXilinx("D:/workspace/PyBar/device/MultiIO/FPGA/ise/top.bit")

print "Reset:Address=",hex(GPIO_BASE_ADDRESS + GPIO_SOFT_RST)," data=",[0x00]
sidev.WriteExternal(GPIO_BASE_ADDRESS + GPIO_SOFT_RST, [0x00])

direction = 0xff
print "Set Direction:Address=",hex(GPIO_BASE_ADDRESS + GPIO_DIRECTION)," data=", hex(direction)
sidev.WriteExternal(GPIO_BASE_ADDRESS + GPIO_DIRECTION, [direction])
print "Direction:", hex(sidev.ReadExternal(GPIO_BASE_ADDRESS + GPIO_DIRECTION, 1)[0])

output = 0xff
print "Set Output:Address=",hex(GPIO_BASE_ADDRESS + GPIO_OUTPUT_DATA)," data=", hex(output)
sidev.WriteExternal(GPIO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output])

print "Get Input:Address=",hex(GPIO_BASE_ADDRESS + GPIO_INPUT)," data=",hex(sidev.ReadExternal(GPIO_BASE_ADDRESS + GPIO_INPUT, 1)[0])
sidev.dispose()
print "done"