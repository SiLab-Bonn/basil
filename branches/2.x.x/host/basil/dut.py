#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - [%(levelname)-8s] (%(threadName)-10s) %(message)s")
from importlib import import_module
from inspect import getmembers, isclass
from yaml import safe_load
import sys


class Base(object):
    def __init__(self, conf):
        self.name = None
        self.version = None
        self.conf_path = None
        self.parent = None
        self._init = {}
        self._conf = self._open_conf(conf)
        if 'name' in self._conf:
            self.name = self._conf['name']
        if 'version' in self._conf:
            self.version = self._conf['version']
        if 'conf_path' in self._conf:
            self.conf_path = self._conf['conf_path']
        if 'parent' in self._conf:
            self.parent = self._conf['parent']
        if 'init' in self._conf:
            self._update_init(self._conf['init'])

    def _open_conf(self, conf):
        conf_dict = {}
        if not conf:
            pass
        elif isinstance(conf, basestring):  # parse the first YAML document in a stream
            with open(conf, 'r') as f:
                conf_dict.update(safe_load(f))
                conf_dict.update(conf_path=f.name)
        elif isinstance(conf, file):  # parse the first YAML document in a stream
            conf_dict.update(safe_load(conf))
            conf_dict.update(conf_path=conf.name)
        else:  # conf is already a dict
            conf_dict.update(conf)
        return conf_dict

    def _update_init(self, init_conf=None, **kwargs):
        init_conf = self._open_conf(init_conf)
        if init_conf:
            self._init.update(init_conf)
        self._init.update(kwargs)

    def init(self):
        raise NotImplementedError("init() not implemented")

    def close(self):
        pass

    def set_configuration(self, conf):
        raise NotImplementedError("set_configuration() not implemented")

    def get_configuration(self):
        raise NotImplementedError("get_configuration() not implemented")


class Dut(Base):
    '''Device
    '''
    def __init__(self, conf):
        super(Dut, self).__init__(conf)
        self._transfer_layer = None
        self._hardware_layer = None
        self._user_drivers = None
        self._registers = None
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
            except NotImplementedError:
                pass

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

    def close(self):
        for item in self._transfer_layer.itervalues():
            item.close()
        for item in self._hardware_layer.itervalues():
            item.close()
        for item in self._user_drivers.itervalues():
            item.close()
        for item in self._registers.itervalues():
            item.close()

    def set_configuration(self, conf):
        conf = self._open_conf(conf)
        if conf:
            for item, item_conf in conf.iteritems():
                if item != 'conf_path':
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
            if 'name' in self._conf:
                self.name = self._conf['name']
            else:
                self.name = None
            if 'version' in self._conf:
                self.version = self._conf['version']
            else:
                self.version = None
            self._transfer_layer = {}
            self._hardware_layer = {}
            self._user_drivers = {}
            self._registers = {}

        if 'transfer_layer' in conf:
            for intf in conf['transfer_layer']:
                intf['parent'] = self
                kargs = {}
                kargs['conf'] = intf
                self._transfer_layer[intf['name']] = self._factory('basil.TL.' + intf['type'], *(), **kargs)

        if 'hw_drivers' in conf:
            if conf['hw_drivers']:
                for hwdrv in conf['hw_drivers']:
                    hwdrv['parent'] = self
                    kargs = {}
                    if not hwdrv['interface'] or hwdrv['interface'].lower() == 'none':
                        kargs['intf'] = None
                    else:
                        kargs['intf'] = self._transfer_layer[hwdrv['interface']]
                    kargs['conf'] = hwdrv
                    self._hardware_layer[hwdrv['name']] = self._factory('basil.HL.' + hwdrv['type'], *(), **kargs)

        if 'user_drivers' in conf:
            if conf['user_drivers']:
                for userdrv in conf['user_drivers']:
                    userdrv['parent'] = self
                    kargs = {}
                    kargs['hw_driver'] = self._hardware_layer[userdrv['hw_driver']]
                    kargs['conf'] = userdrv
                    self._user_drivers[userdrv['name']] = self._factory('basil.UL.' + userdrv['type'], *(), **kargs)

        if 'registers' in conf:
            if conf['registers']:
                for reg in conf['registers']:
                    reg['parent'] = self
                    kargs = {}
                    if 'driver' in reg:
                        if not reg['driver'] or reg['driver'].lower() == 'none':
                            kargs['driver'] = None
                        else:
                            kargs['driver'] = self._user_drivers[reg['driver']]
                        kargs['conf'] = reg
                        self._registers[reg['name']] = self._factory('basil.RL.' + reg['type'], *(), **kargs)
                    elif 'hw_driver' in reg:
                        kargs['driver'] = self._hardware_layer[reg['hw_driver']]
                        kargs['conf'] = reg
                        self._registers[reg['name']] = self._factory('basil.RL.' + reg['type'], *(), **kargs)
                    else:
                        raise ValueError('No driver specified for register: %s' % (reg['name'],))

    def _factory(self, importname, *args, **kargs):
        def is_base_class(item):
            return isclass(item) and issubclass(item, Base) and item.__module__ == importname
        try:
            mod = import_module(importname)
        except ImportError:
            exc = sys.exc_info()
            splitted_import_name = importname.split('.')
            if len(splitted_import_name) > 2:  # give it another try
                try:
                    importname = '.'.join(splitted_import_name[2:])  # remove "basil.RL." etc.
                    mod = import_module(importname)
                except ImportError:
                    raise exc[0], exc[1], exc[2]
            else:  # finally raise exception
                raise
        clsmembers = getmembers(mod, is_base_class)
        if len(clsmembers) > 1:
            raise ValueError('Found more than one matching class in %s.' % importname)
        elif not len(clsmembers):
            raise ValueError('Found no matching class in %s.' % importname)
        cls = clsmembers[0][1]
        return cls(*args, **kargs)

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

    # TODO:
    def __setitem__(self, key, value):
        self._registers[key].set(value)

    def __repr__(self):
        return str(self.get_configuration())
