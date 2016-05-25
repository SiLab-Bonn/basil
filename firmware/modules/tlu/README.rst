
=====================================
**tlu** - trigger logic unit
=====================================

General purpose trigger module and EUDAQ Telescope/TLU communication module. Trigger IDs received by the TLU are propagated to FIFO data interface.

NOTE:
 1. TRIGGER_ENABLE has to be asserted to allow triggering.
 2. If no TRIGGER_ACKNOWLEDGE signal is available, connect TRIGGER_ACCEPTED_FLAG output to TRIGGER_ACKNOWLEDGE input.
 3. TRIGGER_ENABLE and TRIGGER_ACKNOWLEDGE input signals needs to be synchronous to TRIGGER_CLOCK.
 4. TRIGGER_ENABLE input and TRIGGER_ENABLE register are ORed. To start trigger FSM, assert TRIGGER_ENABLE input or set TRIGGER_ENABLE register to 1.
 5. Data words have the MSB always high to allow identification of data words. The remaining 31 bits are data.
 6. All selected trigger inputs (TRIGGER) are ORed
 7. All selected trigger veto inputs (TRIGGER_VETO) are ORed (all veto inputs are enabled by default!)
 8. If TRIGGER_LOW_TIMEOUT_ERROR_COUNTER in TLU handshake mode is not 0, the busy signal might be broken.
 9. If TLU_TRIGGER_ACCEPT_ERROR_COUNTER in TLU handshake mode is not 0, the TLU might be not configured properly (must be in handshake mode) or short pulses are appearing on the trigger line. Possible solution is to increase TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES.
10. TLU_TRIGGER_MAX_CLOCK_CYCLES should always be one more clock cycle than the bit lenght of the trigger data to return the trigger line to logical low.

TRIGGER_MODE[1:0]:
 1. 0 = normal trigger mode
 2. 1 = TLU no handshake
 3. 2 = TLU simple handshake
 4. 3 = TLU trigger data handshake

DATA_FORMAT[1:0]:
 1. 0 = trigger number according to TRIGGER_MODE
 2. 1 = time stamp only
 3. 2 = combined, 15bit time stamp + 16bit trigger number
 4. 3 = n/a

**Unit test/Example:** 
`test_SimTlu.v <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimTlu.v>`_ 
`test_SimTlu.py <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimTlu.py>`_

Parameters
    +------------------------------+---------------------+--------------------------------------------------------------------------+
    | Name                         | Default             | Description                                                              |
    +==============================+=====================+==========================================================================+
    | DIVISOR                      | 8                   | Defines TLU clock speed. TLU clock is divided by Divisor.                |
    +------------------------------+---------------------+--------------------------------------------------------------------------+
    | TLU_TRIGGER_MAX_CLOCK_CYCLES | 17                  | Number of clock cycles send to the TLU. Bit lenght of trigger data is -1.|
    +------------------------------+---------------------+--------------------------------------------------------------------------+

Pins
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | Name                     | Size                | Direction             | Description                                          |
    +==========================+=====================+=======================+======================================================+
    | TRIGGER_CLOCK            | 1                   |  input                | clock for module                                     |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER                  | 8                   |  input (async)        | extenel trigger                                      |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_VETO             | 8                   |  input (async)        | external veto                                        |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_ENABLE           | 1                   |  input (sync)         | enable trigger FSM, ORed with TRIGGER_ENABLE register|
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_ACKNOWLEDGE      | 1                   |  input (sync)         | signal from external devices/modules if ready        |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_ACCEPTED_FLAG    | 1                   |  output               | flag for trigger is valid and was accepted           |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_TRIGGER              | 1                   |  input (async)        | TLU trigger input                                    |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_RESET                | 1                   |  input (async)        | TLU reset input                                      |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_BUSY                 | 1                   |  output               | TLU busy output                                      |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_CLOCK                | 1                   |  output               | TLU clock output                                     |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TIMESTAMP                | 32                  |  output               | timestamp counter for external devices/modules       |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
Registers
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | Name                                   | Address                          | Bits   | r/w   | Default     | Description                                           |
    +========================================+==================================+========+=======+=============+=======================================================+
    | RESET                                  | 0                                |        | wo    |             | reset                                                 |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | VERSION                                | 0                                | [7:0]  | ro    | 0           | version                                               |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_MODE                           | 1                                | [1:0]  | r/w   | 0           | external/TLU trigger mode                             |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_DATA_MSB_FIRST                 | 1                                | [2]    | r/w   | 0           | TLU trigger number MSB                                |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_ENABLE                         | 1                                | [3]    | r/w   | 0           | enable trigger FSM, ORed with TRIGGER_ENABLE input    |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_DATA_DELAY                     | 1                                | [7:4]  | r/w   | 0           | additional TLU data delay for longer cables           |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | DATA_FORMAT                            | 2                                | [1:0]  | r/w   | 0           | format of trigger number output                       |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | EN_TLU_RESET_TIMESTAMP                 | 2                                | [5]    | r/w   | 0           | reset time stamp to 0 on TLU reset                    |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | EN_TLU_VETO                            | 2                                | [6]    | r/w   | 0           | assert TLU veto when external veto                    |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_LOW_TIMEOUT                    | 3                                | [7:0]  | r/w   | 255         | max. wait cycles for TLU trigger low (0=off)          |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | CURRENT_TLU_TRIGGER_NUMBER             | 7 - 4                            | [31:0] | ro    |             | last TLU trigger number                               |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_COUNTER                        | 11 - 8                           | [31:0] | r/w   | 0           | trigger counter value                                 |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | LOST_DATA_COUNTER                      | 12                               | [7:0]  | ro    |             | lost data counter                                     |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_SELECT                         | 13                               | [7:0]  | r/w   | 0           | selecting trigger input                               |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_VETO_SELECT                    | 14                               | [7:0]  | r/w   | 0           | selecting veto input                                  |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_INVERT                         | 15                               | [7:0]  | r/w   | 0           | invert selected trigger input                         |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | MAX_TRIGGERS                           | 16 - 19                          | [31:0] | r/w   | 0           | maximum triggers, use 0 for unltd. triggers           |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES   | 20                               | [7:0]  | r/w   | 3           | TLU trigger minimum length in TLU clock cycles        |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | HANDSHAKE_BUSY_VETO_WAIT_CYCLES        | 21                               | [7:0]  | r/w   | 0           | additional wait cycles before de-asserting TLU busy   |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_LOW_TIMEOUT_ERROR_COUNTER      | 22                               | [7:0]  | ro    |             | trigger low timeout error counter                     |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TLU_TRIGGER_ACCEPT_ERROR_COUNTER       | 23                               | [7:0]  | ro    |             | trigger accept error counter                          |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_THRESHOLD                      | 24                               | [7:0]  | r/w   | 0           | trigger minimum length in TLU clock cycles            |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
