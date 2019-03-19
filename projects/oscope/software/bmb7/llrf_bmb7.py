import sys

from os.path import isfile
from bmb7.r1 import bmb7_spartan

# sys.path.append(os.path.join(os.path.dirname(__file__), "../../firmware/submodules/build"))
# sys.path.append(os.path.join(os.path.dirname(__file__), "../submodules/qf2_pre"))

from read_regmap import get_map, get_reg_info, get_write_address, get_read_address
from build_rom import read_live_array, decode_array


from bmb7.mem_gateway import c_mem_gateway

import struct


class c_llrf_bmb7():

    def __init__(self, ip, port, regmappath='./live_prc_regmap.json',
                 bitfilepath=None, reset=False, clk_freq=1320e6/14.0,
                 use_spartan=False, filewritepath=None):
        print(ip)
        self.ip = ip
        # Postpone .json file reads until after the bitfile is loaded
        self.cirbuf_aw = 13
        self.mg = c_mem_gateway(ip, port)

        self.clk_freq = clk_freq
        self.dt = 1.0 / self.clk_freq

        self.bitfilepath = bitfilepath
        self.regmappath = regmappath
        if bitfilepath is not None:
            use_spartan = True

        self.use_spartan = use_spartan
        # carrier_rev = 1 is default,
        # rev = 1 -> QF2-pre with latest firmware
        # rev = 2 -> BMB7 1.0
        self.carrier_rev = 1

        # Default: BMB7 r1.0 fall-back logic below
        self.wrong_board = False

        if self.use_spartan:  # can force backward compatibility with old Spartan bitfile
            try:
                import qf2_python.identifier
                from .qf2 import c_qf2
                self.spartan_interface = qf2_python.identifier.get_active_interface(self.ip, False)
                self.carrier = c_qf2(ip, reset)
                print("Found a QF2_pre board")
            except Exception as e:
                print(e)
                self.wrong_board = True
            if self.wrong_board:
                # Tested OK on original BMB7
                from bmb7.configuration.bmb7 import c_bmb7
                print("Attempting r1.0 (BMB7) fallback")
                try:
                    self.spartan_interface = bmb7_spartan.interface(self.ip)
                except Exception as e:
                    print(e)
                    exit(2)
                self.carrier_rev = 1
                self.carrier = c_bmb7(ip, reset)
            self.fmc_prom_address = 0x50
        else:
            self.spartan_interface = None
        self.test_mode_now = None

        self.bitfilepath = bitfilepath

        if filewritepath:
            # Make sure path has terminating '/'
            if not filewritepath.endswith('/'):
                filewritepath = filewritepath + '/'
            regmappath = filewritepath + regmappath
        self.regmappath = regmappath
        # print("Write to " + self.regmappath)

        if reset:
            self.reset()
        else:
            if self.bitfilepath:
                if (self.carrier_rev == 2) != ('sesqui' in bitfilepath):
                    print("Bitfile name interlock failed")
                    exit(2)
                print('Trying to program')
                self.carrier.program_kintex_7(bitfilepath=bitfilepath)
            self.json_map_handle(regmappath)

    def reset(self):

        print('Starting reset')

        if self.bitfilepath:
            if (self.carrier_rev == 2) != ('sesqui' in self.bitfilepath):
                print("Bitfile name interlock failed")
                exit(2)
            print('Trying to program')
            self.carrier.program_kintex_7(bitfilepath=self.bitfilepath)
        self.json_map_handle(self.regmappath, refresh=True)

        sys.stdout.flush()

    def json_map_handle(self, regmappath, refresh=False):
        if refresh or not isfile(regmappath):
            a = read_live_array(self)
            r = decode_array(a)
            print(("Bitfile lists git commit " + r[1]))
            print(("Attempting write of live json to " + regmappath))
            with open(regmappath, 'wb') as f:
                f.write(r[3])
        self.regmap = get_map(regmappath)

        # Look for addresses in hex (encoded in JSON as string values) and convert to int
        for key in self.regmap:
            try:
                if isinstance(self.regmap[key]['base_addr'], str):
                    self.regmap[key]['base_addr'] = int(self.regmap[key]['base_addr'], 0)
            except Exception:
                pass

        # Setting the old regmaps to null; Forcing an error on access
        # TODO: Clean up the deprecated codepath that reads from prc_regmap.json
        self.write_regmap = {}
        self.read_regmap = {}

    def reg_read(self, name_list, hierarchy=[]):
        alist = []
        for name in name_list:
            x = get_reg_info(self.regmap, hierarchy, name)
            if x is not None:
                addr = x['base_addr']
            elif name in self.read_regmap:
                addr = self.read_regmap[name]
            elif name in list(self.read_regmap.values()):
                addr = name
            else:
                print(('unknown register:' + name + 'skipped'))
                addr = None
            if addr:
                alist.append(addr)
        return self.reg_read_alist(alist)

    def reg_read_value(self, name_list):
        val = self.reg_read(name_list)
        result = [struct.unpack('!I', r[2])[0] for r in val]
        return result

    def reg_read_alist(self, alist):
        result = []
        while len(alist) > 128:
            result.extend(self.mg_read(alist[0:128]))
            alist = alist[128:]
        if alist:
            result.extend(self.mg_read(alist))
        return result

    def get_write_address(self, name, hierarchy=[]):
        return get_write_address(name, self.regmap, hierarchy)

    def get_read_address(self, name, hierarchy=[]):
        return get_read_address(name, self.regmap, hierarchy)

    def reg_write(self, name_value_dict_list):
        alist = []
        dlist = []
        for name_value_dict in name_value_dict_list:
            for name, value in list(name_value_dict.items()):
                x = self.get_write_address(name)
                alist.append(x)
                dlist.append(value)
        while len(alist) > 128:
            self.mg_write(alist[0:128], dlist[0:128])
            alist = alist[128:]
            dlist = dlist[128:]
        if alist:
            self.mg_write(alist, dlist)

    def buf_read_raw(self, addr, count=None, debug=None):
        if not count:
            count = 2**self.cirbuf_aw
        waveaddr = {1: 0x16, 2: 0x17}
        if addr in waveaddr:
            addr = waveaddr[addr]
        if addr in self.read_regmap:
            addr = self.read_regmap[addr]
        alist = count*[addr]
        result = self.reg_read(alist)
        return [r[2] for r in result]

    def buf_read(self, addr, count=None, debug=None):
        result = self.buf_read_raw(addr, count, debug)
        r1 = [struct.unpack('!i', r)[0] for r in result]
        if debug:
            print((debug + [r[2].encode('hex') for r in result]))
        # print 'buf_read', [r[2].encode('hex') for r in result[0:10]], r1[0:10]
        return r1

    def buf_skip_read(self, addr, count=None, debug=None):
        print(('skipped' + self.buf_read(addr, count, debug)[0:10]))
        print(('skipped' + self.buf_read(addr, count, debug)[0:10]))
        return self.buf_read(addr, count, debug)

    def mg_read(self, alist):
        # print 'mg_read', alist
        result = self.mg.readwrite(alist=alist, write=0)
        return self.mg.parse_readvalue(result)

    def mg_write(self, alist, dlist):
        # print 'mg_write', alist, dlist
        result = self.mg.readwrite(alist=alist, dlist=dlist, write=1)
        return self.mg.parse_readvalue(result)

    # compatibility routine with what I (LRD) want mem_gateway to turn into
    def query_resp_list(self, list_in):
        adwlist = [([self.get_write_address(x[0]), x[1], 1] if isinstance(x, tuple) else
                    [self.get_read_address(x), 0, 0]) for x in list_in]
        if 0:
            print(adwlist)
        pack_in = self.mg.readwrite(adwlist=adwlist)
        ll = len(pack_in)//4 * 4
        pack_in = pack_in[0:ll]
        if 0:
            print(("result packet len %d: %s" % (len(pack_in), pack_in.encode('hex'))))
        list1 = struct.unpack('!'+'I'*(len(pack_in)//4), pack_in)
        # list comprehension with predicate
        r = [list1[2*ix+3] for ix in range(len(list_in)) if not isinstance(list_in[ix], tuple)]
        return r

    def slow_chain_unpack(self, readlist):
        words = [struct.unpack('!i', a[2])[0] for a in readlist]
        nums = [256*words[ix]+words[ix+1] for ix in range(0, 32, 2)]
        nums = [x if x < 32768 else x-65536 for x in nums]
        timestamp = 0
        for ix in range(8):
            timestamp = timestamp*256 + words[41-ix]
        timestamp = timestamp/32  # integer number of 1320/14 MHz adc_clk cycles
        # ignore old_tag and new_tag for now
        return (timestamp, nums)  # nums is 16-long list of minmax values

    def slow_chain_readout(self):
        slow_addr = self.get_read_address('slow_chain_out')
        readlist = self.reg_read_alist(42*[slow_addr])
        return self.slow_chain_unpack(readlist)
