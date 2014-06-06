#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#


from basil.RL.RegisterLayer import RegisterLayer


class FunctionalRegister(RegisterLayer):

    def __init__(self, driver, conf):
        RegisterLayer.__init__(self, driver, conf)
