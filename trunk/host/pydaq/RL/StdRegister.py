from RL.RegisterLayer import RegisterLayer
from utils.BitLogic import BitLogic


class StdRegister(RegisterLayer):

    def __init__(self, driver, conf):
        RegisterLayer.__init__(self, driver, conf)
        self._size = conf['size']
        self._fields = dict()

        if 'fields' in conf:
            for field in conf['fields']:
                bv = BitLogic(size=field['size'])

                if 'offset' in field:
                    bv.offset = field['offset']
                else:
                    bv.offset = field['address'] * conf['width'] + field['position']

                self._fields[field['name']] = bv
        else:
            bv = BitLogic(size=self._conf['size'])
            self._fields['NONE'] = bv
            bv.offset = 0

    def __getitem__(self, items):
        print '__getitem__'
        return self._fields[items]

    def __setslice__(self, i, j, sequence):
        return self.__setitem__(slice(i, j), sequence)

    def __setitem__(self, key, value):
        if isinstance(key, slice):
            reg = self._construct_reg()
            reg[key.start:key.stop] = value
            self._deconstruct_reg(reg)
        elif isinstance(key, str):
            self._fields[key][self._fields[key].size - 1:0] = value
        elif isinstance(key, int):
            reg = self._construct_reg()
            reg[key] = value
            self._deconstruct_reg(reg)
        else:
            raise TypeError("Invalid argument type.")

    def __str__(self):
        ret = dict()
        for field in self._fields:
            ret[field] = str(len(self._fields[field])) + 'b' + str(self._fields[field])

        return str(ret)

    def set(self, value):
        bv = BitLogic(intVal=value, size=self._size)
        self._deconstruct_reg(bv)

    def write(self):
        pass
        #print self.__class__.__name__ ,': Writing to driver. addr:', self._addr, ' data:'
        #print args

        self._drv.write(self._construct_reg())  # ????? //byte array?

    def read(self):
        return self._drv.read()  # ????? //byte array

    def _construct_reg(self):
        bv = BitLogic(size=self._size)
        for field in self._fields:
            off = self._fields[field].offset
            bvsize = len(self._fields[field])
            bv[bvsize + off - 1:off] = self._fields[field]
        return bv

    def _deconstruct_reg(self, new_reg):
        for field in self._fields:
            off = self._fields[field].offset
            bvsize = len(self._fields[field])
            self._fields[field].setValue(bitstring=str(new_reg[off + bvsize - 1:off]))
