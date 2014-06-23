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

    def set_configuration(self, conf):
        pass

    def get_configuration(self):
        return {}


class Dut(Base):
    '''Device
    '''
    _transfer_layer = None
    _hardware_layer = None
    _user_drivers = None
    _registers = None

    def __init__(self, conf):
        super(Dut, self).__init__(conf)
        self.load_configuration(self._conf)

    def init(self):
        for tl in self._transfer_layer.itervalues():
            tl.init()
        for hl in self._hardware_layer.itervalues():
            hl.init()
        for ul in self._user_drivers.itervalues():
            ul.init()
        for rl in self._registers.itervalues():
            rl.init()

    def set_configuration(self, conf):
        if isinstance(conf, basestring):
            stream = open(conf)
            conf = safe_load(stream)  # parse the first YAML document in a stream
        elif isinstance(conf, file):
            conf = safe_load(conf)  # parse the first YAML document in a stream
        else:
            pass  # conf is already a dict

        for item, item_conf in conf.iteritems():
            self[item].set_configuration(item_conf)

    def get_configuration(self):
        conf = {}
        for key, value in self._registers.iteritems():
            conf[key] = value.get_configuration()
        for key, value in self._user_drivers.iteritems():
            conf[key] = value.get_configuration()
        for key, value in self._hardware_layer.iteritems():
            conf[key] = value.get_configuration()
        for key, value in self._transfer_layer.iteritems():
            conf[key] = value.get_configuration()
        return conf

    def load_configuration(self, conf, extend_config=False):
        if not extend_config:
            self._transfer_layer = {}
            self._hardware_layer = {}
            self._user_drivers = {}
            self._registers = {}

        if isinstance(conf, basestring):
            stream = open(conf)
            conf = safe_load(stream)  # parse the first YAML document in a stream
        elif isinstance(conf, file):
            conf = safe_load(conf)  # parse the first YAML document in a stream
        else:
            pass  # conf is already a dict

        for intf in conf['transfer_layer']:
            kargs = {}
            kargs['conf'] = intf
            self._transfer_layer[intf['name']] = self._factory('TL.' + intf['type'], intf['type'], *(), **kargs)

        if 'hw_drivers' in conf:
            if conf['hw_drivers']:
                for hwdrv in conf['hw_drivers']:
                    kargs = {}
                    kargs['intf'] = self._transfer_layer[hwdrv['interface']]
                    kargs['conf'] = hwdrv
                    self._hardware_layer[hwdrv['name']] = self._factory('HL.' + hwdrv['type'], hwdrv['type'], *(), **kargs)

        if 'user_drivers' in conf:
            if conf['user_drivers']:
                for userdrv in conf['user_drivers']:
                    kargs = {}
                    kargs['hw_driver'] = self._hardware_layer[userdrv['hw_driver']]
                    kargs['conf'] = userdrv
                    self._user_drivers[userdrv['name']] = self._factory('UL.' + userdrv['type'], userdrv['type'], *(), **kargs)

        if 'registers' in conf:
            if conf['registers']:
                for reg in conf['registers']:
                    kargs = {}
                    if 'driver' in reg:
                        if reg['driver'].lower() == 'none' or not reg['driver']:
                            kargs['driver'] = None
                        else:
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
