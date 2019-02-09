#!/usr/bin/env python
from __future__ import print_function
import time
import sys

from bmb7.configuration.jtag import jtag, xilinx_bitfile_parser

SUBSECTOR_SIZE = 4096
SECTOR_SIZE = 65536

SPI_DOUT = 1
SPI_DIN = 2
SPI_CLK = 4
SPI_CS_B = 8

# Instructions
RDID = 0x9F
EN4BYTEADDR = 0xB7
EX4BYTEADDR = 0xE9
RDVCR = 0x85
WRVCR = 0x81
RDVECR = 0x65
WRVECR = 0x61
FAST_READ = 0x0B
WREN = 0x6
RDSR = 0x5
SSE = 0x20
SE = 0xD8
PP = 0x2
RFSR = 0x70
RESET_ENABLE = 0x66
RESET_MEMORY = 0x99


class SPI_Base_Exception(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class interface():
    def __init__(self, chain):
        self.__target = chain
        self.__cs_b = SPI_CS_B
        self.__dummy_cycles = 10  # Hard-coded to always work

        # Flush the CS_B pin
        self.__target.jtag_clock([jtag.TMS])
        self.__target.state = jtag.states.SHIFT_DR

        # self.write_register(RESET_ENABLE)
        # self.write_register(RESET_MEMORY)

        self.__prom_size = self.read_register(RDID, 3)[2]

        vcr = self.read_register(RDVCR, 1)[0]

        # Set the dummy cycles in the PROM configuration register
        vcr = self.read_register(RDVCR, 1)[0]
        vcr &= 0xF & vcr
        vcr |= self.__dummy_cycles << 4
        self.write_register(WREN)
        self.write_register(WRVCR, bytearray([vcr]))

        vcr = self.read_register(RDVCR, 1)[0]

        # Set 4 byte addressing mode
        self.write_register(WREN)
        self.write_register(EN4BYTEADDR)

        # Ready for transactions...
        # Input data latched on rising edge of CLK
        # Output data available on falling edge of CLK

        # Instruction, address (3 or 4 bytes)

        # enter 4 byte address mode en4byteaddr ex4byteaddr

    def dummy_cycles(self):
        return self.__dummy_cycles

    def prom_size(self):
        return self.__prom_size

    def write_register(self, instruction, value=bytearray([])):
        # MSB first
        self.__target.write(instruction, 8, False, False, True)
        self.__target.write_bytearray(value, False, True, False)

        # Last byte raises CS_B
        self.__target.jtag_clock([jtag.TMS])

    def read_register(self, instruction, num_bytes):
        self.__target.write(instruction, 8, False, False, True)

        # Read MSB first
        dummy = bytearray([0]) * num_bytes
        result = self.__target.write_read_bytearray(dummy, False, False, True)

        # Last byte raises CS_B
        self.__target.jtag_clock([jtag.TMS])
        return result

    def read_data(self, start_address, num_bytes):
        self.__target.write(FAST_READ, 8, False, False, True)

        # 32-bit address
        send = bytearray()
        for i in range(0, 32):
            if (start_address >> 31 - i) & 0x1:
                send += bytearray([jtag.TDI])
            else:
                send += bytearray([0])

        # Dummy cycles (first data on falling edge of last cycle)
        for i in range(0, self.__dummy_cycles):
            send += bytearray([0])

        self.__target.jtag_clock(send)

        send = bytearray([0]) * num_bytes  # * 8
        result = self.__target.write_read_bytearray(send, False, False, True)

        self.__target.jtag_clock([jtag.TMS])

        return result

    def page_program(self, data, address):
        if len(data) != 256:
            raise SPI_Base_Exception('Data is not size of page')

        # Write enable
        self.write_register(WREN)

        # Page program
        self.__target.write(PP, 8, False, False, True)

        send = bytearray()
        for i in range(0, 32):
            if (address >> 31 - i) & 0x1:
                send += bytearray([jtag.TDI])
            else:
                send += bytearray([0])

        self.__target.jtag_clock(send)
        self.__target.write_bytearray(data, False, True, False)

        # Complete transaction
        self.__target.jtag_clock([jtag.TMS])

        # Read the status register and wait for completion
        while self.read_register(RDSR, 1)[0] & 0x1:
            continue

    def subsector_erase(self, address):

        # Write enable
        self.write_register(WREN)

        # Erase a sector
        self.__target.write(SSE, 8, False, False, True)

        # 32-bit address
        send = bytearray()
        for i in range(0, 32):
            if (address >> 31 - i) & 0x1:
                send += bytearray([jtag.TDI])
            else:
                send += bytearray([0])

        self.__target.jtag_clock(send)
        self.__target.jtag_clock([jtag.TMS])

        # Read the status register and wait for completion
        x = self.read_register(RDSR, 1)[0]
        y = self.read_register(RFSR, 1)[0]
        while True:
            # print hex(x), hex(y),
            if ((x & 0x1) == 0) and ((y & 0x81) == 0x81):
                break
            x = self.read_register(RDSR, 1)[0]
            y = self.read_register(RFSR, 1)[0]

    def sector_erase(self, address):

        # Write enable
        self.write_register(WREN)

        # Erase a sector
        self.__target.write(SE, 8, False, False, True)

        # 32-bit address
        send = bytearray()
        for i in range(0, 32):
            if (address >> 31 - i) & 0x1:
                send += bytearray([jtag.TDI])
            else:
                send += bytearray([0])

        self.__target.jtag_clock(send)
        self.__target.jtag_clock([jtag.TMS])

        # Read the status register and wait for completion
        x = self.read_register(RDSR, 1)[0]
        y = self.read_register(RFSR, 1)[0]
        while True:
            # print hex(x), hex(y),
            if ((x & 0x1) == 0) and ((y & 0x81) == 0x81):
                break
            x = self.read_register(RDSR, 1)[0]
            y = self.read_register(RFSR, 1)[0]

    def program_bitfile(self, name, offset):

        # Parse the bitfile and extract the bitstream
        data = xilinx_bitfile_parser.bitfile(name).data()

        # Pad the data to the block boundary
        data += bytearray([0xFF]) * (SECTOR_SIZE - len(data) % SECTOR_SIZE)

        last_length = 0
        start_time = time.time()
        num_blocks = len(data) / SECTOR_SIZE

        for i in range(0, num_blocks):

            # Read the sector
            pd = self.read_data((offset + i) * SECTOR_SIZE, SECTOR_SIZE)
            elapsed = time.time() - start_time
            left = elapsed * (num_blocks - i - 1) / (i + 1)
            total = elapsed + left
            output = str(i + 1) + ' / ' + str(
                num_blocks) + ' (Elapsed: ' + str(elapsed) + 's, Left: ' + str(
                    left) + 's, Total: ' + str(total) + 's)'
            output = '{:<100}'.format(output)
            x = str('\b' * last_length)
            print(x, '\b' + output, end=' ')
            sys.stdout.flush()
            last_length = len(output) + 1

            sector_update = False
            sector_erase = False
            for j in range(0, SECTOR_SIZE):
                if pd[j] != data[i * SECTOR_SIZE + j]:
                    sector_update = True
                    break

            if not (sector_update):
                continue

            # Only erase the sector if the data that's changed is currently not set to 0xFF
            sector_erase = False
            for j in range(0, SECTOR_SIZE):
                if pd[j] != data[i * SECTOR_SIZE + j]:
                    if pd[j] != 0xFF:
                        sector_erase = True
                        break

            # Erase if necessary
            if sector_erase:
                self.sector_erase((offset + i) * SECTOR_SIZE)
                print('ERASED', end=' ')

            # Program the 256 byte blocks
            for j in range(0, SECTOR_SIZE / 256):
                self.page_program(data[j * 256 + i * SECTOR_SIZE:(j + 1) * 256
                                       + i * SECTOR_SIZE], j * 256 + (
                                           (offset + i) * SECTOR_SIZE))

            # Verify
            pd = self.read_data((offset + i) * SECTOR_SIZE, SECTOR_SIZE)
            for j in range(0, SECTOR_SIZE):
                if pd[j] != data[i * SECTOR_SIZE + j]:
                    print()
                    raise SPI_Base_Exception(
                        'Page update', str(i * SECTOR_SIZE + j), 'failed')

            print('UPDATED')

        print()
