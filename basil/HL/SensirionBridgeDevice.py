# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import HardwareLayer

class SensirionBridgeI2CDevice(HardwareLayer):
    '''
    Driver for I2C devices connected to a Sensirion Sensor Bridge. 
    The device has to be connected to one of the two ports of the Sensirion Sensor Bridge.
    '''

    def __init__(self, intf, conf):
        super(SensirionBridgeI2CDevice, self).__init__(intf, conf)

    def init(self, address):
        super(SensirionBridgeI2CDevice, self).init()
        
        if 'bridgePort' in self._init.keys():
            self.port = self._intf.get_sensor_bridge_port(self._init['bridgePort'])
        else:
            self.port = self._intf.get_sensor_bridge_port('one')

        self.device = self._intf.setup_i2c_device(bridge_port=self.port, **self._init)
        self.address = address

    def _read(self, command, read_n_bytes=0, timeout_us=100e3):
        return self._intf.read_i2c(device=self.device, port=self.port, address=self.address,
                            command=command, read_n_bytes=read_n_bytes, timeout_us=timeout_us)

    def _write(self, command):
        self._intf.write_i2c(device=self.device, port=self.port, address=self.address, command=command)

    def printInformation(self):
        self._intf.print_i2c_device_information(device=self.device)
    
    def __del__(self):
        self.close()

    def close(self):
        super(SensirionBridgeI2CDevice, self).close()
        if hasattr(self, 'device'):
            self._intf.disable_i2c_device(self.device, bridge_port=self.port)
