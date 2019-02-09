#!/bin/env python

import select, socket, string, sys, time
from configuration.jtag import *

# Initialise the chain control
chain = jtag.chain(ip=sys.argv[1], stream_port=50005, input_select=1, speed=0)

print 'There are', chain.num_devices(), 'devices in the chain:'

print
for i in range(0, chain.num_devices()):
    print hex(chain.idcode(i))+' - '+chain.idcode_resolve_name(chain.idcode(i))
print

chain.go_to_run_test_idle()
jtag_state = jtag.states.RUN_TEST_IDLE

def jtag_step(s, tms):

    states = {

        jtag.states.TEST_LOGIC_RESET : [jtag.states.RUN_TEST_IDLE, jtag.states.TEST_LOGIC_RESET],
        jtag.states.RUN_TEST_IDLE : [jtag.states.RUN_TEST_IDLE, jtag.states.SELECT_DR_SCAN],

        jtag.states.SELECT_DR_SCAN : [jtag.states.CAPTURE_DR, jtag.states.SELECT_IR_SCAN],
        jtag.states.CAPTURE_DR : [jtag.states.SHIFT_DR, jtag.states.EXIT_1_DR],
        jtag.states.SHIFT_DR : [jtag.states.SHIFT_DR, jtag.states.EXIT_1_DR],
        jtag.states.EXIT_1_DR : [jtag.states.PAUSE_DR, jtag.states.UPDATE_DR],
        jtag.states.PAUSE_DR : [jtag.states.PAUSE_DR, jtag.states.EXIT_2_DR],
        jtag.states.EXIT_2_DR : [jtag.states.SHIFT_DR, jtag.states.UPDATE_DR],
        jtag.states.UPDATE_DR : [jtag.states.RUN_TEST_IDLE, jtag.states.SELECT_DR_SCAN],

        jtag.states.SELECT_IR_SCAN : [jtag.states.CAPTURE_IR, jtag.states.TEST_LOGIC_RESET],
        jtag.states.CAPTURE_IR : [jtag.states.SHIFT_IR, jtag.states.EXIT_1_IR],
        jtag.states.SHIFT_IR : [jtag.states.SHIFT_IR, jtag.states.EXIT_1_IR],
        jtag.states.EXIT_1_IR : [jtag.states.PAUSE_IR, jtag.states.UPDATE_IR],
        jtag.states.PAUSE_IR : [jtag.states.PAUSE_IR, jtag.states.EXIT_2_IR],
        jtag.states.EXIT_2_IR : [jtag.states.SHIFT_IR, jtag.states.UPDATE_IR],
        jtag.states.UPDATE_IR : [jtag.states.RUN_TEST_IDLE, jtag.states.SELECT_DR_SCAN]

        }

    return states[s][tms]

def handle_data(c):
    global jtag_state
    seen_tlr = False

    while True:
        data = c.recv(2)
        if len(data) == 0:
            return False

        if data == 'ge':
            data = c.recv(6)
            if len(data) == 0:
                return False
            if len(data) != 6:
                return False
            if data != 'tinfo:':
                return False
            #c.send('xvcServer_v1.0:'+str(16536)+'\n')
            #reply = bytearray(4)
            #resp = 128
            #reply[3] = (resp & 0xFF)
            #reply[2] = (resp >> 8) & 0xFF
            #reply[1] = (resp >> 16) & 0xFF
            #reply[0] = (resp >> 24) & 0xFF
            c.send('xvcServer_v1.0:200000000\n')
            print 'Received getinfo:'
            return True
        elif data == 'se':
            data = c.recv(9)
            if len(data) == 0:
                return False
            if len(data) != 9:
                return False
            if data[0:5] != 'ttck:':
                return False
            v = bytearray(data)
            print 'Received settck:', int(v[8]) * 16777216 + int(v[7]) * 65536 + int(v[6]) * 256 + int(v[5])
            reply = bytearray(4)
            for i in range(0, 4):
                reply[i] = v[5+i]
            c.send(str(reply))
            return True
        elif data != 'sh':
            raise Exception('Unrecognised command received')


        data = c.recv(8)

        if len(data) == 0:
            return False
        if len(data) != 8:
            return False
        if data[0:4] != 'ift:':
            return False

        # TODO Endian check?
        num_bits = bytearray([data[4]])[0] + bytearray([data[5]])[0] * 256 + bytearray([data[6]])[0] * 65536 + bytearray([data[7]])[0] * 16777216

        num_bytes = (num_bits + 7) / 8
        #print num_bits, num_bytes

        # Multiply by 2 for TMS & TDI
        amount = num_bytes * 2

        data = str()

        while amount != 0:
            data += c.recv(amount)
            amount -= len(data)

        data = bytearray(data)
        #for i in data:
        #    print hex(i),
        #print

        # Only allow exiting the loop if the state is RTI and the IR has IDCODE by going through test_logic_reset
        seen_tlr = (seen_tlr or (jtag_state == jtag.states.TEST_LOGIC_RESET)) and (jtag_state != jtag.states.CAPTURE_DR) and (jtag_state != jtag.states.CAPTURE_IR)

        # Apparently Impact can go through capture after reading IR/DR which triggers IR to read out an IR value, ignore these...
        if ( ((jtag_state == jtag.states.EXIT_1_IR) and (num_bits == 5) and (data[0] == 0x17)) or
             ((jtag_state == jtag.states.EXIT_1_DR) and (num_bits == 4) and (data[0] == 0x0b)) ):

            print 'Ignoring bogus JTAG state movement'

        else:

            #print 'S:',

            send = bytearray()
            reply = bytearray([0] * num_bytes)
            for i in range(0, num_bits):
                x = 0

                # TMS
                if (data[i/8] & (1<<(i&7))) != 0:
                    jtag_state = jtag_step(jtag_state, 1)
                    x = jtag.TMS
                else:
                    jtag_state = jtag_step(jtag_state, 0)

                # TDI
                if (data[num_bytes + i/8] & (1<<(i&7))) != 0:
                    x |= jtag.TDI

                # Append the TMS \ TDI state to the array
                send += bytearray([x])

                #if x & jtag.TMS:
                #    print 'TMS',
                #if x & jtag.TDI:
                #    print 'TDI',
                #print '|',

            #print

            # Invoke the JTAG chain directly
            result = chain.jtag_clock_with_result(send)

            #print 'R:',

            # Send the response back via TCP
            for i in range(0, num_bits):

                #if int(result[i]) & jtag.TDO:
                #    print 'TDO |',

                reply[i/8] |= (int(result[i]) & jtag.TDO) << (i&7)

            #print
            print '.',# num_bits
            sys.stdout.flush()

            # Send the reply
            c.send(str(reply))

        #print jtag.state_names[jtag_state]

        if ( seen_tlr and (jtag_state == jtag.states.RUN_TEST_IDLE) ):
            break

    return True

# Create socket listener for TCP daemon

ListenerSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
ListenerSocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
ListenerSocket.bind(("127.0.0.1", 2542))
ListenerSocket.listen(0)

ConnectionSocket = None

# Listen / connection loop
# TODO - improve error handling

while True:
    inputs = [ ListenerSocket ]
    outputs = [ ]
    if ConnectionSocket != None:
        inputs.append(ConnectionSocket)

    # Wait for data, new connection or error
    readable, writable, exceptional = select.select(inputs, outputs, inputs)

    for s in readable:
        if s == ListenerSocket:

            # Drop a previous connection
            if ConnectionSocket != None:
                ConnectionSocket.close()
                ConnectionSocket = None

            ConnectionSocket, client_address = s.accept()
            print 'New connection from', client_address

            # Make sure we don't serve anything left from the previous connection
            break

        elif not(handle_data(ConnectionSocket)):

            # Message for connected socket
            ConnectionSocket.close()
            ConnectionSocket = None

            print 'Connection closed'

    for s in exceptional:
        if s == ListenerSocket:

            print 'Exception on listener socket'
            s.close()
            exit()

        else:

            print 'Exception on connection socket'
            ConnectionSocket.close()
            ConnectionSocket = None

