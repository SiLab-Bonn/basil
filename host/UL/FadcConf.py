#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from UL.UserLayer import UserLayer


class FadcConf(UserLayer):

    def __init__(self, hw_driver, conf):
        UserLayer.__init__(self, hw_driver, conf)

    def init(self):

        print "Initializing FADC ..."

        self._drv.set_data(0, [0x00, 0x10])  # RESET ADC
        self._drv.start()

        self._drv.set_data(0, [0x02, 0x07])  # SET 16 bit mode
        self._drv.start()

        #print 'chip[\'FADC_CONF\'].IsDone() = ', dut['FADC_CONF'].IsDone()

        #dut['FADC_CONF'].SetData([0x82, 0x00]) # SET 16 bit mode
        #dut['FADC_CONF'].Start()
