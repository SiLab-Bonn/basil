### Ethernet example for the BDAQ53 hardware

This example shows how to control a GPIO module and how to receive data via the Ethernet interface.

The firmware makes use of the free SiTcp Ethernet module ([GitHub][url1]). Put the extracted files in */firmware/src/SiTCP*.
You can find build instructions in the *Firmware section* of the ([bdaq53 readme][url2]).

[url1]: https://github.com/BeeBeansTechnologies/SiTCP_Netlist_for_Kintex7
[url2]: https://gitlab.cern.ch/silab/bdaq53#firmware

1. Data transfer is started by setting a bit [0] in the GPIO.
2. FPGA starts to send data from a 32 bit counter, as fast as possible through a FIFO.
3. Python receives the data and counts bytes during a given time period.
4. At the end, the average data rate is printed and the FPGA data source is stopped by clearing bit [0].

Test for CocoTB available in */test*
