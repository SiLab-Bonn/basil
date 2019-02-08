
=============================
**gpio** - general purpose io
=============================

General purpose input output (gpio) is a generic pins whose behavior, including whether it is an input or output pin, can be controlled by the user at run time.  

**Unit test/Example:** 
`test_SimGpio.v <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimGpio.v>`_ 
`test_SimGpio.py <https://github.com/SiLab-Bonn/basil/blob/master/tests/test_SimGpio.py>`_

Parameters
    +--------------+---------------------+-----------------------------------------------------------------+ 
    | Name         | Default             | Description                                                     | 
    +==============+=====================+=================================================================+ 
    | IO_WIDTH     | 8                   | Defines io width in bits                                        | 
    +--------------+---------------------+-----------------------------------------------------------------+ 
    | IO_DIRECTION | 0                   | Defines direction for every pin separate, 0 - input, 1 - output |
    +--------------+---------------------+-----------------------------------------------------------------+ 
    | IO_TRI       | 0                   | instantiate tri-state buffer for given pin                      |
    +--------------+---------------------+-----------------------------------------------------------------+ 

Pins
    +--------------+---------------------+-----------------------+-----------------------------------------+ 
    | Name         | Size                | Direction             | Description                             | 
    +==============+=====================+=================================================================+ 
    | IO           | IO_WIDTH            |  IO_DIRECTION/IO_TRI  | General purpose pins                    | 
    +--------------+---------------------+-----------------------------------------------------------------+ 

Registers
    +------------+---------------------+----------------------------------------+ 
    | Name       | Address             | Description                            | 
    +============+=====================+========================================+ 
    | RESET      | 0                   | Soft reset active on write to address  | 
    +------------+---------------------+----------------------------------------+ 
    | INPUT      | 1 to BYTE           | Readback of state of pin               |
    +------------+---------------------+----------------------------------------+ 
    | OUTPUT     | 1+BYTE to 2*BYTE    | Set output state on pin                |
    +------------+---------------------+----------------------------------------+ 
    | DIRECTION  | 1+2*BYTE to 3*BYTE  | Tri-state pin (if enabled)             |  
    +------------+---------------------+----------------------------------------+

    Where: BYTE = IO_WIDTH/8+1
