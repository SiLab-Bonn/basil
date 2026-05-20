========================================
**fast_spi_rx** - Fast serial receiver
========================================

This module can continuous capture serial data on each rising edge of it's capture clock.
Received data is packed into 32-bit words and propagated to a FIFO data interface.
While originally intended for SPI (hence the naming), it can be used for any serial data.

**Unit tests**

Unit tests for this module have not yet been implemented.

**Usage notes**

* **Data output format**: Each 32-bit FIFO word is formatted as
  ``[31:28] IDENTIFIER, [27:N] Frame counter, [N-1:0] Captured data``
  where ``N = DATA_SIZE``. The IDENTIFIER field differentiates multiple
  fast_spi_rx instances merged into the same downstream FIFO stream.
  The frame counter increments on every SEN falling edge, allowing
  reconstruction of multi-word captures. When a capture spans multiple
  FIFO words, all words carry the same frame counter value.
* **FIFO flush behavior**: A FIFO word is written when DATA_SIZE bits have
  been captured, or when SEN falls (flushing any partially-filled word).
  An incomplete frame is never lost — it is always written to the FIFO
  when SEN goes low.
* **Reset**: The soft reset (RESET register write or BUS_RST) is
  synchronised to SEQ_CLK via a CDC synchroniser. At least one rising
  edge of SEQ_CLK must occur after reset is released for it to take
  effect. If SEQ_CLK is not running when reset is asserted, the reset
  will not complete.

Parameters
----------
    +--------------+---------------------+-----------------------------------------------------------------+
    | Name         | Default             | Description                                                     |
    +==============+=====================+=================================================================+
    | ABUSWIDTH    | 16                  | Width of the bus address bus                                    |
    +--------------+---------------------+-----------------------------------------------------------------+
    | IDENTIFIER   | 4'b0001             | Instance identifier packed into bits [31:28] of each FIFO word  |
    +--------------+---------------------+-----------------------------------------------------------------+
    | DATA_SIZE    | 16                  | Number of serial data bits packed into a single FIFO word       |
    +--------------+---------------------+-----------------------------------------------------------------+

Pins
----
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | Name          | Size                | Direction             | Description                                          |
    +===============+=====================+=======================+======================================================+
    | SEQ_CLK       | 1                   | input                 | Capture clock (serial data sampled on rising edge)   |
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | SDI           | 1                   | input                 | Serial data input (sampled on SEQ_CLK rising edge)   |
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | SEN           | 1                   | input                 | Serial enable (active high, frames the capture)      |
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | FIFO_READ     | 1                   | input                 | Read strobe (pop one word from the output FIFO)      |
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | FIFO_EMPTY    | 1                   | output                | FIFO empty flag                                      |
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | FIFO_DATA     | 32                  | output                | FIFO data output (32-bit word)                       |
    +---------------+---------------------+-----------------------+------------------------------------------------------+

Registers
---------
    +---------------+---------------------+--------+-------+-------------+------------------------------------------------------------------+
    | Name          | Address             | Bits   | r/w   | Default     | Description                                                      |
    +===============+=====================+========+=======+=============+==================================================================+
    | RESET         | 0                   |        | wo    |             | Soft reset (synchronous to SEQ_CLK, takes effect on next edge)   |
    +---------------+---------------------+--------+-------+-------------+------------------------------------------------------------------+
    | VERSION       | 0                   | [7:0]  | ro    |             | Firmware version                                                 |
    +---------------+---------------------+--------+-------+-------------+------------------------------------------------------------------+
    | EN            | 2                   | [0]    | r/w   | 0           | Enable capture (set high to arm)                                 |
    +---------------+---------------------+--------+-------+-------------+------------------------------------------------------------------+
    | LOST_COUNT    | 3                   | [7:0]  | ro    | 0           | Lost data counter (incremented on CDC FIFO overflow)             |
    +---------------+---------------------+--------+-------+-------------+------------------------------------------------------------------+

**Unit tests**

Unit tests for this module have not yet been implemented.
