from basil.dut import Dut

dut = Dut('/home/silab/git/basil/examples/lab_devices/julaboFP50_pyserial.yaml')
dut.init()


# turn on:
# dut["chiller"].start_chiller(start=True)

# dut["chiller"].set_temp(15)  # set temp

print("Status: {}".format(dut["chiller"].get_status()))

# turn off:
# dut["chiller"].stop_chiller()
