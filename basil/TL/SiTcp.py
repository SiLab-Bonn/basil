#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# A transfer layer for SiTCP Ethernet. More information: http://sitcp.bbtech.co.jp
#

import logging
import socket
import select
import struct
import re
from array import array
from threading import Thread
from threading import RLock as Lock
from time import time

from basil.TL.SiTransferLayer import SiTransferLayer
from basil.HL.sram_fifo import sram_fifo


# Fake SRAM version to ensure compatibility with the simulation
sram_fifo_version = int(re.findall(r'\d+', sram_fifo._require_version)[-1])

logger = logging.getLogger(__name__)


class SiTcp(SiTransferLayer):
    '''SiTcp transport layer.transport

    UDP (RBCP) Header+Data

    Bit 7         Bit 0
    +-----------------+
    |  Ver.  |  Type  |
    +-----------------+
    |   CMD  |  FLAG  |
    +-----------------+
    |        ID       |
    +-----------------+
    |   Data Length   |
    +-----------------+
    | Address [31:24] |
    +-----------------+
    | Address [23:16] |
    +-----------------+
    | Address [15:8]  |
    +-----------------+
    | Address [7:0]   |
    +-----------------+
    |      Data 0     |
    +-----------------+
    |      Data 1     |
    +-----------------+
    |       ...       |
    +-----------------+
    |     Data N-1    |
    +-----------------+
    |      Data N     | (N max. 255)
    +-----------------+

    CMD Field

    +-----+------------+-------------+
    | BIT |    Name    | Description |
    +--------------------------------+
    |  3  |   Access   | Bus Access  |
    +--------------------------------+
    |  2  |    R/W     | 0:Wr,1:Read |
    +--------------------------------+
    |  1  |  Reserved  |   Always 0  |
    +--------------------------------+
    |  0  |  Reserved  |   Always 0  |
    +-----+------------+-------------+

    FALG Field

    +-----+------------+-------------+
    | BIT |    Name    | Description |
    +--------------------------------+
    |  3  |  REQ/ACK   | 0:Req,1:Ack |
    +--------------------------------+
    |  2  |  Reserved  |   Always 0  |
    +--------------------------------+
    |  1  |  Reserved  |   Always 0  |
    +--------------------------------+
    |  0  |    Error   |   0:Normal  |
    |     |            | 1:Bus Error |
    +-----+------------+-------------+


    TCP to BUS Header+Data

    Bit 7         Bit 0
    +-----------------+
    |   Length [7:0]  |
    +-----------------+
    |   Length [15:8] |
    +-----------------+
    | Address [7:0]   |
    +-----------------+
    | Address [15:8]  |
    +-----------------+
    | Address [23:16] |
    +-----------------+
    | Address [31:24] |
    +-----------------+
    |      Data 0     |
    +-----------------+
    |      Data 1     |
    +-----------------+
    |       ...       |
    +-----------------+
    |  Data Length-1  |
    +-----------------+
    |   Data Length   | (Length max. 65529)
    +-----------------+

    TCP to BUS reset sequence (in case of status invalid): 65535 * 0xff + 6 * 0x00

    '''
    # UDP(RBCP) interface
    RBCP_VER = 0xff
    RBCP_CMD_WR = 0x80
    RBCP_CMD_RD = 0xC0
    RBCP_MAX_SIZE = 255  # bytes

    UDP_TIMEOUT = 1.0  # in seconds
    UDP_RETRANSMIT_CNT = 3  # set retry counts

    BASE_DATA_TCP = 0x100000000
    BASE_FAKE_FIFO_TCP = 0x200000000  # above this read will return size of local TCP fifo (4 bytes)

    def __init__(self, conf):
        super(SiTcp, self).__init__(conf)
        self._sock_udp = None
        self._sock_tcp = None
        self._udp_lock = Lock()
        self._tcp_lock = Lock()
        self._tcp_readout_interval = 0.05
        self._tcp_readout_thread = None
        self._tcp_read_buff = None
        self.RBCP_ID = 0

    def reset(self):
        with self._tcp_lock:
            self._tcp_read_buff = array('B')

    def reset_fifo(self):
        with self._tcp_lock:
            fifo_size = self._get_tcp_data_size()
            fifo_int_size = int((fifo_size - (fifo_size % 4)) / 4)
            del_size = fifo_int_size * 4
            self._tcp_read_buff = self._tcp_read_buff[del_size:]

    def init(self):
        super(SiTcp, self).init()
        self.reset()
        if 'ip' not in self._init:  # check for IP address
            raise ValueError('Parameter \'ip\' missing.')
        if 'udp_port' not in self._init:  # check for UDP port
            raise ValueError('Parameter \'udp_port\' missing.')
        connect_timeout = float(self._init.get('connect_timeout', 5.0))  # in seconds

        self._sock_udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._sock_udp.settimeout(connect_timeout)
        self._sock_udp.connect((self._init['ip'], self._init['udp_port']))
        self._sock_udp.settimeout(None)  # https://stackoverflow.com/questions/3432102/python-socket-connection-timeout
        # using select to monitor socket status, therefore the socket is set to blocking (default)
        self._sock_udp.setblocking(0)
        # start readout thread if TCP connection is set
        if 'tcp_connection' in self._init and self._init['tcp_connection']:
            if 'tcp_port' not in self._init:
                raise ValueError('Parameter \'tcp_port\' missing.')
            self._sock_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self._sock_tcp.settimeout(connect_timeout)
            self._sock_tcp.connect((self._init['ip'], self._init['tcp_port']))
            self._sock_tcp.settimeout(None)  # https://stackoverflow.com/questions/3432102/python-socket-connection-timeout
            # using select to monitor socket status, therefore the socket is set to blocking (default)
            self._sock_tcp.setblocking(0)
            self._tcp_readout_thread = Thread(target=self._tcp_readout, name='TcpReadoutThread', kwargs={})
            self._tcp_readout_thread.daemon = True  # exiting program even when thread is alive
            self._stop = False
            self._tcp_readout_thread.start()
            if 'tcp_to_bus' in self._init and self._init['tcp_to_bus']:
                self._reset_tcp_to_bus()
        else:
            self._sock_tcp = None

    def _write_single(self, addr, data):
        retry_write_cnt = 0
        while True:
            if self.RBCP_ID >= 255:
                self.RBCP_ID = 0
            else:
                self.RBCP_ID += 1
            request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_WR, self.RBCP_ID, len(data), addr))
            request += data
            while True:
                rlist, _, _ = select.select([self._sock_udp], [], [], 0.0)
                if rlist:
                    # Read just enough for the header,
                    # remaining meassge data is lost.
                    rbcp_recv_pending = self._sock_udp.recv(3)
                    if len(rbcp_recv_pending) == 3:
                        rbcp_pending_status = array('B', rbcp_recv_pending)
                        logger.warning('SiTcp:_write_single - Pending RBCP data before send - RBCP message ID: current: %d, read: %d' % (self.RBCP_ID, rbcp_pending_status[2]))
                    else:
                        logger.warning('SiTcp:_write_single - Pending data before send')
                else:
                    break
            retry_write_cnt += 1
            _, wlist, _ = select.select([], [self._sock_udp], [], self.UDP_TIMEOUT)
            if not wlist and retry_write_cnt <= self.UDP_RETRANSMIT_CNT:
                logger.warning('SiTcp:_write_single - Write timeout - Retry...')
                continue
            elif not wlist:
                raise IOError('SiTcp:_write_single - Write timeout')
            else:
                total_sent = self._sock_udp.send(request)
                if total_sent != len(request):
                    raise IOError('SiTcp:_write_single - Socket broken')
                retry_read_cnt = 0
                while True:
                    retry_read_cnt += 1
                    rlist, _, _ = select.select([self._sock_udp], [], [], self.UDP_TIMEOUT)
                    if not rlist:
                        if retry_read_cnt <= self.UDP_RETRANSMIT_CNT:
                            logger.warning('SiTcp:_write_single - Read timeout - Retry...')
                            continue
                        elif retry_write_cnt <= self.UDP_RETRANSMIT_CNT:
                            logger.warning('SiTcp:_write_single - Read timeout - Retry write...')
                            break
                        else:
                            raise IOError('SiTcp:_write_single - Read timeout')
                    else:
                        # Recv buffer needs to be longer than message size,
                        # otherwise remaining message data is not read out and is lost.
                        rbcp_recv = self._sock_udp.recv(1024)
                        if len(rbcp_recv) < 8:
                            raise IOError('SiTcp:_write_single - Invalid RBCP message')
                        rbcp_status = array('B', rbcp_recv[:8])
                        if rbcp_status[2] != self.RBCP_ID:
                            if retry_read_cnt <= self.UDP_RETRANSMIT_CNT:
                                logger.warning('SiTcp:_write_single - Wrong RBCP message ID - Retry...')
                                continue
                            elif retry_write_cnt <= self.UDP_RETRANSMIT_CNT:
                                logger.warning('SiTcp:_write_single - Wrong RBCP message ID - Retry write...')
                                break
                            else:
                                raise IOError('SiTcp:_write_single - Wrong RBCP message ID')
                        if rbcp_status[0] != self.RBCP_VER:
                            raise IOError('SiTcp:_write_single - Invalid RBCP version')
                        if (0x0f & rbcp_status[1]) != 0x8:
                            raise IOError('SiTcp:_write_single - RBCP bus error')
                        if rbcp_status[3] != request[3]:
                            raise IOError('SiTcp:_write_single - RBCP size mismatch - expected: %d, read: %d' % (request[3], rbcp_status[3]))
                        if rbcp_status[4:8] != request[4:8]:
                            raise IOError('SiTcp:_write_single - RBCP address mismatch - expected: %d, read: %d' % (request[4:8], rbcp_status[4:8]))
                        if len(rbcp_recv) != len(request):
                            raise IOError('SiTcp:_write_single - Invalid RBCP message byte size - expected bytes: %d, received bytes: %d' % (len(request), len(rbcp_recv)))
                        rbcp_data = array('B', rbcp_recv[8:])
                        if rbcp_data != data:
                            raise IOError('SiTcp:_write_single - RBCP data mismatch - expected: %s, read: %s' % (data, rbcp_data))
                        while True:
                            rlist, _, _ = select.select([self._sock_udp], [], [], 0.0)
                            if rlist:
                                # Read just enough for the header,
                                # remaining meassge data is lost.
                                rbcp_recv_pending = self._sock_udp.recv(3)
                                if len(rbcp_recv_pending) == 3:
                                    rbcp_pending_status = array('B', rbcp_recv_pending)
                                    logger.warning('SiTcp:_write_single - Pending RBCP data after recv - RBCP message ID: current: %d, read: %d' % (self.RBCP_ID, rbcp_pending_status[2]))
                                else:
                                    logger.warning('SiTcp:_write_single - Pending data after recv')
                            else:
                                break
                        return

    def write(self, addr, data):
        if addr < self.BASE_DATA_TCP:
            if self._sock_tcp is not None and 'tcp_to_bus' in self._init and self._init['tcp_to_bus']:
                arr = array('B', struct.pack('<HI', len(data), addr))
                arr += array('B', data)
                with self._udp_lock:
                    self._send_tcp_data(arr)
            else:
                buff = array('B', data)
                with self._udp_lock:
                    new_addr = addr
                    for req in chunks(buff, self.RBCP_MAX_SIZE):
                        self._write_single(new_addr, req)
                        new_addr += len(req)
        elif addr < self.BASE_FAKE_FIFO_TCP:
            with self._tcp_lock:
                self._sock_tcp.sendall(data)  # chunking?
        # resetting SiTcp buffer
        # the buffer may contain random (?) data words after setting
        # up of the TCP socket and stating of the readout thread
        elif addr == self.BASE_FAKE_FIFO_TCP:
            self.reset()
        else:
            logger.warning("SiTcp:write - Invalid address %s" % hex(addr))

    def _read_single(self, addr, size):
        retry_write_cnt = 0
        while True:
            if self.RBCP_ID >= 255:
                self.RBCP_ID = 0
            else:
                self.RBCP_ID += 1
            request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_RD, self.RBCP_ID, size, addr))
            while True:
                rlist, _, _ = select.select([self._sock_udp], [], [], 0.0)
                if rlist:
                    # Read just enough for the header,
                    # remaining meassge data is lost.
                    rbcp_recv_pending = self._sock_udp.recv(3)
                    if len(rbcp_recv_pending) == 3:
                        rbcp_pending_status = array('B', rbcp_recv_pending)
                        logger.warning('SiTcp:_read_single - Pending RBCP data before send - RBCP message ID: current: %d, read: %d' % (self.RBCP_ID, rbcp_pending_status[2]))
                    else:
                        logger.warning('SiTcp:_read_single - Pending data before send')
                else:
                    break
            retry_write_cnt += 1
            _, wlist, _ = select.select([], [self._sock_udp], [], self.UDP_TIMEOUT)
            if not wlist and retry_write_cnt <= self.UDP_RETRANSMIT_CNT:
                logger.warning('SiTcp:_read_single - Write timeout - Retry...')
                continue
            elif not wlist:
                raise IOError('SiTcp:_read_single - Write timeout')
            else:
                total_sent = self._sock_udp.send(request)
                if total_sent != len(request):
                    raise IOError('SiTcp:_read_single - Socket broken')
                retry_read_cnt = 0
                while True:
                    retry_read_cnt += 1
                    rlist, _, _ = select.select([self._sock_udp], [], [], self.UDP_TIMEOUT)
                    if not rlist:
                        if retry_read_cnt <= self.UDP_RETRANSMIT_CNT:
                            logger.warning('SiTcp:_read_single - Read timeout - Retry...')
                            continue
                        elif retry_write_cnt <= self.UDP_RETRANSMIT_CNT:
                            logger.warning('SiTcp:_read_single - Read timeout - Retry write...')
                            break
                        else:
                            raise IOError('SiTcp:_read_single - Read timeout')
                    else:
                        # Recv buffer needs to be longer than message size,
                        # otherwise remaining message data is not read out and is lost.
                        rbcp_recv = self._sock_udp.recv(1024)
                        if len(rbcp_recv) < 8:
                            raise IOError('SiTcp:_read_single - Invalid RBCP message')
                        rbcp_status = array('B', rbcp_recv[:8])
                        if rbcp_status[2] != self.RBCP_ID:
                            if retry_read_cnt <= self.UDP_RETRANSMIT_CNT:
                                logger.warning('SiTcp:_read_single - Wrong RBCP message ID - Retry...')
                                continue
                            elif retry_write_cnt <= self.UDP_RETRANSMIT_CNT:
                                logger.warning('SiTcp:_read_single - Wrong RBCP message ID - Retry write...')
                                break
                            else:
                                raise IOError('SiTcp:_read_single - Wrong RBCP message ID')
                        if rbcp_status[0] != self.RBCP_VER:
                            raise IOError('SiTcp:_read_single - Invalid RBCP version')
                        if (0x0f & rbcp_status[1]) != 0x8:
                            raise IOError('SiTcp:_read_single - RBCP bus error')
                        if rbcp_status[3] != request[3]:
                            raise IOError('SiTcp:_read_single - RBCP size mismatch - expected: %d, read: %d' % (request[3], rbcp_status[3]))
                        if rbcp_status[4:8] != request[4:8]:
                            raise IOError('SiTcp:_read_single - RBCP address mismatch - expected: %d, read: %d' % (request[4:8], rbcp_status[4:8]))
                        if len(rbcp_recv) != size + 8:
                            raise IOError('SiTcp:_read_single - Invalid RBCP message byte size - expected bytes: %d, received bytes: %d' % (size + 8, len(rbcp_recv)))
                        rbcp_data = array('B', rbcp_recv[8:])
                        while True:
                            rlist, _, _ = select.select([self._sock_udp], [], [], 0.0)
                            if rlist:
                                # Read just enough for the header,
                                # remaining meassge data is lost.
                                rbcp_recv_pending = self._sock_udp.recv(3)
                                if len(rbcp_recv_pending) == 3:
                                    rbcp_pending_status = array('B', rbcp_recv_pending)
                                    logger.warning('SiTcp:_read_single - Pending RBCP data after recv - RBCP message ID: current: %d, read: %d' % (self.RBCP_ID, rbcp_pending_status[2]))
                                else:
                                    logger.warning('SiTcp:_read_single - Pending data after recv')
                            else:
                                break
                        return rbcp_data

    def read(self, addr, size):
        if addr < self.BASE_DATA_TCP:
            ret = array('B')
            with self._udp_lock:
                if size > self.RBCP_MAX_SIZE:
                    new_addr = addr
                    next_size = self.RBCP_MAX_SIZE
                    while next_size < size:
                        ret += self._read_single(new_addr, self.RBCP_MAX_SIZE)
                        new_addr = addr + next_size
                        next_size = next_size + self.RBCP_MAX_SIZE
                    ret += self._read_single(new_addr, size + self.RBCP_MAX_SIZE - next_size)
                else:
                    ret += self._read_single(addr, size)
            return ret
        elif addr < self.BASE_FAKE_FIFO_TCP:
            return self._get_tcp_data(size)
        elif addr == self.BASE_FAKE_FIFO_TCP:
            return array('B', chr(sram_fifo_version))
        else:  # this is to fake a HL fifo. Is there better way? Definitely...
            if size == 4:
                return array('B', struct.pack('I', self._get_tcp_data_size()))
            else:
                return array('B', '\x00' * size)  # FIXME: workaround for SRAM module registers
#                 logger.warning("SiTcp:read - Invalid address %s" % hex(addr))

    def _tcp_readout(self):
        time_read = time()
        while not self._stop:
            try:  # this is in case close() was not called and the thread was forcibly stopped
                rlist, _, _ = select.select([self._sock_tcp], [], [], max(0.0, self._tcp_readout_interval + time_read - time()))
                time_read = time()
                if rlist:
                    with self._tcp_lock:
                        data = self._sock_tcp.recv(1024 * 8)
                        self._tcp_read_buff.extend(array('B', data))
            except AttributeError:
                pass

    def _get_tcp_data_size(self):
        with self._tcp_lock:
            size = len(self._tcp_read_buff)
        return size

    def _get_tcp_data(self, size):
        with self._tcp_lock:
            ret_size = min((size, self._get_tcp_data_size()))
            ret_size = (ret_size - (ret_size % 4))  # modulo 4 bytes
            ret = self._tcp_read_buff[:ret_size]
            self._tcp_read_buff = self._tcp_read_buff[ret_size:]
        return ret

    def _send_tcp_data(self, data):
        total_sent = 0
        while not self._stop:
            _, wlist, _ = select.select([], [self._sock_tcp], [], self._tcp_readout_interval)
            if wlist:
                sent = self._sock_tcp.send(data[total_sent:])
                if sent == 0:
                    raise IOError('SiTcp:_send_tcp_data - Socket broken')
                total_sent += sent
                if total_sent == len(data):
                    break

    def _reset_tcp_to_bus(self):
        self._send_tcp_data(array('B', [255] * 65535))
        self._send_tcp_data(array('B', [0] * 6))

    def close(self):
        super(SiTcp, self).close()
        self._stop = True
        self._tcp_readout_thread.join()
        self._tcp_readout_thread = None
        self._sock_udp.close()
        if self._init['tcp_connection']:
            self._sock_tcp.close()


def chunks(array, max_len):
    index = 0
    while index < len(array):
        yield array[index: index + max_len]
        index += max_len
