#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import os
from importlib import import_module
from inspect import getmembers, isclass
from yaml import safe_load
import sys
import warnings
from collections import OrderedDict
from six import string_types

# FIXME: Bad practice
# Logger settings should not be defined in a module, but once by the
# application developer. Thus outside of basil. Otherwise multiple calls to
# the basic config are possible. This is left here at the moment for backward
# compatibility and since our logging format is the same everywhere (?).
import logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - [%(levelname)-8s] (%(threadName)-10s) %(message)s")


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
        def isFile(f):
            return isinstance(f, file) if sys.version_info[0] == 2 else hasattr(f, 'read')

        conf_dict = {}
        if not conf:
            pass
        elif isinstance(conf, string_types):  # parse the first YAML document in a stream
            if os.path.isfile(conf):
                with open(conf, 'r') as f:
                    conf_dict.update(safe_load(f))
                    conf_dict.update(conf_path=f.name)
            else:  # YAML string
                try:
                    conf_dict.update(safe_load(conf))
                except ValueError:  # invalid path/filename
                    raise IOError("File not found: %s" % conf)
        elif isFile(conf):  # parse the first YAML document in a stream
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
        self._initialized = True

    @property
    def is_initialized(self):
        if "_initialized" in self.__dict__ and self._initialized:
            return True
        else:
            return False

    def close(self):
        self._initialized = False

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
        self._registers = None
        self.load_hw_configuration(self._conf)

    def init(self, init_conf=None, **kwargs):
        super(Dut, self).init()
        init_conf = self._open_conf(init_conf)

        def update_init(mod):
            if init_conf:
                if mod.name in init_conf:
                    mod._update_init(init_conf[mod.name])
            if mod.name in kwargs:
                mod._update_init(kwargs[mod.name])

        def catch_exception_on_init(mod):
            try:
                mod.init()
            except NotImplementedError:
                pass

        for item in self._transfer_layer.values():
            update_init(item)
            catch_exception_on_init(item)
        for item in self._hardware_layer.values():
            update_init(item)
            catch_exception_on_init(item)
        for item in self._registers.values():
            update_init(item)
            catch_exception_on_init(item)

    def close(self):
        def catch_exception_on_close(mod):
            if mod.is_initialized:
                try:
                    mod.close()
                except Exception:  # if close() failed
                    # restore status after close() failed
                    mod._is_initialized = True

        for item in self._registers.values():
            catch_exception_on_close(item)
        for item in self._hardware_layer.values():
            catch_exception_on_close(item)
        for item in self._transfer_layer.values():
            catch_exception_on_close(item)

    def set_configuration(self, conf):
        conf = self._open_conf(conf)
        if conf:
            for item, item_conf in conf.items():
                if item != 'conf_path':
                    try:
                        self[item].set_configuration(item_conf)
                    except NotImplementedError:
                        pass

    def get_configuration(self):
        conf = {}
        for key, value in self._registers.items():
            try:
                conf[key] = value.get_configuration()
            except NotImplementedError:
                conf[key] = {}
        for key, value in self._hardware_layer.items():
            try:
                conf[key] = value.get_configuration()
            except NotImplementedError:
                conf[key] = {}
        for key, value in self._transfer_layer.items():
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
            self._transfer_layer = OrderedDict()
            self._hardware_layer = OrderedDict()
            self._registers = OrderedDict()

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
                    if 'interface' in hwdrv:
                        if hwdrv['interface'].lower() == 'none':
                            kargs['intf'] = None
                        else:
                            kargs['intf'] = self._transfer_layer[hwdrv['interface']]
                    elif 'hw_driver' in hwdrv:
                        kargs['intf'] = self._hardware_layer[hwdrv['hw_driver']]
                    else:
                        kargs['intf'] = None
                    kargs['conf'] = hwdrv
                    self._hardware_layer[hwdrv['name']] = self._factory('basil.HL.' + hwdrv['type'], *(), **kargs)

        if 'user_drivers' in conf:
            warnings.warn("Deprecated: user_drivers move modules to hw_drivers", DeprecationWarning)
            if conf['user_drivers']:
                for userdrv in conf['user_drivers']:
                    userdrv['parent'] = self
                    kargs = {}
                    kargs['intf'] = self._hardware_layer[userdrv['hw_driver']]
                    kargs['conf'] = userdrv
                    self._hardware_layer[userdrv['name']] = self._factory('basil.HL.' + userdrv['type'], *(), **kargs)

        if 'registers' in conf:
            if conf['registers']:
                for reg in conf['registers']:
                    reg['parent'] = self
                    kargs = {}
                    if 'driver' in reg:
                        if not reg['driver'] or reg['driver'].lower() == 'none':
                            kargs['driver'] = None
                        else:
                            kargs['driver'] = self._hardware_layer[reg['driver']]
                        kargs['conf'] = reg
                        self._registers[reg['name']] = self._factory('basil.RL.' + reg['type'], *(), **kargs)
                    elif 'hw_driver' in reg:
                        kargs['driver'] = self._hardware_layer[reg['hw_driver']]
                        kargs['conf'] = reg
                        self._registers[reg['name']] = self._factory('basil.RL.' + reg['type'], *(), **kargs)
                    else:
                        raise ValueError('No driver specified for register: %s' % (reg['name'],))

    def _factory(self, importname, *args, **kargs):
        splitted_import_name = importname.split('.')

        def is_basil_base_class(item):
            return isclass(item) and issubclass(item, Base) and item.__module__ == importname

        try:
            mod = import_module(importname)
        except ImportError:  # give it another try
            if len(splitted_import_name) > 2 and splitted_import_name[0] == 'basil':
                importname = '.'.join(splitted_import_name[2:])  # remove "basil.RL." etc.
                mod = import_module(importname)
            else:  # raise initial exception
                raise
        basil_base_classes = getmembers(mod, is_basil_base_class)
        cls = None
        if not basil_base_classes:  # found no base class
            raise ValueError('Found no matching class in %s.' % importname)
        elif len(basil_base_classes) > 1:  # found more than 1 base class
            mod_name = splitted_import_name[-1]
            for basil_base_class in basil_base_classes:
                if mod_name == basil_base_class[0]:  # check for base class name
                    cls = basil_base_class[1]
                    break
            if cls is None:
                raise ValueError('Found more than one matching class in %s.' % importname)
        else:  # found single class
            cls = basil_base_classes[0][1]
        return cls(*args, **kargs)

    def __getitem__(self, item):
        if item in self._registers:
            return self._registers[item]
        elif item in self._hardware_layer:
            return self._hardware_layer[item]
        elif item in self._transfer_layer:
            return self._transfer_layer[item]
        raise KeyError('Item not existing: %s' % (item,))

    def get_modules(self, type_name):
        '''Getting modules by type name.

        Parameters
        ----------
        type_name : string
            Type name of the modules to be returned.

        Returns
        -------
        List of modules of given type name else empty list.
        '''
        modules = []
        for module in self:
            if module.__class__.__name__ == type_name:
                modules.append(module)
        return modules

    def __iter__(self):
        for item in self._registers.values():
            yield item
        for item in self._hardware_layer.values():
            yield item
        for item in self._transfer_layer.values():
            yield item

    # TODO:
    def __setitem__(self, key, value):
        self._registers[key].set(value)

    def __repr__(self):
        return str(self.get_configuration())
