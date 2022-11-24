import sys
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
sys.path.append(bedrock_dir + "badger")
import lbus_access
from testcase import acquire_vcd


def grab_vcd(dev, capture):
    dev.exchange([327687], values=[12])  # trig_run=1 trig_mode=1
    acquire_vcd(dev, capture, timeout=10000)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Capture vcd file from Marble")
    parser.add_argument('--ip', default='192.168.19.10', help='IP address')
    parser.add_argument('--udp', type=int, default=0, help='UDP Port number')
    parser.add_argument('--vcd', type=str, help='VCD file to capture')

    args = parser.parse_args()
    ip = args.ip
    udp = args.udp
    if args.udp == 0:
        udp = 803
    dev = lbus_access.lbus_access(ip, port=udp, timeout=3.0, allow_burst=False)
    grab_vcd(dev, args.vcd)
