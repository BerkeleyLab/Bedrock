#!/usr/bin/env python

from configuration.jtag import jtag, xilinx_bitfile_parser, xilinx_virtex_5
from configuration.jtag import xilinx_spartan_6, xilinx_kintex_7, xilinx_virtex_7


def program(ip, bitfilepath, device_choices=None):
    # Initialise the chain control
    chain = jtag.chain(ip=ip, stream_port=50005, input_select=1, speed=0)
    print(('There are {} devices in the chain:'.format(chain.num_devices())))
    print()
    for i in range(0, chain.num_devices()):
        print((hex(chain.idcode(i)) + ' - ' + chain.idcode_resolve_name(
		chain.idcode(i))))
    print()

    # Parse the bitfile and resolve the part type
    print(('Loading bitfile:', bitfilepath))
    bitfile = xilinx_bitfile_parser.bitfile(bitfilepath)

    print(('Design name:', bitfile.design_name()))
    print(('Device name:', bitfile.device_name()))
    print(('Build date:', bitfile.build_date()))
    print(('Build time:', bitfile.build_time()))
    print(('Length:', bitfile.length(), 'bits'))

    print()

    matching_devices = list()
    for i in range(0, chain.num_devices()):
        if bitfile.match_idcode(chain.idcode(i)):
            matching_devices.append(i)

    if len(matching_devices) == 0:
        print('No devices matching bitfile found in JTAG chain')
        exit()

# Default to first (and only) entry
    device_choice = matching_devices[0]

    # Override choice from argument line if there's more than one device
    if len(matching_devices) > 1:
        if not device_choices:
            print('More than one matching FPGA in device chain - you must add a chain ID to the arguments')
            exit()

        choice_made = False
        for i in matching_devices:
            if i == int(device_choices):
                device_choice = i
                choice_made = True

        if choice_made == False:
            print('No matching device selection found that corresponds to JTAG chain')
            exit()
    else:
        print('Defaulting device selection in chain from IDCODE')

    print(('Device selected for programming is in chain location:', str(
        device_choice)))

    if str('Xilinx Virtex 5') in chain.idcode_resolve_name(
            chain.idcode(device_choice)):
        print('Xilinx Virtex 5 interface selected')
        interface = xilinx_virtex_5.interface(chain)
    elif str('Xilinx Spartan 6') in chain.idcode_resolve_name(
            chain.idcode(device_choice)):
        print('Xilinx Spartan 6 interface selected')
        interface = xilinx_spartan_6.interface(chain)
    elif str('Xilinx Kintex 7') in chain.idcode_resolve_name(
            chain.idcode(device_choice)):
        print('Xilinx Kintex 7 interface selected')
        interface = xilinx_kintex_7.interface(chain)
    elif str('Xilinx Virtex 7') in chain.idcode_resolve_name(
            chain.idcode(device_choice)):
        print('Xilinx Virtex 7 interface selected')
        interface = xilinx_virtex_7.interface(chain)
    else:
        print('Not able to program this device')
        exit()

    print('Programming...')
    print()

    # Load the bitfile
    interface.program(bitfile.data(), device_choice)
if __name__ == "__main__":
    ip = "192.168.21.11"
    bitfilepath = "../prc.bit"
    device_choice = None
    if (len(sys.argv) > 1):
        ip = sys.argv[1]
    if (len(sys.argv) > 2):
        bitfilepath = sys.argv[2]
    if (len(sys.argv) > 3):
        device_choice = sys.argv[3]

    program(ip=ip, bitfilepath=bitfilepath, device_choices=None)
