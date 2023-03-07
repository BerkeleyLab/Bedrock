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
    parser.add_argument('-a', '--addr', default='192.168.19.10', help='IP address')
    parser.add_argument('-p', '--port', type=int, default=0, help='Port number')
    parser.add_argument('-V', '--vcd', type=str, help='VCD file to capture')

    args = parser.parse_args()
    addr = args.addr
    port = args.port
    if args.port == 0:
        port = 803
    dev = lbus_access.lbus_access(addr, port=port, timeout=3.0, allow_burst=False)
    grab_vcd(dev, args.vcd)
