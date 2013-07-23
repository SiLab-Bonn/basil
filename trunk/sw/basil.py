
#sys.path.append('./TL')

import sys

import types
def imports():
    for name, val in globals().items():
        if isinstance(val, types.ModuleType):
            print val.__name__#yield val.__name__

class DUT:
    
    def __init__(self, config):
        self._transfer_layer = dict()
        self._hardware_layer = dict()
        self._user_drivers = dict()
        self._registers = dict()
    
        for intf in config['transfer_layer']:
            kargs = {}
            kargs['conf'] = intf
            self._transfer_layer[ intf['name'] ] = self._factory( 'TL.'+intf['type'] , intf['type'] , *(), **kargs)
        
        for hwdrv in config['hw_drivers']:
            kargs = {}
            kargs['intf'] = self._transfer_layer[ hwdrv['interface']]
            kargs['conf'] = hwdrv
            self._hardware_layer[ hwdrv['name'] ] = self._factory( 'HL.'+hwdrv['type'], hwdrv['type'], *(), **kargs)
         
        for userdrv in config['user_drivers']:
            kargs = {}
            kargs['hw_driver'] = self._hardware_layer[ userdrv['hw_driver'] ]
            kargs['conf'] = userdrv
            self._user_drivers[ userdrv['name'] ] = self._factory( 'UL.'+userdrv['type'], userdrv['type'], *(), **kargs)
            
        for reg in config['registers']:
            kargs = {}
            if 'driver' in reg:
                kargs['driver'] = self._user_drivers[ reg['driver'] ]
                kargs['conf'] = reg
                self._registers[ reg['name'] ] = self._factory('RL.'+reg['type'], reg['type'], *(), **kargs)
            elif 'hw_driver' in reg:
                kargs['driver'] = self._hardware_layer[ reg['hw_driver'] ]
                kargs['conf'] = reg
                self._registers[ reg['name'] ] = self._factory('RL.'+reg['type'], reg['type'], *(), **kargs)
            else:
                raise ValueError('No driver specyfied or reister %s' (reg['name']))
        
    def test(self):
        for intf in self._transfer_layer :
            print self._transfer_layer [ intf ]
            self._transfer_layer [ intf ].read(33,2)
            self._transfer_layer [ intf ].write(0, (4,5))
            
        for hwdrw in self._hardware_layer :
            print self._hardware_layer [ hwdrw ], self._hardware_layer [ hwdrw ]._intf, hex(self._hardware_layer [ hwdrw ]._base_addr)
    
    def _factory(self, importnamem, classname, *args,  **kargs):
        #aClass = getattr(__import__(__name__), className)
        #aClass = getattr(__import__(__name__), name)
        
        _temp = __import__(importnamem, globals(), locals(), [classname], -1)
        aClass = getattr(_temp, classname)
        return aClass(*args,  **kargs)
    
    def __getitem__(self, items):
        return self._registers[items]

    #TODO
    def __setitem__(self, key, value):
        self._registers[key].set( value )
