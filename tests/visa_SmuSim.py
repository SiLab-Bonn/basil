import pyvisa
from pyvisa_sim.devices import Device
from pyvisa_sim import sessions
from pyvisa_sim.sessions.serial import SerialInstrumentSession
from pyvisa_sim.sessions.tcpip import TCPIPInstrumentSession


class SmuSimDevice(Device):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Track the SMU data format state internally
        self.smu_format = 'ASCII'

    def write(self, message):
        # Intercept the format configuration command
        if 'FORM' in message.upper():
            if 'BIN' in message.upper() or 'REAL' in message.upper():
                self.smu_format = "BINARY"
            else:
                self.smu_format = "ASCII"
            return "OK"

        # Fall back to standard YAML behaviour for other writes
        return super().write(message)

    def query(self, message):
        # Intercept the identical query syntax and branch based state
        if "printbuffer(1, smua.measure.count, smua.nvbuffer1)" in message.upper() or\
                "printbuffer(2, smua.measure.count, smua.nvbuffer1)" in message.upper():
            if self.smu_format == "BINARY":
                # Example: Return IEEE 488.2 arbitrary block data
                # #I4 followed by 4 bytes representing float 1.0 (e.g.
                return b"#0\x00\x00\x00`\x11\'t>\x00\x00\x00\xc0s\x1at>\x00\x00\x00@\x00)t>\x00\x00\x00\x00\x961t>\x00\x00\x00\xc0\xd2$t>\x00\x00\x00`a3t>\x00\x00\x00 \x13)t>\x00\x00\x00\xe0\xcf)t>\x00\x00\x00\x80\x8d$t>\x00\x00\x00\x00\x98$t>\x00\x00\x00\x00U1t>\x00\x00\x00\xe0\x01,t>\x00\x00\x00\xe0\xe5\x14t>\x00\x00\x00\xa0\xbb2t>\x00\x00\x00\x80\xf1\x1at>\x00\x00\x00\xc0x1t>\x00\x00\x00@\x8b3t>\x00\x00\x00@\xa6\'t>\x00\x00\x00`u\x0ft>\x00\x00\x00`5At>\x00\x00\x00\x00J\'t>\x00\x00\x00\x00\xd0(t>\x00\x00\x00\x00\xd6\x1ct>\x00\x00\x00\x00\x1c&t>\x00\x00\x00`2*t>\x00\x00\x00`\x90-t>\x00\x00\x00\x80\xf0!t>\x00\x00\x00\xa0g3t>\x00\x00\x00\x80\xc1\'t>\x00\x00\x00 \xa45t>\x00\x00\x00\xa0\xd7-t>\x00\x00\x00\xa0o\'t>\x00\x00\x00 M.t>\x00\x00\x00`\x94 t>\x00\x00\x00`\xbd&t>\x00\x00\x00 54t>\x00\x00\x00 +#t>\x00\x00\x00@\x00)t>\x00\x00\x00@ \x17t>\x00\x00\x00`;&t>\n"
            else:
                # Return standard ASCII string representation
                return "7.50743E-08,7.48907E-08,7.51024E-08,7.52273E-08,7.50416E-08,7.52534E-08,7.51035E-08,7.51142E-08,7.50377E-08,7.50383E-08,7.52236E-08,7.51461E-08,7.48099E-08,7.52440E-08,7.48978E-08,7.52257E-08,7.52558E-08,7.50827E-08,7.47307E-08,7.54547E-08,7.50775E-08,7.50997E-08,7.49254E-08,7.50603E-08,7.51198E-08,7.51688E-08,7.49996E-08,7.52538E-08,7.50843E-08,7.52863E-08,7.51728E-08,7.50796E-08,7.51795E-08,7.49799E-08,7.50695E-08,7.52655E-08,7.50175E-08,7.51024E-08,7.48423E-08,7.50621E-08"

        # Fall back to standard YAML queries for everything else
        return super().query(message)

# Overwrite the session class or map your custom device type
# so PyVISA-sim instantiates your subclass instead of the default one
class CustomTCPIPSession(TCPIPInstrumentSession):
    device_class = SmuSimDevice

class CustomSerialSession(SerialInstrumentSession):
    device_class = SmuSimDevice

# Register your custom session behaviour into the PyVISA-sim runtime
sessions.Session.register(CustomTCPIPSession)
sessions.Session.register(CustomSerialSession)

# Now initialize your backend as usual pointing to your yaml file
rm = pyvisa.ResourceManager('/path/to/your/simulation_file.yaml@sim')
inst = rm.open_resource('TCPIP:192.168.1.10::inst0::INSTR')
