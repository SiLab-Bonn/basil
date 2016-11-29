### Ethernet example for the MMC3 hardware

This example shows how to control a GPIO module and how to receive data via the Ethernet interface.

1. Data transfer is started by setting a bit [0] in the GPIO.
2. FPGA starts to send data from a 32 bit counter, as fast as possible through a FIFO.
3. Python receives the data during a given time period and counts the bytes while doing so.
4. At the end, the average data rate is printed and the FPGA data source is stopped by clearing bit [0].
