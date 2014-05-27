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


from RL.RegisterLayer import RegisterLayer


class FunctionalRegister(RegisterLayer):

    def __init__(self, driver, conf):
        RegisterLayer.__init__(self, driver, conf)
