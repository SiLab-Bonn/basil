
=====================================
**tlu** - trigger logic unit
=====================================

General purpose trigger module and EUDAQ Telescope/TLU communication module. Trigger IDs received by the TLU are propagated to FIFO data interface.

NOTE:
 1. TRIGGER_ENABLE register has to be set to true to enable trigger FSM.
 2. EXT_TRIGGER_ENABLE and TRIGGER_ACKNOWLEDGE input signals needs to be synchronous to TRIGGER_CLOCK.
 3. Data words have the MSB always high to allow identification of trigger data words. The remaining 31 bits are data.
 4. All selected trigger inputs are ORed. Trigger inputs are connected to TRIGGER input. Trgger inputs are selected by applying a bit mask to TRIGGER_SELECT.
 5. All selected veto inputs are ORed. Veto inputs are connected to TRIGGER_VETO input. Veto inputs are selected by applying a bit mask to TRIGGER_VETO_SELECT.
 6. If TRIGGER_LOW_TIMEOUT_ERROR_COUNTER in TLU handshake mode is not 0, the busy signal might be broken.
 7. If TLU_TRIGGER_ACCEPT_ERROR_COUNTER in TLU handshake mode is not 0, the TLU might be not configured properly (must be in handshake mode) or short pulses are appearing on the trigger line. Possible solution is to increase TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES.
 8. TLU_TRIGGER_MAX_CLOCK_CYCLES should always be one more clock cycle than the bit lenght of the trigger data to return the trigger line to logical low.

TRIGGER_MODE[1:0]:
 1. 0 = normal trigger mode (receiving triggers from input TRIGGER)
 2. 1 = EUDAQ TLU - no handshake
 3. 2 = EUDAQ TLU - simple handshake
 4. 3 = EUDAQ TLU - trigger data handshake

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
    | WIDTH                        | 8 (max. 32)         | Bus width of the trigger input and trigger veto input.                   |
    +------------------------------+---------------------+--------------------------------------------------------------------------+
    | TIMESTAMP_N_OF_BIT           | 32                  | Bus width of time stamp.                                                 |
    +------------------------------+---------------------+--------------------------------------------------------------------------+

Pins
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | Name                     | Size                | Direction             | Description                                          |
    +==========================+=====================+=======================+======================================================+
    | TRIGGER_CLK              | 1                   |  input                | clock for module                                     |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_ENABLED          | 1                   |  output (sync)        | assert signal when trigger FSM is enabled and running|
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_SELECTED         | WIDTH (max. 32)     |  output (sync)        | selected trigger inputs                              |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_ENABLED              | 1                   |  output (sync)        | assert signal when trigger mode is != 0 (EUDAQ TLU)  |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER                  | WIDTH (max. 32)     |  input (async)        | extenel trigger (see also WIDTH parameter)           |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_VETO             | WIDTH (max. 32)     |  input (async)        | external veto (see also WIDTH parameter)             |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TIMESTAMP_RESET          | 1                   |  input (async)        | resetting timestamp counter                          |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | EXT_TRIGGER_ENABLE       | 1                   |  input (sync)         | enables sync with other external devices/modules     |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_ACKNOWLEDGE      | 1                   |  input (sync)         | signal/flag from external devices/modules if ready   |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TRIGGER_ACCEPTED_FLAG    | 1                   |  output               | flag if trigger is valid and was accepted            |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | FIFO_PREEMPT_REQ         | 1                   |  output               | fast signal that put arbiter on hold                 |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_TRIGGER              | 1                   |  input (async)        | TLU trigger input                                    |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_RESET                | 1                   |  input (async)        | TLU reset input                                      |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_BUSY                 | 1                   |  output               | TLU busy output                                      |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TLU_CLOCK                | 1                   |  output               | TLU clock output                                     |
    +--------------------------+---------------------+-----------------------+------------------------------------------------------+
    | TIMESTAMP                | 32                  |  output               | timestamp counter provided for other devices/modules |
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
    | TRIGGER_ENABLE                         | 1                                | [3]    | r/w   | 0           | enable trigger FSM                                    |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | DATA_FORMAT                            | 2                                | [1:0]  | r/w   | 0           | format of trigger number output                       |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | EN_TLU_RESET_TIMESTAMP                 | 2                                | [5]    | r/w   | 0           | reset time stamp to 0 on TLU reset (handsh. mode only)|
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
    | TRIGGER_SELECT                         | 13 - 16                          | [31:0] | r/w   | 0           | selecting trigger input (see also WIDTH parameter)    |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_VETO_SELECT                    | 17 - 20                          | [31:0] | r/w   | 0           | selecting veto input (see also WIDTH parameter)       |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_INVERT                         | 21 - 24                          | [31:0] | r/w   | 0           | inverting selected trigger input                      |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | MAX_TRIGGERS                           | 25 - 28                          | [31:0] | r/w   | 0           | maximum triggers, use 0 for unltd. triggers           |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES   | 29                               | [7:0]  | r/w   | 3           | TLU trigger minimum length in TLU clock cycles        |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | HANDSHAKE_BUSY_VETO_WAIT_CYCLES        | 30                               | [7:0]  | r/w   | 0           | additional wait cycles before de-asserting TLU busy   |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_LOW_TIMEOUT_ERROR_COUNTER      | 31                               | [7:0]  | ro    |             | trigger low timeout error counter                     |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TLU_TRIGGER_ACCEPT_ERROR_COUNTER       | 32                               | [7:0]  | ro    |             | trigger accept error counter                          |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_THRESHOLD                      | 33                               | [7:0]  | r/w   | 0           | trigger minimum length in TLU clock cycles            |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | SOFT_TRIGGER                           | 34                               | [7:0]  | wo    | n/a         | manual software trigger (requires TRIGGER_MODE=0)     |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
    | TRIGGER_DATA_DELAY                     | 35                               | [7:0]  | r/w   | 0           | additional TLU data delay for longer cables           |
    +----------------------------------------+----------------------------------+--------+-------+-------------+-------------------------------------------------------+
