# Ethernet example for the BDAQ53 hardware
This example shows how to control a GPIO module and how to receive data via the Ethernet interface.
1. Data transfer is started by setting a bit [0] in the GPIO.
2. FPGA starts to send data from a 32 bit counter through a BRAM FIFO.
3. The Python script checks the received data and counts the transferred bytes during a given time period.
4. At the end, the average data rate is printed and the FPGA data source is stopped by clearing bit [0].
 
## Build script
To build this example firmware, navigate to `firmware/vivado` and start the process using the Makefile 
```terminal
cd firmware/vivado
make
```
`make download`, `make synthesize` and `make clean` can be used to call the sub-tasks individually.

The firmware makes use of the free SiTcp Ethernet module ([GitHub][url1]).
You can find further build instructions in the *Firmware section* of the ([bdaq53 readme][url2]).

[url1]: https://github.com/BeeBeansTechnologies/SiTCP_Netlist_for_Kintex7
[url2]: https://gitlab.cern.ch/silab/bdaq53#firmware

## Test
A test for CocoTB is available under `test`