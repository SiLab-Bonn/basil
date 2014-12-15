import os

if os.getenv("SIMULATION_HOST"):
    import basil.utils.SimSiLibUSB as SiLibUSB
else:
    import SiLibUSB
sidev = SiLibUSB.SiUSBDevice()

print "FWVersion: " + str(sidev.GetFWVersion())
print "Name: " + str(sidev.GetName())
print "BoardId: " +str(sidev.GetBoardId())


GPIO_BASE_ADDRESS = 0x0000
GPIO_SOFT_RST = 0
GPIO_INPUT = 1;
GPIO_OUTPUT_DATA = 2; 
GPIO_DIRECTION = 3; 

print "Programming FPGA ..."
print "FPGA OK?:", sidev.DownloadXilinx("../ise/example.bit")

print "Reset"
sidev.WriteExternal(GPIO_BASE_ADDRESS + GPIO_SOFT_RST, [0x00])

direction = 0x7f
print "Set Direction:", hex(direction)
sidev.WriteExternal(GPIO_BASE_ADDRESS + GPIO_DIRECTION, [direction])

result = sidev.ReadExternal(GPIO_BASE_ADDRESS + GPIO_DIRECTION, 1)
print "Got %s" % repr(result)

print "Direction:", hex(sidev.ReadExternal(GPIO_BASE_ADDRESS + GPIO_DIRECTION, 1)[0])

output = 0x05
print "Set Output:", hex(output)
sidev.WriteExternal(GPIO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output])

print "Get Input:" , hex(sidev.ReadExternal(GPIO_BASE_ADDRESS + GPIO_INPUT, 1)[0])
