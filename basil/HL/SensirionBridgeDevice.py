# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import HardwareLayer
from basil.TL.SensirionSensorBridge import TimeoutError


class SensirionBridgeI2CDevice(HardwareLayer):
    '''
    Driver for I2C devices connected to a Sensirion Sensor Bridge.
    The device has to be connected to one of the two ports of the Sensirion Sensor Bridge.
    '''

    def __init__(self, intf, conf):
        super(SensirionBridgeI2CDevice, self).__init__(intf, conf)
        self.TimeoutError = TimeoutError

    def init(self, address):
        super(SensirionBridgeI2CDevice, self).init()

        self.port = self._intf.bridge_ports[self._init.get('bridgePort', 'one')]

        self.address = address

        self.power_on()

    def _read(self, command, read_n_bytes=0, timeout_us=100e3):
        return self._intf.read_i2c(device=self.device, port=self.port, address=self.address,
                                   command=command, read_n_bytes=read_n_bytes, timeout_us=timeout_us)

    def _write(self, command):
        self._intf.write_i2c(device=self.device, port=self.port, address=self.address, command=command)

    def printInformation(self):
        self._intf.print_i2c_device_information(device=self.device)

    def power_on(self):
        self.device = self._intf.setup_i2c_device(bridge_port=self.port, **self._init)

    def power_off(self):
        if hasattr(self, 'device'):
            self._intf.disable_i2c_device(self.device, bridge_port=self.port)

    def __del__(self):
        self.close()

    def close(self):
        self.power_off()
        super(SensirionBridgeI2CDevice, self).close()
