#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from time import sleep, time

from basil.dut import Base


class HardwareLayer(Base):
    '''Hardware layer (HL) base class.
    '''
    def __init__(self, intf, conf):
        super(HardwareLayer, self).__init__(conf)
        # interface not required for some cases
        if intf is not None:
            self._intf = intf

    @property
    def is_ready(self):
        raise NotImplementedError

    def wait_for_ready(self, timeout=None, times=None, delay=None, delay_between=None, abort=None):
        '''Determine the ready state of the device and wait until device is ready.

        Parameters
        ----------
        timeout : int, float
            The maximum amount of time to wait in seconds. Reaching the timeout will raise a RuntimeError.
        times : int
            Maximum number of times reading the ready state.
        delay : int, float
            The number of seconds to sleep before checks. Defaults to 0.
        delay_between : int, float
            The number of seconds to sleep between each check. Defaults to 0.
        abort : Threading.Event
            Breaking the loop from other threads.

        Returns
        -------
        True if state is ready, else False.
        '''
        if delay:
            try:
                sleep(delay)
            except IOError:  # negative values
                pass
        if timeout is not None:
            if timeout < 0:
                raise ValueError("timeout is smaller than 0")
            else:
                stop = time() + timeout
        times_checked = 0
        while not self.is_ready:
            now = time()
            times_checked += 1
            if abort and abort.is_set():
                False
            if timeout is not None and stop <= now:
                raise RuntimeError('Time out while waiting for ready in %s, module %s' % (self.name, self.__class__.__module__))
            if times and times > times_checked:
                False
            if delay_between:
                try:
                    sleep(delay_between)
                except IOError:  # negative values
                    pass
        return True
