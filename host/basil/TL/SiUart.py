#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import serial

from basil.TL.SiTransferLayer import SiTransferLayer

CMD_W = 'w'  # Command to write
CMD_R = 'r'  # Command to read
CMD_A = 'a'  # Command to set address
CMD_L = 'l'  # Command to set length (number of bytes)


class SiUart (SiTransferLayer):

    ''' UART DRIVER
    '''
    _ser = None

    def __init__(self, conf):
        super(SiUart, self).__init__(conf)

    def init(self):
        if 'board_id' in self._conf.keys():
            try:
                self.parity = serial.PARITY_NONE
#                 self.stopbit  = serial.STOPBITS_ONE
#                 self.bytesize = serial.EIGHTBITS

#                 if(self._conf['bytesize'] == 8):
#                    print('BYTESIZE', self.bytesize)
#                 else:
#                    pass

                if(self._conf['parity'] == 0):
                    pass
                else:
                    if(self._conf['parity'] == 1):
                        self.parity = serial.PARITY_ODD
                    else:
                        if(self._conf['parity'] == 2):
                            self.parity = serial.PARITY_EVEN

#                 if(self._conf['stopbits'] == 1):
#                    pass
#                 else:
#                    if(self._conf['stopbits'] == 2):
#                        self.stopbit = serial.STOPBITS_TWO
#                    else:
#                        if(self._conf['stopbits'] == 3):
#                            self.stopbit = serial.STOPBITS_ONE_POINT_FIVE
#
#                 self._ser = serial.Serial(self._conf['port'],
#                                          self._conf['baudrate'],
#                                          self.parity,
#                                          self.stopbit,
#                                          self.bytesize,
#                                          timeout=1)
                self._ser = serial.Serial()
                self._ser.setPort(self._conf['port'])
                self._ser.setBaudrate(self._conf['baudrate'])
                self._ser.setParity(self.parity)
                self._ser.setStopbits(self._conf['stopbits'])
                self._ser.setByteSize(self._conf['bytesize'])
                self._ser.setTimeout(1)

                print("_serial instance opened at", self._conf['port'])
                self._ser.open()
            except serial.serialutil.SerialException as e:
                print("Failed to instantiate UART interface! Check if \n\t1) device is connected \n\t2) valid access to the used _port is guaranteed")
                print("Error Message @ init:"), e
        else:
            print('No board_id in config file')

    def __del__(self):
        try:
            self._ser.close()
            print("_serial _port closed successfully")
        except serial.serialutil.SerialException as e:
            print("Failed to close _serial _port with")
            print("Error Message @ __del__(self):"), e
        except AttributeError as a:
            print("Error Message @ __del__(self):"), a

    def send_cmd(self, cmd, data, explicit_size=False):
        num_to_read = data
        if not isinstance(data, str):
            data = hex(data)
        else:
            pass

        dataOut = ""
        done = False

        self._ser.write(cmd)
        if '0x' in data:
            data = data[2:]
        if len(data) % 2 == 0:
            pass
        else:
            data = "0" + data
        if(cmd == CMD_W):
            self._ser.write(data.decode("hex"))
        if(cmd == CMD_A):
            byteData = '00000000'
            data = byteData[:8 - len(data)] + data
            # Revert byte order #### START
            n = 2
            dlist = [data[i:i + n] for i in range(0, len(data), n)]
            d = "".join(dlist[::-1])
            # Revert byte order #### END

            self._ser.write(d.decode("hex"))
        if(cmd == CMD_L):
            if(explicit_size):
                nbytes = len(data)
                tmp = "00000000"
                tmp = tmp[:8 - nbytes] + data
            else:
                nbytes = len(data) / 2
                tmp = "00000000"
                tmp = tmp[:8 - len(str(nbytes))] + hex(nbytes)[2:]
                # print tmp
            # Revert byte order #### START
            n = 2
            dlist = [tmp[i:i + n] for i in range(0, len(tmp), n)]
            d = "".join(dlist[::-1])
            # Revert byte order #### END
            self._ser.write(d.decode("hex"))
        if(cmd == CMD_R):
            dataOut = self._ser.read(int(num_to_read))

        respond = self._ser.readall()
        if "OK" in respond:
            done = True
        return done, dataOut

    def write(self, to_address, this_data):
        # print ("##########  WRITE VIA UART: Started  ##########")
        try:
            done = False
            if(self.send_cmd(cmd=CMD_A, data=to_address)[0]):
                if(self.send_cmd(cmd=CMD_L, data=this_data)[0]):
                    if(self.send_cmd(cmd=CMD_W, data=this_data)[0]):
                        done = True
                else:
                    print "Write failed"
            # print ("##########  WRITE VIA UART: Finished   ##########\n")
            return done
        except AttributeError as e:
            print ("Error message @ write(self,this_data, to_address): "), e

    def read(self, from_address, num_of_bytes):
        # print ("##########  READ VIA UART: Started  ##########")
        try:
            dataOut = ''
            if(self.send_cmd(cmd=CMD_A, data=from_address)[0]):
                if(self.send_cmd(cmd=CMD_L, data=num_of_bytes, explicit_size=True)[0]):
                    done, dataOut = self.send_cmd(cmd=CMD_R, data=num_of_bytes)
                    if(done):
                        print("Read data")
                        done = True
                    else:
                        print "Read failed"
            # print ("##########  READ VIA UART: Finished  ##########\n")
            return dataOut
        except AttributeError as e:
            print ("Error message @ read(self, num_of_bytes, from_address): "), e

    def close(self):
        try:
            self._ser.close()
            print("_serial _port closed successfully")
        except serial.serialutil.serialException as e:
            print("Failed to close _serial _port with")
            print("Error Message @ __del__(self):"), e
        except AttributeError as a:
            print("Error Message @ __del__(self):"), a
