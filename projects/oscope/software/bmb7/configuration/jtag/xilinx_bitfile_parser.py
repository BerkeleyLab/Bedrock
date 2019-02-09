#!/usr/bin/env python

import time, sys, hashlib

# Reverse-idcode lookup (bitfile names -> [mask, idcode])
xilinx_idcode_bitfile_dictionary = {

    # Xilinx Spartan 6 (TODO: add package codes, probably safer and more strict)
    b'6slx4' : [0x0FFFFFFF, 0x04000093],

    b'6slx9csg324' : [0x0FFFFFFF, 0x04001093],######

    b'6slx16' : [0x0FFFFFFF, 0x04002093],
    b'6slx25' : [0x0FFFFFFF, 0x04004093],
    b'6slx25t' : [0x0FFFFFFF, 0x04024093],
    b'6slx45' : [0x0FFFFFFF, 0x04008093],
    b'6slx45tcsg324' : [0x0FFFFFFF, 0x04028093],
    b'6slx75' : [0x0FFFFFFF, 0x0400E093],
    b'6slx75t' : [0x0FFFFFFF, 0x0402E093],
    b'6slx100' : [0x0FFFFFFF, 0x04011093],
    b'6slx100t' : [0x0FFFFFFF, 0x04031093],
    b'6slx150' : [0x0FFFFFFF, 0x0401D093],

    b'6slx150tfgg676' : [0x0FFFFFFF, 0x0403D093], ##########

    # Xilinx Virtex 5
    b'5vsx95tff1136' : [0x0FFFFFFF, 0x02ECE093],

    # Xilinx Kintex 7
    b'7k160tffg676' : [0x0FFFFFFF, 0x0364C093],

    # Xilinx Virtex 7
    b'7v585t'  : [0x0FFFFFFF, 0x03671093],
    #'7v2000t' : [0x0FFF3FFF, 0x036B3093], - special parts - different programmer

    b'7vx330t'  : [0x0FFFFFFF, 0x03667093],
    b'7vx415t'  : [0x0FFFFFFF, 0x03682093],

    b'7vx485tffg1927'  : [0x0FFFFFFF, 0x03687093],########
    b'7vx550tffg1927'  : [0x0FFFFFFF, 0x03692093],#########
    b'7vx690tffg1927'  : [0x0FFFFFFF, 0x03691093],#######

    b'7vx980t'  : [0x0FFFFFFF, 0x03696093],
    #'7vx1140t' : [0x0FFFFFFF, 0x036D5093], - special parts - different programmer

    b'7vh580t' : [0x0FFFFFFF, 0x036D9093],
    b'7vh870t' : [0x0FFFFFFF, 0x036DB093]

}

class Xilinx_Bitfile_Parser_Exception(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

class bitfile():
    def __init__(self, file):
        with open(file, "rb") as f:

            # Discard first 2 bytes
            bytes = bytearray(f.read(2))
            header_length = (int(bytes[0]) << 8) + int(bytes[1])
            if header_length != 9:
                raise Xilinx_Bitfile_Parser_Exception('Header length not 9 bytes')

            # Check header: 15, 240, 15, 240, 15, 240, 15, 240, 0
            bytes = bytearray(f.read(9))
            if bytes != bytearray([15, 240, 15, 240, 15, 240, 15, 240, 0]):
                raise Xilinx_Bitfile_Parser_Exception('Header magic numbers not correct')

            # Discard first length field and token
            bytes = bytearray(f.read(3))

            # Length of design name
            bytes = bytearray(f.read(2))
            name_length = (int(bytes[0]) << 8) + int(bytes[1])

            # Design name
            bytes = f.read(name_length)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect design file name length')
            # Strip the null off the end
            self.__design_name = str(bytes)[:-1]

            # Token
            bytes = f.read(1)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect token')

            # Length of device name
            bytes = bytearray(f.read(2))
            name_length = (int(bytes[0]) << 8) + int(bytes[1])

            # Device name
            bytes = f.read(name_length)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect device name length')
            # Strip the null off the end
            self.__device_name = bytes[:-1]

            if not(self.__device_name in xilinx_idcode_bitfile_dictionary):
                raise Xilinx_Bitfile_Parser_Exception('Device name not recognised - ' + self.__device_name)

            # Token
            bytes = f.read(1)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect token')

            # Length of build date
            bytes = bytearray(f.read(2))
            name_length = (int(bytes[0]) << 8) + int(bytes[1])

            # Build date
            bytes = f.read(name_length)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect build date length')
            self.__build_date = str(bytes)[:-1]

            # Token
            bytes = f.read(1)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect token')

            # Length of build time
            bytes = bytearray(f.read(2))
            name_length = (int(bytes[0]) << 8) + int(bytes[1])

            # Build time
            bytes = f.read(name_length)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect build time length')
            self.__build_time = str(bytes)[:-1]

            # Token
            bytes = f.read(1)
            if bytes == b"":
                raise Xilinx_Bitfile_Parser_Exception('Incorrect token')

            # Bitstream length
            bytes = bytearray(f.read(4))
            name_length = (int(bytes[0]) << 24) + (int(bytes[1]) << 16) + (int(bytes[2]) << 8) + int(bytes[3])
            print(('Bitstream length: ' + str(name_length) + ' bytes'))

            # Get the rest
            result = bytearray()
            while bytes != b"":
                bytes = bytearray(f.read(1000000))
                result += bytes

            if name_length != len(result):
                raise Xilinx_Bitfile_Parser_Exception('Bitstream length doesn\'t match rest of file')

            self.__bitfile_data = result

    def hash(self):
        m = hashlib.sha256()
        m.update(self.__bitfile_data)
        return bytearray(m.digest())

    def data(self):
        return self.__bitfile_data

    def design_name(self):
        return self.__design_name

    def device_name(self):
        return self.__device_name

    def build_date(self):
        return self.__build_date

    def build_time(self):
        return self.__build_time

    def length(self):
        return len(self.__bitfile_data) * 8

    def match_idcode(self, idcode):
        v = xilinx_idcode_bitfile_dictionary[self.__device_name]
        if (v[0] & idcode) == (v[0] & v[1]):
            return True
        return False
