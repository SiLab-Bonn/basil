import socket
import time

from basil.TL.TransferLayer import TransferLayer


class Socket(TransferLayer):
    '''
        General direct socket TL implementation.
        Used for TCP/IP based direct communication with devices.
        Commands are handled including encoding, read and write termination.
    '''

    def __init__(self, conf):
        super(Socket, self).__init__(conf)

    def init(self):
        '''
            Create socket object and connect to specified ip address and port.
        '''
        super(Socket, self).init()
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        self.encoding = self._init.get('encoding', 'utf-8')
        self.write_termination = self._init.get('write_termination', '').encode(self.encoding).decode('unicode_escape')
        self.read_termination = self._init.get('read_termination', self.write_termination).encode(self.encoding).decode('unicode_escape')
        self.query_delay = self._init.get('query_delay', 0)
        self.handle_as_byte = self._init.get('handle_as_byte', False)

        address = self._init.get('address')
        port = self._init.get('port')

        self._sock.connect((address, port))

    def close(self):
        super(Socket, self).close()
        self._sock.close()

    def write(self, data):
        if type(data) == bytes:
            cmd = data
        else:
            cmd = data.encode(self.encoding)
        cmd += self.write_termination.encode(self.encoding)
        if not self.handle_as_byte:
            cmd.decode('unicode_escape')
        self._sock.send(cmd)

    def read(self, buffer_size=1):
        ret = self._sock.recv(buffer_size)
        if not self.handle_as_byte:
            return ret.split(self.read_termination.encode(self.encoding))[:-1]
        return ret

    def query(self, data, buffer_size=1):
        self.write(data)
        time.sleep(self.query_delay)
        return self.read(buffer_size)
