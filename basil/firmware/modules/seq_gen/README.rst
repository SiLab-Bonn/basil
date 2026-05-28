
================================
**seq_gen** - Pattern generator
================================

Module implements a simple sequencer/pattern generator based on block ram. Supports 2 levels of internal loops and external start.

**Unit test/Example:**
`test_SimSeq.v <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimSeq.v>`_
`test_SimSeq.py <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimSeq.py>`_

**Usage notes**

* **Tracks**: The seq_gen supports OUT_BITS from 1 to at least 256. Each output bit
  is a separate track. To fill track data in software, instantiate a
  ``TrackRegister`` in the basil configuration YAML. This provides named track
  access like ``daq["seq0"]["INIT"][0:40] = bitarray("...")``.
* **Start**: The sequence can be started via a write to the ``START`` register
  (software start), or via the `SEQ_EXT_START` pin with ``EN_EXT_START`` set
  (external start). The external start is typically driven by a GPIO or
  pulse_gen output.
* **Repeat mode**: A value of 0 in the ``REPEAT`` register causes the sequence to
  repeat forever (until reset or reconfiguration).
* **Output hold**: When the sequence finishes or stops, the last output state
  is held on ``SEQ_OUT`` — it does not return to zero. The sequencer does not
  reset its outputs on completion.
* **START and READY share the same address**: The ``START`` (write-only) and
  ``DONE`` (read-only) registers are aliased at the same address. Writing to
  address 1 triggers a start, reading address 1 returns the done flag.
  This pattern is consistent across seq_gen, spi, and pulse_gen.

**Parameters:**
    +--------------+---------------------+-------------------------------------------------------------------------+
    | Name         | Default             | Description                                                             |
    +==============+=====================+=========================================================================+
    | MEM_BYTES    | 16384               | Amount of memory allocated for data (in bytes)                          |
    +--------------+---------------------+-------------------------------------------------------------------------+
    | OUT_BITS     | 8                   | Size (bit) for output pattern - word size                               |
    +--------------+---------------------+-------------------------------------------------------------------------+

**Pins:**
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | Name          | Size                | Direction             | Description                                          |
    +===============+=====================+=======================+======================================================+
    | SEQ_EXT_START | 1                   |  input                | external start signal (synchronous to SEQ_CLK)       |
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | SEQ_CLK       | 1                   |  input                | external clock used for driving sequence             |
    +---------------+---------------------+-----------------------+------------------------------------------------------+
    | SEQ_OUT       | OUT_BITS            |  output               | sequencer output                                     |
    +---------------+---------------------+-----------------------+------------------------------------------------------+

**Registers:**
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | Name          | Address                          | Bits   | r/w   | Default     | Description                                                                                |
    +===============+==================================+========+=======+=============+============================================================================================+
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    |RESET / VERSION|                0                 |        | wo/ro |             |                           Soft reset on write / Firmware version                           |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    |  START / DONE |                1                 |        | wo/ro |      0      |                   Start sequence on write / Indicates sequence finished                    |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | EN_EXT_START  | 2                                | [0]    | r/w   | 0           | Enable external start                                                                      |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | CLK_DIV       | 3                                | [7:0]  | r/w   | 1           | Internal division factor for SEQ_CLK                                                       |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | SIZE          | 7 - 4                            | [31:0] | r/w   | out_words   | Set the size of sequence (in output words)                                                 |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | WAIT          | 11 - 8                           | [31:0] | r/w   | 0           | Waits after every sequence if REPEAT != 0 (0 -> forever)                                   |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | REPEAT        | 15 - 12                          | [31:0] | r/w   | 1           | Repeat sequence count (0 -> forever)                                                       |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | REP_START     | 19 - 16                          | [31:0] | r/w   | 0           | Position from which pattern will start in repeat mode (first sequence always starts at 0)  |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | NESTED_START  | 23 - 20                          | [31:0] | r/w   | 0           | Position from which pattern will start for nested loop                                     |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | NESTED_STOP   | 27 - 24                          | [31:0] | r/w   | 0           | Position to which pattern will stop for nested loop                                        |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | NESTED_REPEAT | 31 - 28                          | [31:0] | r/w   | 0           | Repeat count for nested loop                                                               |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | MEM_BYTES     | 35 - 32                          | [31:0] | ro    | MEM_BYTES   | Memory size (read only)                                                                    |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
    | DATA          | 64 to 64+MEM_BYTES-1             |        | r/w   | unknown     | Memory for pattern                                                                         |
    +---------------+----------------------------------+--------+-------+-------------+--------------------------------------------------------------------------------------------+
