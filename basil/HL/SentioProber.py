#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import HardwareLayer


class SentioProber(HardwareLayer):

    '''
    Implements functions to steer a Sentio probe station. The interface is the same for all Hong Kong Sentio probe stations.
    '''

    def __init__(self, intf, conf):
        super(SentioProber, self).__init__(intf, conf)

    def init(self):
        # self._intf.write("*RCS 1")
        pass
        
    def set_position(self, x, y, speed=None):
        ''' Move chuck to absolute position in um'''
        return self._intf.query("move_chuck_xy zero,%1.1f,%1.1f" % (x, y))

    def move_position(self, dx, dy, speed=None):
        ''' Move chuck relative to actual position in um'''
        return self._intf.query("move_chuck_xy relative,%1.1f,%1.1f" % (dx, dy))

    def get_position(self):
        ''' Read chuck position (x, y, z)'''
        data = self._intf.query("get_chuck_xy 0,zero")
        values = data.split(',')
        x = float(values[2])
        y = float(values[3])
        z = float(self._intf.query("get_chuck_z").split(',')[2])
        return [x,y,z]
    
    def goto_die(self, index_x, index_y):
        ''' Move chuck to wafer map chip index'''
        return self._intf.query("map:step_die %d,%d" % (index_x, index_y))

    def goto_next_die(self):
        ''' Move chuck to next die from wafer map'''
        return self._intf.query("map:step_next_die")

    def goto_first_die(self):
        ''' Move chuck to first die from wafer map'''
        return self._intf.query("map:step_first_die")

    def get_die(self):
        ''' Get chip index '''
        print("Check if return order of col and row is correct and consistent with other pc drivers.")
        values = self._intf.query("map:die:get_current_index").split(",")
        print(int(values[-2]), int(values[-1]))

    def contact(self):
        ''' Move chuck to contact z position'''
        return self._intf.query("move_chuck_contact")

    def load(self):
        ''' Move chuck to load z position AND contact (!!)'''
        # return self._intf.query("move_chuck_load")
        return 0

    def separate(self):
        ''' Move chuck to separation z position'''
        return self._intf.query("move_chuck_separation")
