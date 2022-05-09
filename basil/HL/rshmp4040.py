#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import logging
import time
from basil.HL.scpi import scpi

logger = logging.getLogger(__name__)
'''
Commands are taken from https://scdn.rohde-schwarz.com/ur/pws/dl_downloads/dl_common_library/dl_manuals/gb_1/h/hmp_serie/HMPSeries_UserManual_en_02.pdf#ID_d94c30730bed21620a001ae70a36e776-7e03621134747e760a001ae709a7174f-en-US

'''


class rshmp4040(scpi):

    def __init__(self, intf, conf):
        super(rshmp4040, self).__init__(intf, conf)

    # def init(self):
    #     super(RS_HMP4040, self).init()



    def on(self,channel=1):
        self.set_channel(channel=channel)
        self._on()

    def off(self,channel=1):
        self.set_channel(channel)
        self._off()

    def set_voltage(self,voltage,channel=1):
        self.set_channel(channel)
        self._set_voltage(voltage)

    def set_current(self,current,channel=1):
        self.set_channel(channel)
        self._set_current(current)
    
    def get_target_voltage(self,channel=1):
        """Outputs the target current"""
        self.set_channel(channel)
        self._get_target_voltage()

    def get_target_current(self,channel=1):
        """Outputs the target current"""
        self.set_channel(channel)
        self._get_target_current()
    
    def get_voltage(self,channel):
        self.set_channel(channel)
        self._get_voltage()
    
    def get_current(self,channel):
        self.set_channel(channel)
        self._get_current()

    def set_ovp(self,voltage,channel=1):
        """voltage: Can be float or can be set to MAX  or MIN to set
        OVP to maximum (32.5V) or minimum (0.1V)"""
        self.set_channel(channel)
        self._set_ovp(voltage)
    


    def get_ovp(self,channel=1):
        self.set_channel(channel)
        self._get_ovp()


