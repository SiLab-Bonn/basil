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
        self.name = None
        self.version = None
        self._init = {}
        self._conf = self._open_conf(conf)
        if 'name' in self._conf:
            self.name = self._conf['name']
        if 'version' in self._conf:
            self.version = self._conf['version']
        if 'init' in self._conf:
            self._update_init(self._conf['init'])

    def _open_conf(self, conf):
        if not conf:
            return None
        elif isinstance(conf, basestring):  # parse the first YAML document in a stream
            stream = open(conf)
            return safe_load(stream)
        elif isinstance(conf, file):  # parse the first YAML document in a stream
            return safe_load(conf)
        else:  # conf is already a dict
            return conf

    def _update_init(self, init_conf=None, **kwargs):
        init_conf = self._open_conf(init_conf)
        if init_conf:
            self._init.update(init_conf)
        self._init.update(kwargs)

    def init(self):
        raise NotImplementedError("init() not implemented")

    def set_configuration(self, conf):
        raise NotImplementedError("set_configuration() not implemented")

    def get_configuration(self):
        raise NotImplementedError("get_configuration() not implemented")


class Dut(Base):
    '''Device
    '''
    _transfer_layer = None
    _hardware_layer = None
    _user_drivers = None
    _registers = None

    def __init__(self, conf):
        super(Dut, self).__init__(conf)
        self.load_hw_configuration(self._conf)

    def init(self, init_conf=None, **kwargs):
        init_conf = self._open_conf(init_conf)

        def update_init(mod):
            if init_conf:
                if mod.name in init_conf:
                    mod._update_init(init_conf[mod.name])
            if mod.name in kwargs:
                mod._update_init(kwargs[mod.name])
            # copy _conf to _init for backward compatibility
            if not mod._init:
                mod._init = mod._conf

        def catch_exception_on_init(mod):
            try:
                mod.init()
            except NotImplementedError, e:
                pass
#                 print '%s: %s' % (type(mod), e)

        for item in self._transfer_layer.itervalues():
            update_init(item)
            catch_exception_on_init(item)
        for item in self._hardware_layer.itervalues():
            update_init(item)
            catch_exception_on_init(item)
        for item in self._user_drivers.itervalues():
            update_init(item)
            catch_exception_on_init(item)
        for item in self._registers.itervalues():
            update_init(item)
            catch_exception_on_init(item)

    def set_configuration(self, conf):
        conf = self._open_conf(conf)

        if conf:
            for item, item_conf in conf.iteritems():
                try:
                    self[item].set_configuration(item_conf)
                except NotImplementedError:
                    pass

    def get_configuration(self):
        conf = {}
        for key, value in self._registers.iteritems():
            try:
                conf[key] = value.get_configuration()
            except NotImplementedError:
                conf[key] = {}
        for key, value in self._user_drivers.iteritems():
            try:
                conf[key] = value.get_configuration()
            except NotImplementedError:
                conf[key] = {}
        for key, value in self._hardware_layer.iteritems():
            try:
                conf[key] = value.get_configuration()
            except NotImplementedError:
                conf[key] = {}
        for key, value in self._transfer_layer.iteritems():
            try:
                conf[key] = value.get_configuration()
            except NotImplementedError:
                conf[key] = {}
        return conf

    def load_hw_configuration(self, conf, extend_config=False):
        conf = self._open_conf(conf)

        if extend_config:
            self._conf.update(conf)
        else:
            self._conf = conf

        if not extend_config:
            if conf['name']:
                self.name = conf['name']
            else:
                self.name = None
            if conf['version']:
                self.version = conf['version']
            else:
                self.version = None
            self._transfer_layer = {}
            self._hardware_layer = {}
            self._user_drivers = {}
            self._registers = {}

        for intf in conf['transfer_layer']:
            kargs = {}
            kargs['conf'] = intf
            self._transfer_layer[intf['name']] = self._factory('TL.' + intf['type'], intf['type'], *(), **kargs)

        if 'hw_drivers' in conf:
            if conf['hw_drivers']:
                for hwdrv in conf['hw_drivers']:
                    kargs = {}
                    if hwdrv['interface'] != 'None':
                        kargs['intf'] = self._transfer_layer[hwdrv['interface']]
                    else:
                        kargs['intf'] = None
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
        try:
            _temp = __import__(importname, globals(), locals(), [classname], -1)
        except ImportError:
            _temp = __import__(importname.split('.')[-1], globals(), locals(), [classname], -1)
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

    def __repr__(self):
        return str(self.get_configuration())
