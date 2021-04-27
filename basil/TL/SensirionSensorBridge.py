#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging

from basil.TL.TransferLayer import TransferLayer

from sensirion_shdlc_driver import ShdlcSerialPort, ShdlcConnection
from sensirion_shdlc_sensorbridge import SensorBridgePort, SensorBridgeShdlcDevice
from sensirion_shdlc_sensorbridge.device_errors import SensorBridgeI2cTimeoutError
TimeoutError = SensorBridgeI2cTimeoutError
# Requires 'sensirion_shdlc_sensorbridge'

logger = logging.getLogger(__name__)


class SensirionSensorBridge(TransferLayer):
    '''
    Driver for Sensirion Sensor Bridge using the official SHDLC drivers of Sensirion.
    The Sensirion Sensor Bridge is connected via USB and allows communication to two I2C ports.
    '''

    bridge_ports = {
        "one": SensorBridgePort.ONE,
        "two": SensorBridgePort.TWO,
        "all": SensorBridgePort.ALL,
    }

    def __init__(self, conf):
        super(SensirionSensorBridge, self).__init__(conf)

    def init(self):
        super(SensirionSensorBridge, self).init()

        self.port = self._init['port']
        self.baudrate = self._init.get('baudrate', 460800)

        self.ser = ShdlcSerialPort(port=self.port, baudrate=self.baudrate)

    def setup_i2c_device(self, bridge_port=SensorBridgePort.ONE, voltage=3.3, frequency=400e3, **_):
        device = SensorBridgeShdlcDevice(ShdlcConnection(self.ser), slave_address=0)
        device.set_i2c_frequency(bridge_port, frequency=frequency)
        device.set_supply_voltage(bridge_port, voltage=voltage)
        device.switch_supply_on(bridge_port)
        return device

    def disable_i2c_device(self, device, bridge_port=SensorBridgePort.ONE):
        if hasattr(self, 'device'):
            device.switch_supply_off(bridge_port)

    def print_i2c_device_information(self, device):
        logger.info("Product Name: {}".format(device.get_product_name()))
        logger.info("Product Type: {}".format(device.get_product_type()))
        logger.info("Serial Number: {}".format(device.get_serial_number()))
        logger.info("Version: {}".format(device.get_version()))

    def read_i2c(self, device, port, address, command, read_n_bytes=0, timeout_us=100e3):
        rx_data = device.transceive_i2c(port, address=address, tx_data=command,
                                        rx_length=read_n_bytes, timeout_us=timeout_us)
        return rx_data

    def write_i2c(self, device, port, address, command):
        device.transceive_i2c(port, address=address,
                              rx_length=0, tx_data=command, timeout_us=0)

    def __del__(self):
        self.close()

    def close(self):
        super(SensirionSensorBridge, self).close()
        if hasattr(self, 'ser'):
            self.ser.close()
