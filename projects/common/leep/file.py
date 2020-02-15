
from __future__ import print_function
import json
import hashlib

from .base import DeviceBase

import logging
_log = logging.getLogger(__name__)


class FileDevice(DeviceBase):
    backend = 'file'

    def __init__(self, jfile, timeout=None, **kws):
        DeviceBase.__init__(self, **kws)

        with open(jfile, 'rb') as F:
            J = F.read()

        self.regmap = json.loads(J)

        self.descript = 'Offline JSON'
        self.codehash = '0000000000000000000000000000000000000000'
        self.jsonhash = hashlib.new('sha1', J).hexdigest()

    def reg_write(self, ops, instance=[]):
        pass

    def reg_read(self, names, instance=[]):
        return [0]*len(names)
