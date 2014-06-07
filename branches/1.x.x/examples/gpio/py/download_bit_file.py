
import SiLibUSB
import time
sidev = SiLibUSB.SiUSBDevice()

print "FWVersion: " + str(sidev.GetFWVersion())
print "Name: " + str(sidev.GetName())
print "BoardId: " +str(sidev.GetBoardId())

print "Programming FPGA ..."
print "FPGA OK?:", sidev.DownloadXilinx("../ise/example.bit")