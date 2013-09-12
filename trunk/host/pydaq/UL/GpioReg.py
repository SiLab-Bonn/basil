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


class GPIOReg(UserLayer):

    def write(self, addr, data):
        print self.__class__.__name__, ': Revived data   addr=', hex(addr), 'data=', data
        self._drv.write(addr, data)
