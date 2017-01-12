### Ethernet example for the MMC3 hardware

This example shows how to control a GPIO module and how to receive data via the Ethernet interface.

The firmware makes use of the free SiTcp Ethernet module ([general website][url1], [community website with downloads and documentation][url2]).

[url1]: https://translate.google.de/translate?hl=de&sl=ja&tl=en&u=http%3A%2F%2Fresearch.kek.jp%2Fpeople%2Fuchida%2Ftechnologies%2FSiTCP%2F

[url2]: https://sitcp.bbtech.co.jp/

1. Data transfer is started by setting a bit [0] in the GPIO.
2. FPGA starts to send data from a 32 bit counter, as fast as possible through a FIFO.
3. Python receives the data and counts bytes during a given time period.
4. At the end, the average data rate is printed and the FPGA data source is stopped by clearing bit [0].
