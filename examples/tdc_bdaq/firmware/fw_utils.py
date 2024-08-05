#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Module to manage firmware, download additional modules etc.
    This represents a subset of the BDAQ53 firmware_manager.
'''

import logging
import coloredlogs
import fileinput
import os.path
import git

logger = logging.getLogger(__name__)
coloredlogs.install(level='DEBUG', logger=logger)

sitcp_repo = r'https://github.com/BeeBeansTechnologies/SiTCP_Netlist_for_Kintex7'
sitcp_10G_repo = r'https://github.com/BeeBeansTechnologies/SiTCPXG_Netlist_for_Kintex7'

fw_path = os.path.os.getcwd()


def get_si_tcp():
    ''' Download SiTCP/SiTCP10G sources from official github repo and apply patches
    '''

    def line_prepender(filename, line):
        with open(filename, 'rb+') as f:
            content = f.read()
            f.seek(0, 0)
            add = bytearray()
            add.extend(map(ord, line))
            add.extend(map(ord, '\n'))
            f.write(add + content)

    sitcp_folder = os.path.join(fw_path, 'SiTCP/')

    logger.info(sitcp_folder)

    # Only download if not already existing SiTCP git repository
    if not os.path.isdir(os.path.join(sitcp_folder)):
        if not os.path.isdir(os.path.join(sitcp_folder, '.git')):
            logger.info('Downloading SiTCP')

            # Has to be moved to be allowed to use existing folder for git checkout
            git.Repo.clone_from(url=sitcp_repo,
                                to_path=sitcp_folder, branch='master')
            # Patch sources, see README of bdaq53
            line_prepender(filename=sitcp_folder + 'TIMER.v', line=r'`default_nettype wire')
            line_prepender(filename=sitcp_folder + 'WRAP_SiTCP_GMII_XC7K_32K.V', line=r'`default_nettype wire')
            for line in fileinput.input([sitcp_folder + 'WRAP_SiTCP_GMII_XC7K_32K.V'], inplace=True):
                print(line.replace("assign\tMY_IP_ADDR[31:0]\t= (~FORCE_DEFAULTn | (EXT_IP_ADDR[31:0]==32'd0) \t? DEFAULT_IP_ADDR[31:0]\t\t: EXT_IP_ADDR[31:0]\t\t);",
                                   'assign\tMY_IP_ADDR[31:0]\t= EXT_IP_ADDR[31:0];'), end='')
        else:  # update if existing
            g = git.cmd.Git(sitcp_folder)
            g.pull()

    sitcp_10G_folder = os.path.join(fw_path, 'SiTCP10G/')
    # Only download if not already existing SiTCP10G git repository
    if not os.path.isdir(os.path.join(sitcp_10G_folder, '.git')):
        logger.info('Downloading SiTCP10G')

        # Has to be moved to be allowed to use existing folder for git checkout
        git.Repo.clone_from(url=sitcp_10G_repo,
                            to_path=sitcp_10G_folder, branch='master')
        # Patch sources, see README of bdaq53
        for line in fileinput.input([sitcp_10G_folder + 'WRAP_SiTCPXG_XC7K_128K.v'], inplace=True):
            print(line.replace("\t\t.MY_IP_ADDR	\t\t\t\t\t(MY_IP_ADDR[31:0]	\t\t\t),\t// in\t: My IP address[31:0]",
                               "\t\t.MY_IP_ADDR	\t\t\t\t\t({8'd192, 8'd168, 8'd100, 8'd12}),\t// in\t: My IP address[31:0]"), end='')

    else:  # update if existing
        g = git.cmd.Git(sitcp_10G_folder)
        g.pull()


if __name__ == '__main__':
    get_si_tcp()
