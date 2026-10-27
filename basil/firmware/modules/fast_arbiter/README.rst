
==========================================
**fast_arbiter** - Round-robin arbiter
==========================================

Round-robin arbiter for data streams with priority.
It is a replacement for ``rrp_arbiter`` with shorter combinational paths.

**Usage notes**

* **Priority**: A stream with ``PRIO_REQ`` and ``WRITE_REQ`` set is served before all other streams,
  the lowest stream first. ``PRIO_REQ`` without ``WRITE_REQ`` has no effect.
* **Round-robin**: The pointer advances only when a word is transferred.
* **Differences to rrp_arbiter**: ``HOLD_REQ`` of ``rrp_arbiter`` reserves the output even without data.
  Such a reservation has to be handled upstream when replacing ``rrp_arbiter``. ``fast_arbiter`` only
  prioritizes streams that actually have data.

**Parameters:**
    +--------------+---------------------+-------------------------------------------------------------------------+
    | Name         | Default             | Description                                                             |
    +==============+=====================+=========================================================================+
    | WIDTH        | 4                   | Number of incoming data streams                                         |
    +--------------+---------------------+-------------------------------------------------------------------------+
    | DWIDTH       | 32                  | Data width of a single stream                                           |
    +--------------+---------------------+-------------------------------------------------------------------------+

**Pins:**
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
    | Name         | Size                | Direction             | Description                                                      |
    +==============+=====================+=======================+==================================================================+
    | WRITE_REQ    | WIDTH               | input                 | indicate will of writing data (from upstream)                    |
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
    | PRIO_REQ     | WIDTH               | input                 | serve given stream(s) first (priority), starting with lowest one |
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
    | DATA_IN      | WIDTH*DWIDTH        | input                 | incoming data for arbitration                                    |
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
    | READ_GRANT   | WIDTH               | output                | indicate to stream that data has been accepted (to upstream)     |
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
    | READY_OUT    | 1                   | input                 | indicate ready for outgoing stream (from downstream)             |
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
    | WRITE_OUT    | 1                   | output                | indicate will of write to outgoing stream (to downstream)        |
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
    | DATA_OUT     | DWIDTH              | output                | outgoing data stream                                             |
    +--------------+---------------------+-----------------------+------------------------------------------------------------------+
