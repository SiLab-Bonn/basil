
Basil modules
===============

.. begin-include

Modules connect to a simple single-master bus. Every module has a similar set of parameters and pins for bus integration. The full list of firmware modules can be found in the `firmware/modules <https://github.com/SiLab-Bonn/basil/tree/master/basil/firmware/modules>`_ folder, and their Python drivers in `basil/HL <https://github.com/SiLab-Bonn/basil/tree/master/basil/HL>`_.

The following parameters, pins, and registers are common to all bus-connected modules. Individual modules add their own on top of these.

**Common parameters:**

+--------------+---------------------+--------------------------------------------------------------------+
| Name         | Default             | Description                                                        |
+==============+=====================+====================================================================+
| BASEADDR     | 0                   | Defines base address of module (start address) in memory map space |
+--------------+---------------------+--------------------------------------------------------------------+
| HIGHADDR     | 0                   | Defines last module address in memory map space                    |
+--------------+---------------------+--------------------------------------------------------------------+
| ABUSWIDTH    | 16                  | Address bus width                                                  |
+--------------+---------------------+--------------------------------------------------------------------+
| DBUSWIDTH    | 8                   | Data bus width                                                     |
+--------------+---------------------+--------------------------------------------------------------------+

**Common pins:**

+--------------+-------------------------+-----------+------------------------------------------------------+
| Name         | Size                    | Direction | Description                                          |
+==============+=========================+===========+======================================================+
| BUS_RST      | 1                       | input     | Synchronous reset, active high                       |
+--------------+-------------------------+-----------+------------------------------------------------------+
| BUS_CLK      | 1                       | input     | Bus clock                                            |
+--------------+-------------------------+-----------+------------------------------------------------------+
| BUS_WR       | 1                       | input     | Write strobe, active high                            |
+--------------+-------------------------+-----------+------------------------------------------------------+
| BUS_RD       | 1                       | input     | Read strobe, active high                             |
+--------------+-------------------------+-----------+------------------------------------------------------+
| BUS_ADD      | ABUSWIDTH               | input     | Address bus                                          |
+--------------+-------------------------+-----------+------------------------------------------------------+
| BUS_DATA     | DBUSWIDTH (typically 8) | inout     | Data bus                                             |
+--------------+-------------------------+-----------+------------------------------------------------------+

**Common registers:**

+------------+----------------+-------+----------------------------------------+
| Name       | Address        | r/w   | Description                            |
+============+================+=======+========================================+
| RESET      | 0              | wo    | Soft reset on write to address         |
+------------+----------------+-------+----------------------------------------+
| VERSION    | 0              | ro    | Module version                         |
+------------+----------------+-------+----------------------------------------+