from time import sleep
import sys
sys.path.append("bedrock/peripheral_drivers/i2cbridge")
sys.path.append("bedrock/badger")
import lbus_access
from c2vcd import produce_vcd


class i2c_live:
    def __init__(self, host, timeout=1.02, port=803,
                 retry=120, sim=False, i2c_base=0x040000,
                 force_burst=False, allow_burst=True):
        self.dev = lbus_access.lbus_access(
            host, port=port, timeout=timeout,
            force_burst=force_burst, allow_burst=allow_burst)
        self.sim = sim
        self.retry = retry
        self.i2c_base = i2c_base

    def read_result(self, result_len=20, running=True):
        run_flag = 2 if running else 0
        addr = range(self.i2c_base+0x800, self.i2c_base+0x800+result_len)
        if result_len < 125:  # combine into one packet
            ll = len(addr)
            push_addr = [327687] + list(addr) + [327687]
            push_vals = [run_flag + 1] + [None]*ll + [run_flag]
            raw_read = self.dev.exchange(push_addr, push_vals)
            readout = raw_read[1:-1]
        else:  # allow burst mode for data
            # freeze result buffer, and keep running
            self.dev.exchange([327687], values=[run_flag + 1])
            # read out "results"
            readout = self.dev.exchange(addr)
            # thaw result buffer, still keep running
            self.dev.exchange([327687], values=[run_flag])
        return readout

    def wait_for_stat(self, checker, verbose=True):
        for ix in range(self.retry):
            updated = self.dev.exchange([9])
            # print("%d updated? %d" % (ix, updated))
            if checker(updated):
                if verbose:
                    sys.stdout.write("OK\n")
                break
            else:
                if verbose:
                    sys.stdout.write(".")
                    sys.stdout.flush()
            if self.sim:
                self.dev.exchange(125*[0])  # twiddle our thumbs for 1000 clock cycles
            else:
                sleep(0.01)

    def wait_for_done(self, verbose=True):
        self.wait_for_stat(lambda x: (x & 1) == 1, verbose=verbose)

    def wait_for_stop(self, verbose=True):
        self.wait_for_stat(lambda x: (x & 4) == 0, verbose=verbose)

    def run_testcase(self, prog, result_len=20, capture=None, stop=False):
        self.dev.exchange([327687], values=[0])  # run_cmd=0
        self.wait_for_stop()
        # Upload program to i2c_chunk dpram
        addr = range(self.i2c_base, self.i2c_base+len(prog))
        self.dev.exchange(addr, values=prog)
        self.dev.exchange([327687], values=[2])  # run_cmd=1
        self.wait_for_new()
        readout = self.read_result(result_len=result_len)
        if stop:
            self.dev.exchange([327687], values=[0])  # run_cmd=0
        # read out "logic analyzer" data
        if capture is not None:
            addr = range(self.i2c_base+0x400, self.i2c_base+0x400+1024)
            logic = self.dev.exchange(addr)
        if stop:
            self.wait_for_stop()
        if self.sim:
            # stop simulation
            self.dev.exchange([327686], values=[1])
        if capture is not None:
            # corresponds to hard-coded 6, 2 in i2c_chunk_tb.v
            mtime = 1 << 6
            dw = 2
            with open(capture, "w") as ofile:
                produce_vcd(ofile, logic, dw=dw, mtime=mtime, t_step=8)
        return readout


def i2c_live_pre_args(parser):
    parser.add_argument('--ip', default='192.168.19.10', help='IP address')
    parser.add_argument('--udp', type=int, default=0, help='UDP Port number')
    parser.add_argument('--sim', action='store_true', help='simulation context')
    parser.add_argument('--stop', action='store_true', help='stop after run')
    parser.add_argument('--vcd', type=str, help='VCD file to capture')


def i2c_live_post_args(args):
    ip = args.ip
    udp = args.udp
    if args.sim:
        ip = 'localhost'
        if args.udp == 0:
            udp = 8030
    else:
        if args.udp == 0:
            udp = 803

    # OK, setup is finished, start the actual work
    dev = i2c_live(ip, port=udp, allow_burst=False)
    return dev
