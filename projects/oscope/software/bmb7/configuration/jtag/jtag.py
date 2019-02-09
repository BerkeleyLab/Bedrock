import socket
import time

from bmb7.configuration.jtag.idcodes import idcodes
import platform

# TODO - When exiting TEST_LOGIC_RESET, the device can be in BYPASS or
# IDCODE. SHIFT_DR will first emit a '1' in IDCODE, but a '0' in BYPASS.

# Maximum transmission size for a single transaction
MTU = 1400

# http://stackoverflow.com/questions/1133857/how-accurate-is-pythons-time-sleep
# A delay multiplier depending on the operating system
TIME_PER_MTU_OFFSET = 0.002 if platform.system() == 'Windows' else 0.0

# Bits
TMS = 2
TDI = 1
TDO = 1


# JTAG states
class states:
    # Normal states
    UNKNOWN = 1
    TEST_LOGIC_RESET = 2
    RUN_TEST_IDLE = 3
    SHIFT_IR = 4
    SHIFT_DR = 5
    UPDATE_IR = 6
    UPDATE_DR = 7

    # Unused states below, just for completeness
    SELECT_DR_SCAN = 8
    CAPTURE_DR = 9
    EXIT_1_DR = 10
    PAUSE_DR = 11
    EXIT_2_DR = 12

    SELECT_IR_SCAN = 13
    CAPTURE_IR = 14
    EXIT_1_IR = 15
    PAUSE_IR = 16
    EXIT_2_IR = 17


state_names = {
    states.UNKNOWN: 'UNKNOWN',
    states.TEST_LOGIC_RESET: 'TEST LOGIC RESET',
    states.RUN_TEST_IDLE: 'RUN TEST IDLE',
    states.SHIFT_IR: 'SHIFT IR',
    states.SHIFT_DR: 'SHIFT DR',
    states.UPDATE_IR: 'UPDATE IR',
    states.UPDATE_DR: 'UPDATE DR',

    # Unused states below, just for completeness
    states.SELECT_DR_SCAN: 'SELECT DR SCAN',
    states.CAPTURE_DR: 'CAPTURE DR',
    states.EXIT_1_DR: 'EXIT 1 DR',
    states.PAUSE_DR: 'PAUSE DR',
    states.EXIT_2_DR: 'EXIT 2 DR',
    states.SELECT_IR_SCAN: 'SELECT IR SCAN',
    states.CAPTURE_IR: 'CAPTURE IR',
    states.EXIT_1_IR: 'EXIT 1 IR',
    states.PAUSE_IR: 'PAUSE IR',
    states.EXIT_2_IR: 'EXIT 2 IR'
}


class EthernetToJTAGException(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class chain(states):
    def __init__(self, ip, stream_port, input_select, speed, noinit=False):
        self.state = states.UNKNOWN

        self.__pre_send_time = 0
        self.__post_send_time = 0

        # Configuration
        self.__ip = ip
        self.__stream_port = stream_port
        self.__mode_rw = True
        self.__mode_two_bit = True
        self.__mode_read_endian = False  # LSB first
        self.__mode_write_endian = False  # LSB first
        self.__bit_in_phase = 2  # 1 # Normal rising-edge mode
        self.__bit_in_select = input_select
        self.__channel_enable = 1 << input_select
        self.__speed = speed
        self.__burst_size = 1  # Single clock mode

        self.__num_devices = 0
        self.__idcodes = []

        self.__UDPSock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.__UDPSock.settimeout(5)

        # Find an available port and bind to is
        for i in range(0, 1000):
            try:
                self.__UDPSock.bind(("0.0.0.0", 50000 + i))
            except socket.error as msg:
                if msg.errno == 98:
                    # Bind port already in use, loop to next
                    continue
                raise EthernetToJTAGException(msg)
            break

        # Start in default configuration
        self.__update_configuration()
        self.__UDPSock.sendto(self.__config, (self.__ip, self.__stream_port))

        if noinit:
            return

        # Boot into TLR -> SHIFT_IR
        self.go_to_shift_ir()

        # Put in bypass for any reasonable length of chain
        # TODO: Make this a safer solution for many-chip designs
        self.jtag_clock(bytearray([TDI]) * 1002 + bytearray([TDI | TMS, TMS]))

        self.state = states.UPDATE_IR
        self.go_to_shift_dr()

        # Flush zeroes then clock ones
        self.jtag_clock(bytearray([0]) * 1000)
        result = self.jtag_clock_with_result(bytearray([TDI]) * 1000)

        # Count the number of devices
        for i in range(0, 1000):
            if int(result[i]) & TDO:
                self.__num_devices = i
                break

# Read the idcodes
        self.go_to_test_logic_reset()
        self.go_to_shift_dr()
        for i in range(0, self.__num_devices):
            self.__idcodes.append(self.read(32))

        # Reverse the device order so that it matches the order in which data is loaded
        self.__idcodes.reverse()

    def idcode_resolve_name(self, idcode):
        for i in idcodes:
            if (i[0] & i[1]) == (idcode & i[1]):
                return i[2]
        return 'UNKNOWN DEVICE'

    def idcode_resolve_irlen(self, idcode):
        for i in idcodes:
            if (i[0] & i[1]) == (idcode & i[1]):
                return i[3]
        raise EthernetToJTAGException('Unknown IRLEN for given IDCODE')

    def __update_configuration(self):

        # Sleep maximum cycle time to ensure a clean configuration change
        # clocks_per_cycle = 4 + self.__speed * 2
        # clocks_per_mtu = MTU * 8 * (4 + self.__speed * 2) + 2
        # time_per_mtu = clocks_per_mtu * 0.0000001 #0.000000005
        # time.sleep(time_per_mtu)

        # Burst size is limited to 4 in two_bit mode, 8 in tdi-only mode
        if self.__burst_size == 0:
            raise EthernetToJTAGException('Burst size of zero is not allowed')

        if self.__mode_two_bit is True:
            if self.__burst_size > 4:
                raise EthernetToJTAGException(
                    'Burst size greater than 4 is not allowed in TMS/TDI mode')
        else:
            if self.__burst_size > 8:
                raise EthernetToJTAGException(
                    'Burst size greater than 8 is not allowed in TDI-only mode')

        token = 1 << (self.__burst_size - 1)

        # Set the new configuration
        self.__config = bytearray([
            token, self.__speed, (self.__bit_in_select << 4) |
            self.__channel_enable, (self.__bit_in_phase << 4) |
            (self.__mode_write_endian << 3) | (self.__mode_read_endian << 2) |
            (self.__mode_two_bit << 1) | self.__mode_rw
        ])

        # for i in self.__config:
        #    print hex(i),
        # print

        # self.__config = str(self.__config)
        self.__config = self.__config

    def idcode(self, index):
        return self.__idcodes[index]

    def num_devices(self):
        return self.__num_devices

    def go_to_test_logic_reset(self):
        # Just clock TMS five times
        self.jtag_clock(bytearray([TMS]) * 5)
        self.state = states.TEST_LOGIC_RESET

    def go_to_shift_ir(self):
        if self.state == states.UNKNOWN:
            self.go_to_test_logic_reset()
            self.go_to_shift_ir()
        elif self.state == states.TEST_LOGIC_RESET:
            self.jtag_clock([0, TMS, TMS, 0, 0])
        elif self.state == states.RUN_TEST_IDLE:
            self.jtag_clock([TMS, TMS, 0, 0])
        elif self.state == states.SHIFT_DR:
            self.jtag_clock([TMS, TMS, TMS, TMS, 0, 0])
        elif self.state == states.UPDATE_IR:
            self.jtag_clock([TMS, TMS, 0, 0])
        elif self.state == states.UPDATE_DR:
            self.jtag_clock([TMS, TMS, 0, 0])

        self.state = states.SHIFT_IR

    def go_to_shift_dr(self):
        if self.state == states.UNKNOWN:
            self.go_to_test_logic_reset()
            self.go_to_shift_dr()
        elif self.state == states.TEST_LOGIC_RESET:
            self.jtag_clock([0, TMS, 0, 0])
        elif self.state == states.RUN_TEST_IDLE:
            self.jtag_clock([TMS, 0, 0])
        elif self.state == states.SHIFT_IR:
            self.jtag_clock([TMS, TMS, TMS, 0, 0])
        elif self.state == states.UPDATE_IR:
            self.jtag_clock([TMS, 0, 0])
        elif self.state == states.UPDATE_DR:
            self.jtag_clock([TMS, 0, 0])

        self.state = states.SHIFT_DR

    def go_to_run_test_idle(self):
        if self.state == states.UNKNOWN:
            self.go_to_test_logic_reset()
            self.go_to_run_test_idle()
        elif self.state == states.TEST_LOGIC_RESET:
            self.jtag_clock([0])
        elif self.state == states.SHIFT_IR:
            self.jtag_clock([TMS, TMS, 0])
        elif self.state == states.SHIFT_DR:
            self.jtag_clock([TMS, TMS, 0])
        elif self.state == states.UPDATE_IR:
            self.jtag_clock([0])
        elif self.state == states.UPDATE_DR:
            self.jtag_clock([0])

        self.state = states.RUN_TEST_IDLE

    def go_to_update_ir(self):
        if self.state == states.UNKNOWN:
            self.go_to_test_logic_reset()
            self.go_to_update_ir()
        elif self.state == states.TEST_LOGIC_RESET:
            self.jtag_clock([0, TMS, TMS, 0, TMS, TMS])
        elif self.state == states.RUN_TEST_IDLE:
            self.jtag_clock([TMS, TMS, 0, TMS, TMS])
        elif self.state == states.SHIFT_IR:
            self.jtag_clock([TMS, TMS])
        elif self.state == states.SHIFT_DR:
            self.jtag_clock([TMS, TMS, TMS, TMS, 0, TMS, TMS])
        elif self.state == states.UPDATE_DR:
            self.jtag_clock([TMS, TMS, 0, TMS, TMS])

        self.state = states.UPDATE_IR

    def go_to_update_dr(self):
        if self.state == states.UNKNOWN:
            self.go_to_test_logic_reset()
            self.go_to_update_dr()
        elif self.state == states.TEST_LOGIC_RESET:
            self.jtag_clock([0, TMS, 0, TMS, TMS])
        elif self.state == states.RUN_TEST_IDLE:
            self.jtag_clock([TMS, 0, TMS, TMS])
        elif self.state == states.SHIFT_IR:
            self.jtag_clock([TMS, TMS, TMS, 0, TMS, TMS])
        elif self.state == states.SHIFT_DR:
            self.jtag_clock([TMS, TMS])
        elif self.state == states.UPDATE_IR:
            self.jtag_clock([TMS, 0, TMS, TMS])

        self.state = states.UPDATE_DR

    # Just read from JTAG
    def read(self,
             num_bits,
             update_register=False,
             flush_first_character=False,
             reverse=False):
        if (self.state != states.SHIFT_IR) and (self.state != states.SHIFT_DR):
            raise EthernetToJTAGException('Invalid state for this instruction')

        if flush_first_character:
            self.jtag_clock([0])

        send = bytearray([0]) * (num_bits - 1)
        if update_register:
            send += bytearray([TMS, TMS])
            if self.state == states.SHIFT_IR:
                self.state = states.UPDATE_IR
            else:
                self.state = states.UPDATE_DR
        else:
            send += bytearray([0])

        # Send the data
        data = self.jtag_clock_with_result(send)

        result = int(0)
        if reverse:
            for i in range(0, num_bits):
                result |= (int(data[i]) & TDO) << (num_bits - 1 - i)
        else:
            for i in range(0, num_bits):
                result |= (int(data[i]) & TDO) << i

        return result

    # Just write to JTAG
    def write_bytearray(self,
                        data,
                        update_register=False,
                        endian=False,
                        flush_first_character=False):
        if (self.state != states.SHIFT_IR) and (self.state != states.SHIFT_DR):
            raise EthernetToJTAGException('Invalid state for this instruction')

        if (update_register or flush_first_character) is False:
            self.jtag_clock_burst_8(data, endian)
            return

        if flush_first_character:
            self.jtag_clock([0])

        send = bytearray()
        for i in data:
            for j in range(0, 8):
                if not (endian):
                    if i & 1:
                        send += bytearray([TDI])
                    else:
                        send += bytearray([0])
                    i = i >> 1
                else:
                    if i & 128:
                        send += bytearray([TDI])
                    else:
                        send += bytearray([0])
                    i = i << 1

        if update_register:
            send[8 * len(data) - 1] |= TMS
            send += bytearray([TMS])
            if self.state == states.SHIFT_IR:
                self.state = states.UPDATE_IR
            else:
                self.state = states.UPDATE_DR

        # Send the data
        self.jtag_clock(send)

    # Write to JTAG and read result at the same time
    def write_read_bytearray(self,
                             data,
                             update_register=False,
                             write_endian=False,
                             read_endian=False,
                             flush_first_character=False):
        if ((self.state != states.SHIFT_IR) and (self.state != states.SHIFT_DR)):
            raise EthernetToJTAGException('Invalid state for this instruction')

        if (update_register or flush_first_character) is False:
            return self.jtag_clock_with_result_burst_8(data, write_endian,
                                                       read_endian)

        if flush_first_character:
            self.jtag_clock([0])

        send = bytearray()
        for i in data:
            for j in range(0, 8):
                if not (write_endian):
                    if i & 1:
                        send += bytearray([TDI])
                    else:
                        send += bytearray([0])
                    i = i >> 1
                else:
                    if i & 128:
                        send += bytearray([TDI])
                    else:
                        send += bytearray([0])
                    i = i << 1

        if update_register:
            send[8 * len(data) - 1] |= TMS
            send += bytearray([TMS])
            if self.state == states.SHIFT_IR:
                self.state = states.UPDATE_IR
            else:
                self.state = states.UPDATE_DR

        # Send the data
        data = self.jtag_clock_with_result(send)

        result = bytearray()
        offset = 0
        val = 0
        for j in data:

            # if self.__mode_read_endian:
            #    item = int('{:08b}'.format(j)[::-1], 2)

            val |= (int(val) & TDO) << offset

            offset += 1
            if offset == 8:
                result += bytearray([val])
                offset = 0
                val = 0

        return result

    # Just write to JTAG
    def write(self,
              data,
              num_bits,
              update_register=False,
              flush_first_character=False,
              endian=False):
        if ((self.state != states.SHIFT_IR) and (self.state != states.SHIFT_DR)):
            raise EthernetToJTAGException('Invalid state for this instruction')
        if (num_bits == 0):
            return

        if flush_first_character:
            self.jtag_clock([0])

        if endian:
            data = int(('{:0' + str(num_bits) + 'b}').format(data)[::-1], 2)

        send = bytearray()
        for i in range(0, num_bits):
            if data & 1:
                send += bytearray([TDI])
            else:
                send += bytearray([0])
            data = data >> 1

        if update_register:
            send[num_bits - 1] |= TMS
            send += bytearray([TMS])
            if self.state == states.SHIFT_IR:
                self.state = states.UPDATE_IR
            else:
                self.state = states.UPDATE_DR

        # Send the data
        self.jtag_clock(send)

    # Write to JTAG and read result at the same time
    def write_read(self,
                   data,
                   num_bits,
                   update_register=False,
                   reverse=False,
                   flush_first_character=False):
        if ((self.state != states.SHIFT_IR) and (self.state != states.SHIFT_DR)):
            raise EthernetToJTAGException('Invalid state for this instruction')
        if (num_bits == 0):
            return

        if flush_first_character:
            self.jtag_clock([0])

        send = bytearray()
        for i in range(0, num_bits):
            if data & 1:
                send += bytearray([TDI])
            else:
                send += bytearray([0])
            data = data >> 1

        if update_register:
            send[num_bits - 1] |= TMS
            send += bytearray([TMS])
            if self.state == states.SHIFT_IR:
                self.state = states.UPDATE_IR
            else:
                self.state = states.UPDATE_DR

        # Send the data
        data = self.jtag_clock_with_result(send)

        result = int(0)
        if reverse:
            for i in range(0, num_bits):
                result |= (int(data[i]) & TDO) << (num_bits - 1 - i)
        else:
            for i in range(0, num_bits):
                result |= (int(data[i]) & TDO) << i

        return result

    def __format_block(self, data):

        # Burst packing is a little tricky...
        # First we get the burst count
        burst_count = len(data) // 4
        end_count = len(data) % 4

        block = bytearray()
        if burst_count:

            # Repackage the data in burst-4 blocks
            # based on whatever the current endian configuration is
            for i in range(0, burst_count):
                item = 0
                for j in range(0, 4):
                    item |= (data[(i << 2) + j] << (j << 1))

                # Flip byte if MSB-first
                if self.__mode_write_endian:
                    item = int('{:08b}'.format(item)[::-1], 2)

                block += bytearray([item])

        last = 0
        if end_count:

            # Repackage the non-burst-4 blocks
            # based on whatever the current endian configuration is
            for j in range(0, end_count):
                last |= (data[(burst_count << 2) + j] << (j << 1))

            # Flip byte if MSB-first
            if self.__mode_write_endian:
                last = int('{:08b}'.format(last)[::-1], 2)

        return [burst_count, block, end_count, last]

    def jtag_clock_burst_8(self, data, endian):
        # This command packs a clocked output
        # of bits from a single command and processes it
        # It returns the resulting packet
        if (self.__mode_two_bit is True) or (self.__burst_size != 8) or (
                self.__mode_write_endian != endian):
            self.__mode_two_bit = False
            self.__burst_size = 8
            self.__mode_write_endian = endian
            self.__update_configuration()

        self.jtag_exec(data)

    def jtag_clock_with_result_burst_8(self, data, write_endian, read_endian):
        # This command packs a clocked output
        # of bits from a single command and processes it
        # It returns the resulting packet
        if (self.__mode_two_bit is True) or (self.__burst_size != 8) or (
                self.__mode_write_endian != write_endian) or (
                    self.__mode_read_endian != read_endian):
            self.__mode_two_bit = False
            self.__burst_size = 8
            self.__mode_write_endian = write_endian
            self.__mode_read_endian = read_endian
            self.__update_configuration()

        result = self.jtag_exec_with_result(data)

        if (self.__mode_read_endian):
            self.__mode_read_endian = False
            self.__update_configuration()

        return result

    def jtag_clock(self, data):
        # This command packs a clocked output
        # of bits from a single command and processes it
        # It returns the resulting packet
        if self.__mode_two_bit is False:
            self.__burst_size = 4
            self.__mode_two_bit = True
            self.__update_configuration()

        frame = self.__format_block(data)

        if frame[0]:

            # Enter burst mode
            if self.__burst_size != 4:
                self.__burst_size = 4
                self.__update_configuration()

            self.jtag_exec(frame[1])

        if frame[2]:

            if self.__burst_size != frame[2]:
                self.__burst_size = frame[2]
                self.__update_configuration()

            self.jtag_exec(bytearray([frame[3]]))

    def jtag_clock_with_result(self, data):
        if self.__mode_two_bit is False:
            self.__burst_size = 4
            self.__mode_two_bit = True
            self.__update_configuration()

        frame = self.__format_block(data)

        result = bytearray()
        if frame[0]:

            # Enter burst mode
            if self.__burst_size != 4:
                self.__burst_size = 4
                self.__update_configuration()

            unsorted_result = self.jtag_exec_with_result(frame[1])

            result = bytearray()
            for i in unsorted_result:

                # Flip the word if we're in the opposite endian
                if self.__mode_read_endian:
                    i = int('{:08b}'.format(i)[::-1], 2)

                for j in range(0, 4):
                    result += bytearray([(i >> (7 - (3 - j))) & 0x1])

        if frame[2]:

            if self.__burst_size != frame[2]:
                self.__burst_size = frame[2]
                self.__update_configuration()

            i = self.jtag_exec_with_result(bytearray([frame[3]]))[0]

            if self.__mode_read_endian:
                i = int('{:08b}'.format(i)[::-1], 2)

            for j in range(0, frame[2]):
                result += bytearray([(i >> (7 - (frame[2] - 1 - j))) & 0x1])

        return result

    def jtag_exec_with_result(self, data):
        if self.__mode_rw is False:
            self.__mode_rw = True
            self.__update_configuration()

        # TDI updates on rising edge of TCK
        # TDO updates on falling edge of TCK

        # print 'S:',
        # for i in data:
        #    print hex(i),
        # print 'burst:', self.__burst_size

        data = bytearray(data)

        # Loop through by MTU size
        i = 0
        substring = data[i:i + MTU]
        return_string = b''

        # self.__pre_send_time = time.time()
        # print 'proc:',self.__pre_send_time - self.__post_send_time,

        # print 'Exec with result'

        while len(substring):

            # Send the data and receive the output
            self.__UDPSock.sendto(self.__config + substring,
                                  (self.__ip, self.__stream_port))
            data2 = self.__UDPSock.recv(len(substring))
            if not data2:
                raise EthernetToJTAGException('No data received')

            bytes2 = bytearray(data2)
            if (len(bytes2) != len(substring)):
                raise EthernetToJTAGException('Incorrect data volume received')

            i = i + MTU
            substring = data[i:i + MTU]
            return_string += data2

        # self.__post_send_time = time.time()
        # print 'send:',self.__post_send_time - self.__pre_send_time

        # print 'R:',
        # for i in bytearray(return_string):
        #    print hex(i),
        # print

        return bytearray(return_string)

    def jtag_exec(self, data):
        # self.jtag_exec_with_result(data)
        # return

        if self.__mode_rw is True:
            self.__mode_rw = False
            self.__update_configuration()

        # TDI updates on rising edge of TCK
        # TDO updates on falling edge of TCK

        # print 'S:',
        # for i in bytearray(data):
        #    print hex(i),
        # print 'burst:', self.__burst_size

        # print 'Exec without result'

        data = bytearray(data)

        # Loop through by MTU size
        i = 0
        substring = data[i:i + MTU]

        # Interface shifts one cycle every two of 50MHz at best
        # Therefore theoretical maximum speed is 25MHz
        max_cycles_per_mtu = MTU * self.__burst_size

        if self.__speed == 0:
            clocks_per_cycle = 2 + self.__speed * 2
        else:
            clocks_per_cycle = 2 + (self.__speed + 1) * 2

        clocks_per_mtu = max_cycles_per_mtu * clocks_per_cycle + 10 + (
            self.__speed + 1)
        time_per_mtu = clocks_per_mtu * 0.00000002  # 50MHz
        time_per_mtu += TIME_PER_MTU_OFFSET
        # print clocks_per_mtu, time_per_mtu

        # self.__pre_send_time = time.time()
        # print 'proc:',self.__pre_send_time - self.__post_send_time,

        # print len(self.__config)

        while len(substring):

            # Send the data and receive the output
            self.__UDPSock.sendto(self.__config + substring,
                                  (self.__ip, self.__stream_port))

            # Wait state to avoid overloading the JTAG interface
            # when we're sending UDP packets

            time.sleep(time_per_mtu)

            # data2 = self.__UDPSock.recv(len(substring))
            # if not data2:
            #    raise "No data received"

            i = i + MTU
            substring = data[i:i + MTU]

        # self.__post_send_time = time.time()
        # print 'send:',self.__post_send_time - self.__pre_send_time
