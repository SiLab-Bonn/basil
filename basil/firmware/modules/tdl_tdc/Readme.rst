==========================================================================
**Tdl Tdc** - Tapped Delay Line based Time to Digital Converter
==========================================================================

----------------
Required modules
----------------

* `utils/3_stage_synchronizer.v`
* `utils/flag_domain_crossing.v`
* `utils/generic_fifo.v`
* `utils/cdc_syncfifo.v`
* `utils/clock_divider.v`

----------------
Key TDC figures
----------------

* 30ps RMS accuracy
* 40ns shortest reliably detectable pulse length
* 400us dynamic range


----------------
Usage
----------------
Before use, the Tdc should be calibrated. This can be done as follows::

        chip['TDL_TDC'].EN_CALIBRATION_MOD = 1
        time.sleep(1)
        chip['TDL_TDC'].EN_CALIBRATION_MOD = 0


 

This will cause the Tdc to write many ``CALIB`` words to the fifo. Subsequently any required configuration bits for the particular experiment may be set. During analysis the recorded
calibration stream is easily incorporated::
        
        calib_data_indices = chip['TDL_TDC'].is_calib_word(collected_data)

        if any(calib_data_indices) :
            calib_values = chip['TDL_TDC'].get_raw_tdl_values(np.array(collected_data[calib_data_indices]))
            chip['TDL_TDC'].set_calib_values(calib_values)
            logging.info("Calibration set using %s samples" % len(calib_values))

Optionally, you can view a histogram of the calibration using ``chip['TDL_TDC'].plot_calib_values(calib_values)``.

        If measurements are made over a longer time span, recalibration might be necessary, however note that the above example lumps all the calibration(s) in ``collected_data`` together.

The calibrated basil module can then be used the following way::
        
        time_word_indices = chip['TDL_TDC'].is_time_word(collected_data)
        time_data = collected_data[time_word_indices]
        if any(calib_data_indices) :
                time_in_ns = chip['TDL_TDC'].tdc_word_to_time(time_data[0])



----------------
Data Format
----------------
The Tdc module uses a state machine to send various types of 32 bit data words, however the first seven bits always follow the same structure:

+-------------------------+-------------------+---------------------------------------------------------+
| DATA IDENTIFIER (4 bit) | WORD TYPE (3 bit) |                     Data (25 bits)                      |
+-------------------------+-------------------+---------------------------------------------------------+

The most important words are those carrying the measured time information. Those word types are issued in the following order::
        
        [TRIGGERED] -> RISING -> FALLING -> [TIMESTAMP]

``TRIGGERED`` is only sent if ``EN_TRIGGER_DIST``, and ``TIMESTAMP`` only if ``EN_WRITE_TIMESTAMP`` is set.
In the following, we list how the remaining 25 bits are allocated for the various words.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TRIGGERED, RISING, FALLING
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



+---------------------------------------------+---------------------------+-----------------------------+
|          160 Mhz Counter (16 bits)          |  480 Mhz Counter (2 bits) |      Delay Line (7 bits)    |
+---------------------------------------------+---------------------------+-----------------------------+

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TIMESTAMP
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This word comes after the ``FALLING`` word, but the Timestamp is actually sampled two 160Mhz clock cycles after a measurement has been started.


+-------------------------------------------------------------------+-----------------------------------+
|                           Timestamp (16 bits)                     |               0 (9 bits)          |
+-------------------------------------------------------------------+-----------------------------------+


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
CALIB
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If the Tdc is set for self-calibration using ``EN_CALIBRATION_MODE``, it will repeatedly send this word.



+---------------------------------------------+---------------------------+-----------------------------+
|          0 (16 bits)                        |  480 Mhz Counter (2 bits) |      Delay Line (7 bits)    |
+---------------------------------------------+---------------------------+-----------------------------+


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
RESET
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If a reset is issued to the Tdc, either as a global bus reset or through basil, this word is sent. It might be useful for resetting a state machine
decoding the words on the receiving end. The Timestamp included is sampled as soon as 
the reset signal has passed the clock domain circuitry.

+-------------------------------------------------------------------+-----------------------------------+
|                           Timestamp (16 bits)                     |               0 (9 bits)          |
+-------------------------------------------------------------------+-----------------------------------+

