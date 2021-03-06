
======================================
**jtag** - serial peripheral interface
======================================

Module implements master jtag peripheral interface. Supports simple internal loops.

**Unit test/Example:** 
`test_SimJtagMaster.v <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimJtagMaster.v>`_ 
`test_SimJtagMaster.py <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimJtagMaster.py>`_

Parameters
    +--------------+---------------------+-------------------------------------------------------------------------+ 
    | Name         | Default             | Description                                                             | 
    +==============+=====================+=========================================================================+ 
    | MEM_BYTES    | 16                  | Amount of meemory allocated for data (maximum single transfer in bytes) | 
    +--------------+---------------------+-------------------------------------------------------------------------+ 

Pins
    +--------------+---------------------+-----------------------+------------------------------------------------------+ 
    | Name         | Size                | Direction             | Description                                          | 
    +==============+=====================+=======================+======================================================+ 
    | JTAG_CLK     | 1                   |  input                | clock used for SPI transfers                         | 
    +--------------+---------------------+-----------------------+------------------------------------------------------+ 
    | TCK          | 1                   |  output               | external clock (active only during transfers)        | 
    +--------------+---------------------+-----------------------+------------------------------------------------------+ 
    | TDO          | 1                   |  input                | incoming data                                        | 
    +--------------+---------------------+-----------------------+------------------------------------------------------+ 
    | TDI          | 1                   |  output               | outgoing data                                        | 
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | TMS          | 1                   |  output               | jtag machine state control pin                       | 
    +--------------+---------------------+-----------------------+------------------------------------------------------+ 
    | SEN          | 1                   |  output               | active high during transfer                          | 
    +--------------+---------------------+-----------------------+------------------------------------------------------+ 
    | SLD          | 1                   |  output               | active high strobe indicating end of transfer        | 
    +--------------+---------------------+-----------------------+------------------------------------------------------+ 
  
Registers
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 
    | Name         | Address                           | Bits   | r/w   | Default     | Description                                             | 
    +==============+===================================+========+=======+=============+=========================================================+ 
    | START        | 1                                 |        | wo    |             | start transfer on write to address                      | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 
    | DONE         | 1                                 | [0]    | ro    | 0           | indicate transfer finish                                | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 
    | BIT_OUT      | 4 - 3                             | [15:0] | r/w   | MEM_BYTES*8 | set the size of transfer in bits                        | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 
    | WAIT         | 8 - 5                             | [31:0] | r/w   | 4           | waits after every transfer if REPEAT != 0               | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 
    | WORD_COUNT   | 10 - 9                            | [15:0] | r/w   | 1           | number of word to be sent (1 word = BIT_OUT bit long)   | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+
    | JTAG COMMAND | 12 - 11                           | [15:0] | r/w   | 0           | JTAG command 0 = SCAN_IR, 1 = SCAN_DR                   | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+  
    | MEM_BYTES    | 15 - 14                           | [15:0] | ro    | MEM_BYTES   | byte size of memory                                     | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 
    | DATA_OUT     | 16 to 16+MEM_BYTES-1              |        | r/w   | unknown     | memory for outgoing data                                | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 
    | DATA_IN      | 16+MEM_BYTES to 16+2*MEM_BYTES-1  |        | r/w   | unknown     | memory for incoming data                                | 
    +--------------+-----------------------------------+--------+-------+-------------+---------------------------------------------------------+ 