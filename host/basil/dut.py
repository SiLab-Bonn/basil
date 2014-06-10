#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from yaml import safe_load


class Base(object):
    def __init__(self, conf):
        self._conf = conf

    def init(self):
        pass  # nothing to do here

    def get_configuration(self):
        return self._conf


class Dut(object):
    '''Device
    '''
    _transfer_layer = None
    _hardware_layer = None
    _user_drivers = None
    _registers = None

    def __init__(self, config):
        self.load(config)

    def init(self):
        for tl in self._transfer_layer:
            self._transfer_layer[tl].init()
        for hl in self._hardware_layer:
            self._hardware_layer[hl].init()
        for ul in self._user_drivers:
            self._user_drivers[ul].init()
        for rl in self._registers:
            self._registers[rl].init()

    def load(self, config, extend_config=False):
        if not extend_config:
            self._transfer_layer = {}
            self._hardware_layer = {}
            self._user_drivers = {}
            self._registers = {}

        if isinstance(config, basestring):
            stream = open(config)
            config_dict = safe_load(stream)  # parse the first YAML document in a stream
        elif isinstance(config, file):
            config_dict = safe_load(config)  # parse the first YAML document in a stream
        else:
            config_dict = config

        for intf in config_dict['transfer_layer']:
            kargs = {}
            kargs['conf'] = intf
            self._transfer_layer[intf['name']] = self._factory('TL.' + intf['type'], intf['type'], *(), **kargs)

        if 'hw_drivers' in config_dict:
            if config_dict['hw_drivers']:
                for hwdrv in config_dict['hw_drivers']:
                    kargs = {}
                    kargs['intf'] = self._transfer_layer[hwdrv['interface']]
                    kargs['conf'] = hwdrv
                    self._hardware_layer[hwdrv['name']] = self._factory('HL.' + hwdrv['type'], hwdrv['type'], *(), **kargs)

        if 'user_drivers' in config_dict:
            if config_dict['user_drivers']:
                for userdrv in config_dict['user_drivers']:
                    kargs = {}
                    kargs['hw_driver'] = self._hardware_layer[userdrv['hw_driver']]
                    kargs['conf'] = userdrv
                    self._user_drivers[userdrv['name']] = self._factory('UL.' + userdrv['type'], userdrv['type'], *(), **kargs)

        if 'registers' in config_dict:
            if config_dict['registers']:
                for reg in config_dict['registers']:    
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
                        raise ValueError('No driver specified for register: %s' % (reg['name'],))

    def _factory(self, importname, classname, *args, **kargs):
        _temp = __import__(importname, globals(), locals(), [classname], -1)
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
            raise ValueError('Item not existing: %s' % (item,))

    #TODO
    def __setitem__(self, key, value):
        self._registers[key].set(value)

    def get_configuration(self):
        raise NotImplementedError
