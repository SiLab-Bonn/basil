
======================================
**spi** - Serial peripheral interface
======================================

Module implements master serial peripheral interface. Supports simple internal loops.

**Unit test/Example:**
`test_SimSpi.v <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimSpi.v>`_
`test_SimSpi.py <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimSpi.py>`_

**Usage notes**

* **External start**: When ``EN`` is set, the SPI transfer can be triggered via
  the ``EXT_START`` pin instead of a software write to ``START``.
* **Repeat mode**: A value of 0 in the ``REPEAT`` register causes the transfer
  to repeat forever.
* **START and DONE share the same address**: The ``START`` (write-only) and
  ``DONE`` (read-only) registers are aliased at the same address. Writing to
  address 1 triggers a start, reading address 1 returns the done flag.
  This pattern is consistent across seq_gen, spi, and pulse_gen.

**Parameters:**
    +--------------+---------------------+------------------------------------------------------------------------+
    | Name         | Default             | Description                                                            |
    +==============+=====================+========================================================================+
    | MEM_BYTES    | 16                  | Amount of memory allocated for data (maximum single transfer in bytes) |
    +--------------+---------------------+------------------------------------------------------------------------+

**Pins:**
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | Name         | Size                | Direction             | Description                                          |
    +==============+=====================+=======================+======================================================+
    | SPI_CLK      | 1                   |  input                | clock used for SPI transfers                         |
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | SCLK         | 1                   |  output               | external clock (active only during transfers)        |
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | SDO          | 1                   |  input                | incoming data                                        |
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | SDI          | 1                   |  output               | outgoing data                                        |
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | SEN          | 1                   |  output               | active high during transfer                          |
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | SLD          | 1                   |  output               | active high strobe indicating end of transfer        |
    +--------------+---------------------+-----------------------+------------------------------------------------------+
    | EXT_START    | 1                   |  input                | active high start signal (synchronous to SPI_CLK)    |
    +--------------+---------------------+-----------------------+------------------------------------------------------+

**Registers:**
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | Name         | Address                          | Bits   | r/w   | Default     | Description                                 |
    +==============+==================================+========+=======+=============+=============================================+
    |START / DONE  |1                                 |        |wo/ro  |0            |Start transfer / Indicate transfer finish    |
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | SIZE         | 4 - 3                            | [15:0] | r/w   | MEM_BYTES*8 | Set the size of transfer in bits            |
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | WAIT         | 8 - 5                            | [31:0] | r/w   | 4           | Waits after every transfer if REPEAT != 0   |
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | REPEAT       | 12 - 9                           | [31:0] | r/w   | 1           | Repeat transfer count (0 -> forever)        |
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | EN           | 13                               | [0]    | r/w   | 0           | Enable external start (0 -> soft start only)|
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | MEM_BYTES    | 15 - 14                          | [15:0] | ro    | MEM_BYTES   | Byte size of memory                         |
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | DATA_OUT     | 16 to 16+MEM_BYTES-1             |        | r/w   | unknown     | Memory for outgoing data                    |
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
    | DATA_IN      | 16+MEM_BYTES to 16+2*MEM_BYTES-1 |        | r/w   | unknown     | Memory for incoming data                    |
    +--------------+----------------------------------+--------+-------+-------------+---------------------------------------------+
