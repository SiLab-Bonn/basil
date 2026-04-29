from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer

class signal_counter(RegisterHardwareLayer):

    _registers = {
        "COUNTER_1": {"descr": {"addr":0, "size": 32, "properties": ["ro"]}},
        "COUNTER_2": {"descr": {"addr":4, "size": 32, "properties": ["ro"]}},
        "COUNTER_3": {"descr": {"addr":8, "size": 32, "properties": ["ro"]}},
        "COUNTER_4": {"descr": {"addr":12, "size": 32, "properties": ["ro"]}},
        "COUNTER_5": {"descr": {"addr":16, "size": 32, "properties": ["ro"]}},
        "CLK_CYC"  : {"descr": {"addr":20, "size": 32}},
        "RESET"    : {"descr": {"addr":24, "size": 1}}
    }
     
    #_require_version = "==1" # was ist das/ wofür

    def __init__(self, intf, conf):
        super().__init__(intf, conf)

    def get_counter_1(self) -> list: #evtl int
        return self.COUNTER_1

    def get_counter_2(self) -> list:
        return self.COUNTER_2

    def get_counter_3(self) -> list:
        return self.COUNTER_3

    def get_counter_4(self) -> list:
        return self.COUNTER_4
    
    def get_counter_5(self) -> list:
        return self.COUNTER_5

    def set_clk_cyc(self, clk_cyc: int) -> None:
        self.CLK_CYC = clk_cyc
    
    def set_reset(self, reset: bool) -> None:
        self.RESET = reset