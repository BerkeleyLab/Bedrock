from migen import Module

from litex.soc.interconnect.csr import AutoCSR


class Zest(Module, AutoCSR):
    def __init__(self, i2c_pads):
        pass
