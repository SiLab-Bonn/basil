import time

MULTI_IO_BASE_ADDRESS=0x8800
GPIO_SOFT_RST    = 0
GPIO_INPUT       = 1;
GPIO_OUTPUT_DATA = 2; 
GPIO_DIRECTION   = 3;

PCB_Chopper=0x1
PCB_LD     =0x2
PCB_DIN    =0x4
PCB_CLK    =0x8
HVCMOS_CKD =0x10
HVCMOS_CKC =0x20
HVCMOS_LD  =0x40
HVCMOS_SIN =0x80


import SiLibUSB
sidev=SiLibUSB.SiUSBDevice()
sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_SOFT_RST, [0x00])
sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_DIRECTION, [0xFE])

def program():
    print "Programming FPGA ..."
    print "FPGA OK?:", sidev.DownloadXilinx("D:/workspace/PyBar/host/config/fpga/top3.bit")
    print "Reset:Address=",hex(MULTI_IO_BASE_ADDRESS + GPIO_SOFT_RST)," data=",[0x00]
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_SOFT_RST, [0x00])
    direction = 0xff
    print "Set Direction:Address=",hex(MULTI_IO_BASE_ADDRESS + GPIO_DIRECTION)," data=", hex(direction)
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_DIRECTION, [direction])
    print "Direction:", hex(sidev.ReadExternal(MULTI_IO_BASE_ADDRESS + GPIO_DIRECTION, 1)[0])
    print "done"

def writeTH_INJ(th,inj=0x00):
    import time
    data=(inj+2**(16)*th)*4 # 2-bits shift to convert 16bit to 14bit
    print hex(data)
    for i in range(32,0,-1):
      if (data & 2**(i-1) ) != 0:
         output=PCB_DIN
      else:
         output=0x0
      print hex(output),
      sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output])
      time.sleep(0.001)
      sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output|PCB_CLK])
      time.sleep(0.001)
    print "load PCBDAC(TH, INJ)"
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output|PCB_LD])
    time.sleep(0.01)
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [0])
    print "done"

def mkBitstream_Global(data):
    return [(data & 0x4)!=0, (data & 0x1)!=0, (data &0x2)!=0, (data &0x8)!=0, (data &0x10)!=0, (data &0x20)!=0]

def writeHVCMOS_Global(data={"BLRes":5,"ThRes":60,"VN":60,"VNFB":2,"VNFoll":5,"VNLoad":10,"VNDAC":0,"VNComp":10,
               "VNCompL":10,"NU":0,"VNOut0":20,"VNOut1":20,"VNOut2":20}):
    
    bitstream=[]
    for i in ["VNOut2","VNOut1","VNOut0","VNCompL","VNComp","NU","NU","NU","VNDAC","VNLoad","VNFoll","VNFB","VN","ThRes","BLRes"]:
      bitstream.extend(mkBitstream_Global(data[i]))
    print "len=",len(bitstream),
    for b in bitstream:
      if b:
         output=HVCMOS_SIN
      else:
         output=0x00
      print hex(output),
      sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output])
      time.sleep(0.001)
      sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output|HVCMOS_CKD])
      time.sleep(0.001)
      sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output])
    print "load HVCMOS GlobalDAC"
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output|HVCMOS_LD])
    time.sleep(0.1)
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [0])
    print "done"

def mkBitstream_Row(data=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],row=-1):
    bitstream=[]
    for i in range(24,0,-4):
        #print row,i-1,i-2,i-3
        bitstream.extend([(data[i-2]&0x1)!=0,(data[i-2]&0x2)!=0,(data[i-2]&0x4)!=0,(data[i-2]&0x8)!=0])
        #if row<0 or row==i-1:
        if row==i-2 or row < 0:
            bitstream.extend([False])
        else:
            bitstream.extend([True])
        bitstream.extend([(data[i-1]&0x1)!=0,(data[i-1]&0x2)!=0,(data[i-1]&0x4)!=0,(data[i-1]&0x8)!=0])
        #if row<0 or row==i-2:
        if row==i-1 or row < 0:
            bitstream.extend([False])
        else:
            bitstream.extend([True])
        bitstream.extend([(data[i-3]&0x1)!=0,(data[i-3]&0x2)!=0,(data[i-3]&0x4)!=0,(data[i-3]&0x8)!=0])
        #if row<0 or row==i-4:
        if row==i-3 or row < 0:
            bitstream.extend([False])
        else:
            bitstream.extend([True])
        bitstream.extend([(data[i-4]&0x1)!=0,(data[i-4]&0x2)!=0,(data[i-4]&0x4)!=0,(data[i-4]&0x8)!=0])
        #if row<0 or row==i-3:
        if row==i-4 or row < 0:
            bitstream.extend([False])
        else:
            bitstream.extend([True])
        print "mkBitstream_Row()", i, bitstream[-20:]
    return bitstream

def mkBitstream_Col(col, row=-1):
    EnCurrent=False
    EnStrip=False
    write=False
    bitstream=[]

    if row<0:
        l=False
        r=False
    elif (row % 4)==1 or (row % 4)==2:
        l=True
        r=False
    else:
        l=False
        r=True
    if col<0:
        lr_all=[r,l,r,l,r,l]
        write_all=[write,write,write]
    elif col % 3==0:
        lr_all=[False,False,False,False,r,l]
        write_all=[False,False,write]
    elif col % 3==1:
        lr_all=[False,False,r,l,False,False]
        write_all=[False,write,False]
    else:
        lr_all=[r,l,False,False,False,False]
        write_all=[write,False,False]
    #print lr_all, write_all
    for i in range(60,0,-3):
        bitstream.extend([EnCurrent])
        if i-1==col or i-2==col or i-3==col or col<0:
            bitstream.extend(write_all)
        else:
            bitstream.extend([False,False,False])
        bitstream.extend([EnStrip])
        if i-1==col or i-2==col or i-3==col or col<0:
            bitstream.extend(lr_all)
        else:
            bitstream.extend([False,False,False,False,False,False])
        print "mkBitstream_Col()",i, bitstream[-11:]
    return bitstream

def writeHVCMOS_RowCol(row,col):
    bitstream=[]
    bitstream.extend(mkBitstream_Col(col,row))
    bitstream.extend(mkBitstream_Row([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],row))
    print "len=", len(bitstream),
    for b in bitstream:
        if b:
          output=HVCMOS_SIN
        else:
          output=0x00
        print hex(output),
        sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output])
        time.sleep(0.001)
        sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output|HVCMOS_CKC])
        time.sleep(0.001)
    print "load HVCMOS Config"
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [output|HVCMOS_LD])
    time.sleep(0.1)
    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [0])
    print "done"

if __name__ == "__main__":
    program()
    writeTH_INJ(0x2100)
    #print writeHVCMOS_RowCol()
    writeHVCMOS_Global()

    writeHVCMOS_RowCol(22,58)

    #writeHVCMOS_Global({"BLRes":5,"ThRes":60,"VN":60,"VNFB":2,"VNFoll":5,"VNLoad":10,"VNDAC":0,"VNComp":10,"VNCompL":10,"NU":0,"VNOut0":20,"VNOut1":20,"VNOut2":20})
#    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [HVCMOS_LD])
#    sidev.WriteExternal(MULTI_IO_BASE_ADDRESS + GPIO_OUTPUT_DATA, [HVCMOS_SIN])
#    print mkBitstream_Col(58,22)
#    writeTH_INJ(0x2000)
    #writeHVCMOS_Global({"BLRes":16,"ThRes":16,"VN":16,"VNFB":16,"VNFoll":16,"VNLoad":16,"VNDAC":16,"VNComp":16,"VNCompL":16,"NU":0,"VNOut0":16,"VNOut1":16,"VNOut2":16})
    #writeHVCMOS_Global({"BLRes":3,"ThRes":3,"VN":3,"VNFB":3,"VNFoll":3,"VNLoad":3,"VNDAC":3,"VNComp":3,"VNCompL":3,"NU":3,"VNOut0":3,"VNOut1":3,"VNOut2":3})
#    writeHVCMOS_Global({"BLRes":0,"ThRes":0,"VN":0,"VNFB":0,"VNFoll":0,"VNLoad":0,"VNDAC":0,"VNComp":0,"VNCompL":0,"NU":0,"VNOut0":0,"VNOut1":0,"VNOut2":0})
    #writeHVCMOS_Global({"BLRes":31,"ThRes":31,"VN":31,"VNFB":31,"VNFoll":31,"VNLoad":31,"VNDAC":31,"VNComp":31,"VNCompL":31,"NU":31,"VNOut0":31,"VNOut1":31,"VNOut2":31})
    #writeHVCMOS_Global({"BLRes":63,"ThRes":63,"VN":63,"VNFB":63,"VNFoll":63,"VNLoad":63,"VNDAC":63,"VNComp":63,"VNCompL":63,"NU":0,"VNOut0":63,"VNOut1":63,"VNOut2":63}) 
    #writeHVCMOS_Global({"BLRes":32,"ThRes":32,"VN":32,"VNFB":32,"VNFoll":32,"VNLoad":32,"VNDAC":32,"VNComp":32,"VNCompL":32,"NU":32,"VNOut0":32,"VNOut1":32,"VNOut2":32})
    #writeHVCMOS_Global({"BLRes":0,"ThRes":0,"VN":63,"VNFB":0,"VNFoll":0,"VNLoad":63,"VNDAC":63,"VNComp":63,"VNCompL":63,"NU":0,"VNOut0":63,"VNOut1":63,"VNOut2":63})

#    writeHVCMOS_RowCol()
    #writeTH_INJ(0xFFFF, 0x0000)
    