#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University 
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $: 
#  $Date::                      $:
#

class Base(object):
    def __init__(self, conf):
        self._conf = conf

    def init(self):
        pass

    def get_configuration(self):
        raise NotImplementedError


class Dut(object):

    def __init__(self, config):
        self._transfer_layer = dict()
        self._hardware_layer = dict()
        self._user_drivers = dict()
        self._registers = dict()

        for intf in config['transfer_layer']:
            kargs = {}
            kargs['conf'] = intf
            self._transfer_layer[intf['name']] = self._factory('TL.' + intf['type'], intf['type'], *(), **kargs)

        for hwdrv in config['hw_drivers']:
            kargs = {}
            kargs['intf'] = self._transfer_layer[hwdrv['interface']]
            kargs['conf'] = hwdrv
            self._hardware_layer[hwdrv['name']] = self._factory('HL.' + hwdrv['type'], hwdrv['type'], *(), **kargs)

        for userdrv in config['user_drivers']:
            kargs = {}
            kargs['hw_driver'] = self._hardware_layer[userdrv['hw_driver']]
            kargs['conf'] = userdrv
            self._user_drivers[userdrv['name']] = self._factory('UL.' + userdrv['type'], userdrv['type'], *(), **kargs)

        for reg in config['registers']:
            kargs = {}
            if 'driver' in reg:
                kargs['driver'] = self._user_drivers[reg['driver']]
                kargs['conf'] = reg
                self._registers[reg['name']] = self._factory('RL.' + reg['type'], reg['type'], *(), **kargs)
            elif 'hw_driver' in reg:
                kargs['driver'] = self._hardware_layer[reg['hw_driver']]
                kargs['conf'] = reg
                self._registers[reg['name']] = self._factory('RL.' + reg['type'], reg['type'], *(), **kargs)
            else:
                raise ValueError('No driver specified or register %s' (reg['name']))

    def _factory(self, importnamem, classname, *args, **kargs):
        _temp = __import__(importnamem, globals(), locals(), [classname], -1)
        aClass = getattr(_temp, classname)
        return aClass(*args, **kargs)

    def __getitem__(self, item):
        if item in self._registers:
            return self._registers[item]
        elif item in self._user_drivers:
            return self._user_drivers[item]
        elif item in self._hardware_layer:
            return self._hardware_layer[item]
        elif item in self._transfer_layer:
            return self._transfer_layer[item]
        else:
            raise ValueError('No item %s found' (item))
        
    #TODO
    def __setitem__(self, key, value):
        self._registers[key].set(value)

    def init(self):
        for tl in self._transfer_layer:
            self._transfer_layer[tl].init()
        for hl in self._hardware_layer:
            self._hardware_layer[hl].init()
        for ul in self._user_drivers:
            self._user_drivers[ul].init()
        for rl in self._registers:
            self._registers[rl].init()

    def get_configuration(self):
        raise NotImplementedError
