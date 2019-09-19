import codecs
import getopt
import re
import struct
import sys
import time

from bmb7.llrf_bmb7 import c_llrf_bmb7
from llspi_lmk01801 import c_llspi_lmk01801
from llspi_ad9653 import c_llspi_ad9653
from llspi_ad9781 import c_llspi_ad9781
from ad7794 import c_ad7794
from amc7823 import c_amc7823
from prnd import prnd
from onewire import onewire_status


class c_prc(c_llrf_bmb7):
    def __init__(self,
                 ip,
                 port=50006,
                 regmappath='./live_prc_regmap.json',
                 bitfilepath=None,
                 reset=False,
                 clk_freq=1320e6 / 14.0,
                 use_spartan=False,
                 filewritepath=None):

        self.pn9 = prnd(0x92, 16)  # static class variable

        self.ip = ip
        self.lmk_spi = c_llspi_lmk01801(1)
        self.U2_adc_spi = c_llspi_ad9653(2)
        self.U3_adc_spi = c_llspi_ad9653(3)
        self.dac_spi = c_llspi_ad9781(4)
        self.ad7794 = c_ad7794()
        self.amc7823 = c_amc7823()

        # Used in top2idelay; makes things (more?) specific to
        # AD9653 test mode 00001100, but it seems needed for reliability.
        self.valid_pattern = [{
            0x43: 1, 0x0d: 1, 0x34: 1, 0xd0: 1
        }, {
            0x39: 1, 0xe4: 1, 0x93: 1, 0x4e: 1
        }]
        self.channels = {
            0: 'U3DA', 1: 'U3DB', 2: 'U3DC', 3: 'U3DD',
            4: 'U2DA', 5: 'U2DB', 6: 'U2DC', 7: 'U2DD'
        }
        self.chan_list = [self.channels[ix] for ix in range(8)]
        self.ad9653_regname = {  # XXX please move this to a class!
            0x00: 'SPI port configuration',
            0x01: 'Chip ID',
            0x02: 'Chip Grade',
            0x05: 'Device Index',
            0x08: 'Power Modes (global)',
            0x09: 'Clock (global)',
            0x0b: 'Clock divide (global)',
            0x0c: 'Enhancement control',
            0x0d: 'Test mode',
            0x10: 'Offset adjust (local)',
            0x14: 'Output mode',
            0x15: 'Output adjust',
            0x16: 'Output phase',
            0x18: 'V_REF',
            0x19: 'USER_PATT1_LSB (global)',
            0x1a: 'USER_PATT1_MSB (global)',
            0x1b: 'USER_PATT2_LSB (global)',
            0x1c: 'USER_PATT2_MSB (global)',
            0x21: 'Serial output data control (global)',
            0x22: 'Serial channel status (local)',
            0x100: 'Sample rate override',
            0x101: 'User I/O Control 2',
            0x102: 'User I/O Control 3',
            0x109: 'Sync'
        }

        c_llrf_bmb7.__init__(
            self,
            ip,
            port,
            regmappath=regmappath,
            bitfilepath=bitfilepath,
            reset=reset,
            clk_freq=clk_freq,
            use_spartan=use_spartan,
            filewritepath=filewritepath)

        # if self.spartan_interface:
        #     if not self.sn_init():
        #         print("ERROR: Couldn't find serial number")
        #         exit(2)
        # else:
        #     print("Digitizer serial number read disabled")
        #     self.sn = "Unknown"

    def reset(self):
        print('Starting reset')

        if self.bitfilepath:
            if (self.carrier_rev == 2) != ('sesqui' in bitfilepath):
                print("Bitfile name interlock failed")
                exit(2)
            print('Trying to program')
            self.carrier.program_kintex_7(bitfilepath=bitfilepath)
        self.json_map_handle(self.regmappath, refresh=True)
        if not self.hardware_reset():
            print("Initialization Error!")
            exit(2)
        sys.stdout.flush()

    def hardware_reset(self):
        print("Entering hardware_reset")
        self.digitizer_spi_init()

        if not self.amc7823_print(check_channels=[7]):
            print("amc7823_print failed")
            return False
        if not self.adc_reset_clk():
            print("adc_reset_clk failed")
            return False
        if not self.adc_idelay1(0):
            print("adc_idelay1 failed")
            return False
        # self.adc_idelay0()
        sys.stdout.flush()
        if not self.adc_bufr_reset():
            return False
        self.adc_bitslip()
        # self.dac_smp(SET=None, HLD=None, SMP=None)
        # self.dac_smp(SET=15, HLD=4, SMP=4)
        if False:
            if self.pntest2() == []:
                self.pntest()
        else:
            if not self.pntest4():
                return False
        self.adc_twos_comp(twoscomp=True)
        print('test pattern %s' % self.set_test_mode('00000000'))
        if not self.amc7823_print(check_channels=[4, 5, 6, 7]):
            return False
        return True

    def sn_init(self):
        if self.use_spartan:
            snread = self.sn_read()
            if snread is False:
                print("sn_read() failed")
                return False
            print('Read SN: "%s"' % snread)
            self.sn = snread
            m = re.match(r'LBNL DIGITIZER V1.\d SN +(\d+)', snread)
            if not m:
                try:
                    if True:
                        import qrtools
                        a = qrtools.QR()
                        a.decode_webcam()
                        adata = a.data
                    else:
                        # Emergency use only
                        adata = 'LBNL DIGITIZER V1.0 SN 006'
                    print('Writing new SN: "%s"' % adata)
                    self.sn_write(adata)
                except Exception:
                    pass
                    print("Error: Failed to get QR code or write to EEPROM")
                    return False
        return True

    def read_buffer_to_end(self, chan):
        waveforms_available_location = {
            'U3DA_buf': 0x10,
            'U3DB_buf': 0x20,
            'U3DC_buf': 0x40,
            'U3DD_buf': 0x80,
            'U2DA_buf': 0x100,
            'U2DB_buf': 0x200,
            'U2DC_buf': 0x400,
            'U2DD_buf': 0x800,
            "wave0_out": 0x1,
            "wave1_out": 0x2,
            "adc_test_wave1_out": 0x4,
            "adc_test_wave2_out": 0x8
        }
        avail = self.reg_read_value(['waveforms_available'])[0] & waveforms_available_location[chan]
        index = 0
        while avail and index <= 2 * 2**self.cirbuf_aw + 1:
            index = index + 128
            print(" ".join([hex(i) for i in self.reg_read_value(128 * [chan])]))
            avail = self.reg_read_value(['waveforms_available'])[0] & waveforms_available_location[chan]
        return index <= 2**(self.cirbuf_aw + 1)

    def dac_out(self, dac_0_sel=0, dac_1_sel=0, amplitude=0, freq=145.0, verbose=False):
        fclk = 1320.0/7
        modulo = 136  # magic for LCLS-II
        ddsa_phstep_h = int(freq*1.0/fclk*2**20+0.5)
        ddsa_phstep_l = 1560
        vlist = [("amplitude", amplitude), ("ddsa_modulo", modulo),
                 ("ddsa_phstep_h", ddsa_phstep_h), ("ddsa_phstep_l", ddsa_phstep_l),
                 ("dac_0_sel", dac_0_sel), ("dac_1_sel", dac_1_sel)]
        if verbose:
            actual_freq = fclk * (ddsa_phstep_h + ddsa_phstep_l / (4096.0-modulo)) * 0.5**20
            ferror = freq - actual_freq
            print("Frequency error %.3f Hz" % (ferror*1e6))
            print(vlist)
        self.leep.reg_write(vlist)

    def sn_write(self, write_string):
        for ix in range(len(write_string)):
            if self.spartan_interface:
                self.spartan_interface.write_at24c32d_prom(
                    self.fmc_prom_address, ix, ord(write_string[ix]))
        pass

    def sn_read(self, count=27, start_ix=0):
        r_ascii = ""
        for i in range(count):
            if self.spartan_interface:
                try:
                    v = self.spartan_interface.read_at24c32d_prom(start_ix+i, False)
                    if v >= 32 and v < 127:
                        r_ascii += chr(v)
                except Exception:
                    print("Error: Failure reading FMC EEPROM")
                    return False
        return r_ascii

    def ad9653_spi_dump(self, adc_list):
        print("addr  U2  U3")
        for addr in sorted(self.ad9653_regname.keys()):
            foo = self.spi_readn(adc_list, addr)
            x = [str(codecs.encode(v[2], 'hex'))[-2:] for v in foo]
            print("%3.3x  " % addr + "  ".join(x) + " " + self.ad9653_regname[addr])

    def amc_write(self, pg, saddr, val):
        # print 'amc write pg', pg, 'saddr', hex(saddr), 'val', hex(val)
        print('amc write pg %d saddr 0x%x val 0x%x' % (pg, saddr, val))
        da = self.amc7823.dataaddr(val, self.amc7823.cmd(rw=0, pg=pg, saddr=saddr, eaddr=0x00))
        self.reg_write([
            {"U15_spi_data_addr_r": da},
            {"U15_spi_read_and_start_r": 2},
            {"U15_spi_read_and_start_r": 3}
        ])
        # print 'after write',
        # , "U15_spi_ready, U15_sdio_as_sdo", "U15_spi_start, U15_spi_read_r", "U15_spi_data_r, U15_spi_addr_r"])
        self.reg_read_value(["U15_spi_rdbk"])
        time.sleep(0.2)

    def amc_read(self, pg, saddr):
        cmd = self.amc7823.cmd(rw=1, pg=pg, saddr=saddr, eaddr=0x00)
        da = self.amc7823.dataaddr(0xaaa, cmd)
        self.reg_write([
            {"U15_spi_data_addr_r": da},
            {"U15_spi_read_and_start_r": 0},
            {"U15_spi_read_and_start_r": 3}
        ])
        time.sleep(0.02)
        result = self.reg_read_value(["U15_spi_rdbk"])[0]
        [rw, pg, saddr, eaddr] = self.amc7823.cmddecode(result >> 16)
        data = result & 0xffff
        return [rw, pg, saddr, eaddr, data]

    def ad7794_write(self, addr, val):
        # print 'ad7794 write ', 'addr', hex(addr), 'val', hex(val)
        da = self.ad7794.dataaddr(val, self.ad7794.cmd(read=0, addr=addr))
        self.reg_write([
            {"U18_spi_data_addr_r": da},
            {"U18_spi_read_and_start_r": 2},
            {"U18_spi_read_and_start_r": 3}
        ])

    def ad7794_reset(self):
        self.reg_write([
            {"U18_spi_data_addr_r": 0xffffffff},
            {"U18_spi_read_and_start_r": 0},
            {"U18_spi_read_and_start_r": 3}
        ])
        time.sleep(0.2)

    def ad7794_read(self, addr):
        da = self.ad7794.dataaddr(0xffff, self.ad7794.cmd(read=1, addr=addr))
        self.reg_write([
            {"U18_spi_data_addr_r": da},
            {"U18_spi_read_and_start_r": 0},
            {"U18_spi_read_and_start_r": 3}
        ])
        time.sleep(0.2)
        result = self.reg_read_value(["U18_spi_rdbk"])
        result = result[0]
        [read, addr, cread] = self.ad7794.cmddecode(result >> 24)
        data = result & 0xffffff
        return [read, addr, cread, data]

    def wait_for_tx_fifo_empty(self):
        retries = 0
        while 1:
            result = self.mg.readwrite(
                alist=[self.get_read_address('llspi_status')], write=0)
            r = self.mg.parse_readvalue(result)
            # rrvalue = int(r[0][2].encode('hex'), 16)
            rrvalue = int(codecs.encode(r[0][2], 'hex'), 16)
            empty = (rrvalue >> 4) & 1
            please_read = (rrvalue + 1) & 0xf
            if empty:
                break
            time.sleep(0.002)
            retries += 1
        # print(rvalue.encode('hex'), type(rvalue),
        #        hex(int(rvalue.encode('hex'), 16)), please_read)
        if retries > 0:
            print("%d retries" % retries)
        return please_read

    def verbose_send(self, dlist):
        alist = len(dlist) * [self.get_write_address('llspi_we')]
        result = self.mg.readwrite(alist=alist, dlist=dlist, write=1)
        self.mg.parse_readvalue(result)
        time.sleep(0.002)
        return self.wait_for_tx_fifo_empty()

    def U2_adc_spi_write(self, addr, value):
        self.spi_write(self.U2_adc_spi, addr, value)

    def U3_adc_spi_write(self, addr, value):
        self.spi_write(self.U3_adc_spi, addr, value)

    def dac_spi_write(self, addr, value):
        self.spi_write(self.dac_spi, addr, value)

    def lmk_spi_write(self, addr, value):
        self.spi_write(self.lmk_spi, addr, value)

    def spi_write(self, obj, addr, value):
        self.verbose_send(obj.write(addr, value))

    def spi_flush(self):
        please_read = self.wait_for_tx_fifo_empty()
        if please_read:
            discard = self.mg.readwrite(
                alist=please_read * [self.get_read_address('llspi_result')],
                write=0)
            print("spi_flush: discarded %d FIFO entries" % discard)

    def spi_read(self, obj, addr):
        # print 'spi_read addr', addr
        please_read = self.verbose_send(obj.read(addr))
        if please_read:
            result = self.mg.readwrite(
                alist=please_read * [self.get_read_address('llspi_result')],
                write=0)
            return self.mg.parse_readvalue(result)

    def spi_readn(self, obj_list, addr):
        please_read = self.verbose_send(sum([adc.read(addr) for adc in obj_list], []))
        lol = len(obj_list)
        if please_read != lol:
            print("spi_readn mismatch please_read %d  len(obj_list) %d" %
                  (please_read, lol))
        if please_read:
            result1 = self.mg.readwrite(
                alist=please_read * [self.get_read_address('llspi_result')],
                write=0)
            result2 = self.mg.parse_readvalue(result1)
            return result2

    def adc_reg(self):
        adc = self.reg_read(
            ['U3dout_msb', 'U3dout_lsb', 'U2dout_msb', 'U2dout_lsb'])
        # print('adc_reg U3DAU3DB U3DCU3DD U2DAU2DB U2DCU2DD',
        #       [(d[2].encode('hex')) for d in adc])
        U3DA = struct.unpack('!H', adc[0][2][0:2])[0]
        U3DB = struct.unpack('!H', adc[0][2][2:4])[0]
        U3DC = struct.unpack('!H', adc[1][2][0:2])[0]
        U3DD = struct.unpack('!H', adc[1][2][2:4])[0]
        U2DA = struct.unpack('!H', adc[2][2][0:2])[0]
        U2DB = struct.unpack('!H', adc[2][2][2:4])[0]
        U2DC = struct.unpack('!H', adc[3][2][0:2])[0]
        U2DD = struct.unpack('!H', adc[3][2][2:4])[0]
        return [U3DA, U3DB, U3DC, U3DD, U2DA, U2DB, U2DC, U2DD]

    def adc_reg_hilo(self):
        adcvalue = self.adc_reg()
        hilo = []
        for value in adcvalue:
            hilo.append(value >> 8)
            hilo.append(value & 0xff)
        # print([hex(i) for i in adcvalue]#, [hex(i) for i in hilo])
        return hilo

    def set_test_mode(self, tp):
        if tp != self.test_mode_now:
            for adc in [self.U2_adc_spi, self.U3_adc_spi]:
                self.spi_write(adc, 0xd, tp)
        self.test_mode_now = tp
        return tp  # self.spi_read(adc, 0xd)[0][2].encode('hex')

    def bitslip_calc(self, value=0xa19c):
        value_hi = value >> 8
        value_lo = value & 0xff
        checklist = 8 * [value_hi, value_lo]
        adchilo = self.adc_reg_hilo()

        bitsliplist = [
            adchilo[ix] != checklist[ix] for ix in range(len(adchilo))
        ]
        bitslip = (eval('0b' + ''.join([str(int(i)) for i in bitsliplist])))
        return bitslip

    def idelayctrl_reset(self):
        self.reg_write([
            {'idelayctrl_reset_r': 0},
            {'idelayctrl_reset_r': 1},
            {'idelayctrl_reset_r': 0}
        ])  # , {'idelayctrl_reset_r': 0}])

    def U2_adc_iserdes_reset(self):
        self.reg_write([
            {'U2_iserdes_reset_r': 0},
            {'U2_iserdes_reset_r': 1},
            {'U2_iserdes_reset_r': 1},
            {'U2_iserdes_reset_r': 0}
        ])

    def U3_adc_iserdes_reset(self):
        self.reg_write([
            {'U3_iserdes_reset_r': 0},
            {'U3_iserdes_reset_r': 1},
            {'U3_iserdes_reset_r': 1},
            {'U3_iserdes_reset_r': 0}
        ])

    def hw_reset(self):
        self.reg_write([
            {'U4_reset_r': 0},
            {'U4_reset_r': 1},
            {'U4_reset_r': 0},
            {'U4_reset_r': 0}
        ])

    def adc_test_reset(self):
        self.reg_write([
            {'adc_test_reset': 0},
            {'adc_test_reset': 1},
            {'adc_test_reset': 1},
            {'adc_test_reset': 0}
        ])

    def digitizer_spi_init(self):
        self.reg_write([{'periph_config': 0xfffffffd}])
        self.spi_flush()
        sys.stdout.write("start lmk setup -")
        self.spi_write(self.lmk_spi, 15, self.lmk_spi.R15(uWireLock="0"))
        self.spi_write(self.lmk_spi, 0, self.lmk_spi.R0(RESET='1'))
        if False:
            # Check this if running on sliderule.dhcp with 377MHz input clock
            self.spi_write(
                self.lmk_spi,
                0,
                self.lmk_spi.R0(RESET='0',
                                CLKin0_DIV="010",
                                CLKin1_DIV="000",
                                CLKin1_MUX="01",
                                CLKin0_MUX="01"))
        else:
            self.spi_write(
                self.lmk_spi,
                0,
                self.lmk_spi.R0(RESET='0',
                                CLKin0_DIV="111",
                                CLKin1_DIV="000",
                                CLKin1_MUX="01",
                                CLKin0_MUX="01"))
        # , CLKout4_7_PD='1', CLKout0_3_PD='0'))#, CLKin0_DIV='011'))
        self.spi_write(
            self.lmk_spi,
            1,
            self.lmk_spi.R1(
                CLKout7_TYPE="0000",  # Powerdown
                CLKout4_TYPE="0000",  # Powerdown
                CLKout2_TYPE="001"))  # LVCMOS
        self.spi_write(
            self.lmk_spi,
            2,
            self.lmk_spi.R2(
                CLKout13_TYPE="0000",  # Powerdown
                CLKout12_TYPE="0000",  # Powerdown
                CLKout11_TYPE="0110",  # CMOS J24 test point
                CLKout10_TYPE="0001",  # LVDS J20
                CLKout9_TYPE="0000",  # Powerdown
                CLKout8_TYPE="0000"))  # Powerdown
        sys.stdout.write("done\n")
        sys.stdout.flush()
        time.sleep(0.3)
        sys.stdout.write("turn on lmk output -")
        self.spi_write(
            self.lmk_spi,
            3,
            self.lmk_spi.R3(SYNC1_AUTO="0",
                            SYNC0_AUTO="0",
                            SYNC1_FAST="1",
                            SYNC0_FAST="1",
                            SYNC0_POL_INV='0',
                            SYNC1_POL_INV='0'))
        sys.stdout.write("done\n")
        sys.stdout.flush()
        sys.stdout.write("continue lmk setup -")
        self.spi_write(
            self.lmk_spi, 4, self.lmk_spi.R4(CLKout12_13_DDLY="0000000000"))
        self.spi_write(self.lmk_spi, 5, self.lmk_spi.R5(CLKout0_3_DIV="010"))
        self.spi_write(self.lmk_spi, 15, self.lmk_spi.R15(uWireLock="1"))
        sys.stdout.write("done\n")
        sys.stdout.flush()

        sys.stdout.write("various resets -")
        self.idelayctrl_reset()
        self.U2_adc_iserdes_reset()
        self.U3_adc_iserdes_reset()
        self.hw_reset()
        for adc in [self.U2_adc_spi, self.U3_adc_spi]:
            self.spi_write(adc, 0x00, '00111100')
            self.spi_write(adc, 0x08, '00000011')
            self.spi_write(adc, 0x08, '00000000')
            # init
            self.spi_write(adc, 0x100, '01000110')
            self.spi_write(adc, 0xff, '00000001')
            self.spi_write(adc, 0x14, '00000010')
            # self.spi_write(adc, 0x16, '00000100')
            self.spi_write(adc, 0x18, '00000100')
            self.spi_write(adc, 0x09, '00000001')
        sys.stdout.write("done\n")
        sys.stdout.flush()

        print("AD9653 initialization")
        self.ad9653_spi_dump([self.U2_adc_spi, self.U3_adc_spi])
        print("done")
        sys.stdout.flush()

        print("AD9781 initialization")
        self.spi_write(self.dac_spi, 0, '00100000')
        self.spi_write(self.dac_spi, 0, '00000000')
        self.spi_write(self.dac_spi, 2, '00000000')
        self.spi_write(self.dac_spi, 3, '00000000')
        self.spi_write(self.dac_spi, 4, '11011111')
        if True:
            self.spi_write(self.dac_spi, 10, '00001111')  # mix mode for SCLLRF
        else:
            self.spi_write(self.dac_spi, 10, '00000000')  # normal mode for gun
        # self.spi_write(self.dac_spi, 0xb, '11111111')
        # self.spi_write(self.dac_spi, 0xc, '11111111')
        # self.spi_write(self.dac_spi, 0xf, '11111111')
        # self.spi_write(self.dac_spi, 0x10, '11111111')
        alist = [
            0x00, 0x02, 0x03, 0x04, 0x05, 0x06, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e,
            0x0f, 0x10, 0x11, 0x12
        ]
        alist += [0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f]
        for addr in alist:
            bb = [
                codecs.encode(d[2], 'hex') for d in self.spi_read(self.dac_spi, addr)
            ]
            print('dac spi addr 0x%x ' % addr + repr(bb))
        print("done")
        sys.stdout.flush()

        print("Polling SPI bus device reset -")
        self.ad7794_reset()
        self.ad7794_write(0x1, 0x200aff)
        self.ad7794_write(0x2, 0x0011ff)
        self.ad7794_write(0x1, 0x200aff)
        # AMC7823 RESET register, invoke system reset
        self.amc_write(1, 0xc, 0xbb30)
        # AMC7823 ADC control register, set:
        # - first channel to to be converted is CH0
        # - last channel to be converted is CH8
        # - CMODE to auto-mode
        self.amc_write(1, 0xb, 0x8080)
        # AMC7823 Power-Down register
        # Set ADC, DACs, and current source
        # for normal operating mode
        self.amc_write(1, 0xd, 0xffff)
        print("done")
        sys.stdout.flush()

    def adc_reset_clk(self):
        print('adc_reset_clk')
        regs = []
        regs.extend(1 * [{'U2_clk_reset_r': 0}])
        regs.extend(1 * [{'U2_clk_reset_r': 1}])
        regs.extend(1 * [{'U2_clk_reset_r': 0}])
        regs.extend(1 * [{'U3_clk_reset_r': 0}])
        regs.extend(1 * [{'U3_clk_reset_r': 1}])
        regs.extend(1 * [{'U3_clk_reset_r': 0}])
        self.reg_write(regs)

        print('test pattern %s' % self.set_test_mode('00001100'))
        time.sleep(0.34)  # Frequency counter reference 24 bits at 50 MHz
        adc_freq = self.reg_read_value(["frequency_adc"])[0]
        adc_freq = adc_freq * 50 * 0.5**24
        print('ADC clock %.3f MHz' % adc_freq)
        if adc_freq < 20:
            print("Error: ADC clock not present")
            return False
        if abs(adc_freq - 94.2857) > 0.01:
            print("#### WARNING #### Unexpected ADC frequency")
        adc_values = self.adc_reg()
        print('adc_value ' + ' '.join(['%4.4x' % i for i in adc_values]))
        print('0x%x %s %s' % (adc_values[0], adc_values[0] != 0x4339,
                              adc_values[0] != 0xa19c))
        return True

    def top2idelay(self, listin, LH):
        a = [
            1 if listin[i] == listin[(i - 1) & 0x1f] and
            (listin[i] in self.valid_pattern[LH]) else 0
            for i in range(len(listin))
        ]
        cnt = len(a) * [0]
        out = len(a) * [0]
        # for ix in range(a.index(0), a.index(0)+len(a)):
        for ix in range(len(a)):
            index = ix & 0x1f
            # print ix, index, (index-1) & 0x1f
            cnt[index] = a[index] * (cnt[(index - 1) & 0x1f] + 1)
            out[index] = 0 if a[(index + 1) & 0x1f] else cnt[index]
        top1 = sorted(out)[-1]
        top2 = sorted(out)[-2]
        return ((out.index(top1)) - top1 / 2) & 0x1f, (
            (out.index(top2)) - top2 / 2) & 0x1f

    def set_idelays(self, v):
        idelay_base = self.get_write_address('idelay_base')
        return [(idelay_base + ix, v[ix]) for ix in range(len(v))]

    def find_best_idelay(self, ix, idelay_dict):
        lane = [idelay_dict[jx][ix] for jx in range(32)]  # loop over delays
        return ix if 0 else self.top2idelay(lane, ix % 2)[0]

    def adc_idelay1(self, dbg1):
        print('test pattern %s' % self.set_test_mode('00001100'))
        if True:  # not needed after powerup, but will clear old values if re-scanning
            # Note hard-coded 0x70 here and for lb_idelay_write in digitizer_config.v
            scanner_reset = [{0x70 + ix: 0} for ix in range(16)]
            self.reg_write(scanner_reset)
        rlist1 = self.query_resp_list(
            [("scanner_debug", dbg1), ("scan_trigger", 3), "banyan_status"])
        print("banyan_status 1 %x" % rlist1[0])
        time.sleep(0.002)
        idelay_base = self.get_read_address('idelay_base')
        glist1 = ["banyan_status"] + list(range(idelay_base, idelay_base + 16))
        rlist1 = self.query_resp_list(glist1)
        print("banyan_status 2 %x" % rlist1[0])
        scan_addr = self.get_read_address("scanner_result")
        scan_result = self.reg_read_alist(list(range(scan_addr, scan_addr + 2048)))
        scan_v = [struct.unpack("!I", x[2]) for x in scan_result]
        print("idelay  scan   " + "  ".join(self.chan_list))
        for jx in range(32):
            bb = " ".join(
                ["%2.2x" % scan_v[lx * 128 + jx * 4 + 3] for lx in range(16)])
            print("idelay %2.2d  Rx %s" % (jx, bb))
        print("idelay mirror " + " ".join(["%2d" % (x & 0x1f) for x in rlist1[1:17]]))
        print("idelay mflags " + " ".join(["%2d" % (x >> 5) for x in rlist1[1:17]]))
        return all([2 == (x >> 5)
                    for x in rlist1[1:17]])  # all channels scan success!

    def adc_idelay0(self):
        print('test pattern %s' % self.set_test_mode('00001100'))
        print("idelay  scan   " + "  ".join(self.chan_list))
        idelay_dict = {}
        for idelay in range(33):
            test = ['U3dout_msb', 'U3dout_lsb', 'U2dout_msb', 'U2dout_lsb'
                    ] + self.set_idelays([idelay % 32] * 16)
            list_resp = self.query_resp_list(test)
            if 0:
                list_resp = [0x12345678, 0x24681357, 0xdeadbeef, 0xfeedface]
            if idelay == 0:
                continue
            # subdivide four 32-bit values to 16 x 8-bit values
            rx_pats = sum(
                [[x >> 24, (x >> 16) & 0xff, (x >> 8) & 0xff, x & 0xff]
                 for x in list_resp], [])
            bb = " ".join(["%2.2x" % x for x in rx_pats])
            print("idelay %2.2d  Rx %s" % ((idelay - 1), bb))
            idelay_dict[idelay - 1] = rx_pats
        idelay_bests = [
            self.find_best_idelay(ix, idelay_dict) for ix in range(16)
        ]
        print("idelay  best  " + " ".join(['%2d' % v for v in idelay_bests]))
        self.query_resp_list(self.set_idelays(idelay_bests))
        if 1:
            idelay_base = self.get_read_address('idelay_base')
            glist1 = ["banyan_status"] + list(range(idelay_base, idelay_base + 16))
            rlist1 = self.query_resp_list(glist1)
            print("idelay mirror " + " ".join(["%2d" % (x & 0x1f) for x in rlist1[1:17]]))
            print("idelay mflags " + " ".join(["%2d" % (x >> 5) for x in rlist1[1:17]]))
        for i in range(0):
            adc = self.adc_reg()
            print(" ".join([hex(i) for i in adc]))
            time.sleep(0.002)
        return True  # ???

    def adc_bufr_reset1(self, adc_values, name, adc, ic_reset, iserdes_reset):
        success = False
        for ix in range(24):
            if adc_values[adc] == 0x4339 or adc_values[adc] == 0xa19c:
                success = True
                break
            self.reg_write([{ic_reset: 0}, {ic_reset: 1}, {ic_reset: 0}])
            iserdes_reset()
            adc_values = self.adc_reg()
            print('adc_value ' + ' '.join(['%4.4x' % i for i in adc_values]))
            if adc_values[adc] == 0x4339 or adc_values[adc] == 0xa19c:
                success = True
                break
        else:
            print('ERROR: %s sync failed' % name)
        print('%s sync stopped after %d iterations' % (name, ix))
        return success, adc_values

    def adc_bufr_reset(self):
        print('test pattern %s' % self.set_test_mode('00001100'))
        adc_values = self.adc_reg()
        print('adc_value ' + ' '.join(['%4.4x' % i for i in adc_values]))
        print('0x%x %s %s' % (adc_values[0], adc_values[0] != 0x4339, adc_values[0] != 0xa19c))
        s1, adc_values = self.adc_bufr_reset1(adc_values, 'BUFR 1', 0,
                                              'U3_clk_reset_r',
                                              self.U3_adc_iserdes_reset)
        s2, adc_values = self.adc_bufr_reset1(adc_values, 'BUFR 2', 2,
                                              'U2_clk_reset_r',
                                              self.U2_adc_iserdes_reset)
        return s1 and s2

    def adc_bitslip(self):
        print('bitslip: test pattern %s' % self.set_test_mode('00001100'))
        index = 0
        bitslip = self.bitslip_calc()
        print(format(bitslip, '016b'))
        time.sleep(0.002)
        while index <= 8 and bitslip != 0:
            self.reg_write([{'bitslip': bitslip}])
            self.reg_write([{'bitslip': 0}])
            time.sleep(0.001)
            bitslip = self.bitslip_calc()
            print(format(bitslip, '016b'))
            index = index + 1
        print("bitslip %s after %d iteration(s)" %
              ("success" if bitslip == 0 else "failure", index))
        for i in range(10):
            adc = self.adc_reg()
            print(" ".join([hex(i) for i in adc]))
            time.sleep(0.002)

    def adc_twos_comp(self, twoscomp):
        for adc in [self.U2_adc_spi, self.U3_adc_spi]:
            value = '00000011' if twoscomp else '00000010'
            self.spi_write(adc, 0x14, value)
            # print 'reg0x14', value

    def reg4(self, SET, HLD):
        return format(((SET & 0xf) << 4) + (HLD & 0xf), '08b')

    def reg5(self, SMP):
        return format(SMP, '08b')

    def seeksethldsmp(self, SET, HLD, SMP, display=0):
        self.spi_write(self.dac_spi, 4, self.reg4(SET, HLD))
        self.spi_write(self.dac_spi, 5, self.reg5(SMP))
        reg6 = self.spi_read(self.dac_spi, 6)
        SEEK = struct.unpack('!I', reg6[0][2])[0] & 0x1
        if display:
            print('working SMP %d SET %d HLD %d SEEK %d' % (SMP, SET, HLD, SEEK))
        return SEEK

    def dac_smp(self, SET=None, HLD=None, SMP=None):
        if SET and HLD and SMP:
            self.seeksethldsmp(SET=SET, HLD=HLD, SMP=SMP, display=1)
        else:
            # step 1
            SMP = 0
            SET = 0
            HLD = 0
            SEEK = self.seeksethldsmp(SET, HLD, SMP)
            print('step 1 %d %d %d %d' % (SMP, SEEK, SET, HLD))
            SEEK_000 = SEEK
            # step 2
            SMP = 0
            SET = 0
            HLD = 0
            SEEK = SEEK_000
            while HLD < 16 and SEEK == SEEK_000:
                HLD = HLD + 1
                SEEK = self.seeksethldsmp(SET, HLD, SMP)
            print('step 2 %d %d %d %d' % (SMP, SEEK, SET, HLD))
            # step 3
            SMP = 0
            SET = 0
            HLD = 0
            SEEK = SEEK_000
            while SET < 16 and SEEK == SEEK_000:
                SET = SET + 1
                SEEK = self.seeksethldsmp(SET, HLD, SMP)
            # print 'set', SET, 'seek', SEEK
            print('step 3 %d %d %d %d' % (SMP, SEEK, SET, HLD))
            # step 4
            SET = 0
            HLD = 0
            SMP = 0
            SEEK = SEEK_000
            while SMP < 32:
                SMP = SMP + 1
                SEEK = self.seeksethldsmp(SET, HLD, SMP)
                SEEK_SMP = SEEK
                while HLD < 16 and SEEK == SEEK_SMP:
                    HLD = HLD + 1
                    SEEK = self.seeksethldsmp(SET, HLD, SMP)
                HLD_SMP = HLD
                HLD = 0
                while SET < 16 and SEEK == SEEK_SMP:
                    SET = SET + 1
                    SEEK = self.seeksethldsmp(SET, HLD, SMP)
                SET_SMP = SET
                SET = 0
                print('step 3 %d %d %d %d' % (SMP, SEEK_SMP, SET_SMP, HLD_SMP))

    # def raw_buf(self, adc_ch):  unused, bit-rotten, deleted; see all_adcs.py instead.

    def pntest_kernel(self, data):
        cnt = 0
        p9 = self.pn9
        offset = p9.index(data[0]) if data[0] in p9 else (p9.index(data[1])-1 if data[1] in p9 else 0)
        pn9l = len(p9)
        for i in range(len(data)):
            d = data[i]
            p = p9[(i+offset) % pn9l]
            if p != d:
                cnt += 1
            if d-p and False:
                print("%d %04x %04x %d" % (i, d, p, p-d))
            # print 'chan', chan, 'error:', cnt
        return cnt

    def pntest(self):
        print("pntest using circular buffer wave0")
        self.set_test_mode('00000110')
        self.adc_twos_comp(twoscomp=False)
        cntlist = []
        for chan in range(8):
            sys.stdout.write('pseudo-random test channel %d (%s)' % (chan, self.channels[chan]))
            sys.stdout.flush()
            self.reg_write([{'wave0_src': chan}])
            # time.sleep(0.05)
            self.buf_read_raw('wave0_out', count=2**self.cirbuf_aw)
            self.buf_read_raw('wave0_out', count=2**self.cirbuf_aw)
            data = self.buf_read_raw('wave0_out', count=2**self.cirbuf_aw)
            # print data[0][0:2].encode('hex')
            # print data[0][2:4].encode('hex')
            data = [struct.unpack('!H', r[2:4])[0] for r in data]
            cnt = self.pntest_kernel(data)
            cntlist.append(cnt)
            sys.stdout.write('fail %d\n' % cnt if cnt else 'pass\n')
            sys.stdout.flush()
        return cntlist

    def pntest2(self, quiet=False):
        # first check the configuration to see if banyan_mem is in this FPGA build
        b_status = self.reg_read_value(["banyan_status"])[0]
        npt = 1 << ((b_status >> 24) & 0x3f)
        if npt < 512:
            return []
        # if npt > 4096:
        #     npt = 4096
        if not quiet:
            print("pntest2 using banyan_mem npt=%d" % npt)
        sys.stdout.flush()
        self.set_test_mode('00000110')
        self.adc_twos_comp(twoscomp=False)
        self.reg_write([{'banyan_mask': 0xff}])
        from banyan_spurs import collect
        (dataset, timestamp) = collect(
            self, npt, print_minmax=False, allow_clk_frozen=True)
        cntlist = []
        for chan in range(8):
            if not quiet:
                sys.stdout.write('pseudo-random test channel %d (%s)' %
                                 (chan, self.channels[chan]))
                sys.stdout.flush()
            data = [x + 65536 if x < 0 else x for x in dataset[chan]]
            cnt = self.pntest_kernel(data)
            cntlist.append(cnt)
            if not quiet:
                sys.stdout.write('fail %d\n' % cnt if cnt else 'pass\n')
                sys.stdout.flush()
        return cntlist

    def mmcm_step(self, count):
        cmd = 1 if count > 0 else 3
        pstep_one = [{'adc_mmcm': cmd}] + 3 * [{'adc_mmcm': 0}]
        self.reg_write(abs(count) * pstep_one)

    def pntest3(self, pstep):
        for kx in range(56 * 10 / pstep):
            r = self.pntest2(quiet=True)
            print("%3d " % (kx*pstep) + "  ".join(["%5d" % x for x in r]))
            self.mmcm_step(pstep)

    def pntest4(self):
        pstep = 5
        ok = 0
        print("Scanning adc_clk mmcm phase")
        try:
            self.reg_write([{"clk_status_we": 1}])
            clk_status_present = 1
        except KeyError:
            print("Please upgrade to post-commit-5a098b92 bitfile")
            clk_status_present = 0
        for kx in range(15):  # range(56*10/pstep):
            r = self.pntest2(quiet=True)
            print("%2d " % (kx*pstep) + "  ".join(["%5d" % x for x in r]))
            if all(x == 0 for x in r):
                ok += 1
            else:
                ok = 0
            if ok == 5:
                self.mmcm_step(-2 * pstep)
                print("Found safe mmcm phase %d" % ((kx - 2) * pstep))
                if clk_status_present:
                    self.reg_write([{"clk_status_we": 2}])
                    c_status = self.reg_read_value(["clk_status_out"])[0]
                    print("Clock status %d" % c_status)
                return True
            self.mmcm_step(pstep)
        print("Error: Finished full mmcm phase scan without finding eye")
        return False

    def ad7794_read_channel(self, chan, G=0):
        config = self.ad7794.configuration_register(chan=chan, G=G, REFSEL=2)  # should this in the init?
        # print 'chan', chan, 'config', format(config, '06x'), 'reading'
        self.ad7794_write(0x2, config)
        self.ad7794_write(0x1, 0x200aff)
        time.sleep(0.3)
        # read0 = self.ad7794_read(0x0)
        # print [format(i, '06x') for i in read0]
        read3 = self.ad7794_read(0x3)
        # print [format(i, '06x') for i in read3],
        return read3[3]

    def ad7794_value(self):
        return [self.ad7794_read_channel(i) for i in [0, 1, 2, 5, 6, 7]]

    def amc7823_read(self, addr):
        return self.amc_read(pg=0, saddr=addr)[4] & 0xfff

    def amc7823_adcread(self, addr):
        return self.amc7823_read(addr=addr)

    def amc7823_adcread_volt(self, addr):
        adcs = self.amc7823_adcread(addr=addr)
        v = adcs * 2.5 / 2**12
        return v

    def amc7823_adcread_volt_all(self):
        return [self.amc7823_adcread_volt(addr) for addr in range(9)]

    def amc7823_string(self, check_channels=[]):
        ss = "AMC7823 housekeeping voltages\n"
        amc_labels = {
            0: 'Spare (J14-9)',
            1: 'V2P2V_MON (0.5 * V2P2V)',
            2: 'V3P7V_MON (0.5 * V3P7V)',
            3: 'V12P0V_MON (0.1776 * V12P0V)',
            4: 'microphone',
            5: 'LO_MON',
            6: 'I_MON current * 1 Ohm',
            7: 'V_MON (0.5 * VDD3P3V)',
            8: 'On-chip temperature'
        }
        v = self.amc7823_adcread_volt_all()
        amc_minmax = [(0, 3.3), (1.0, 1.2), (1.66, 2.04), (0.85, 2.24),
                      (0.5, 2.7), (0.7, 1.4), (0.3, 0.9), (1.5, 1.8),
                      (0.1, 0.2)]
        rv = True
        for addr in range(9):
            # print '%4.4x' % adcs[addr],
            n = amc_labels[addr] if addr in amc_labels else "."
            too_lo = v[addr] < amc_minmax[addr][0]
            too_hi = v[addr] > amc_minmax[addr][1]
            code = ("<" if too_lo else " ") + (">" if too_hi else " ")
            ss += '%2d  %6.3f V %s %s\n' % (addr, v[addr], code, n)
            if (addr in check_channels) and (too_lo or too_hi):
                rv = False
        return (ss, rv)

    def amc7823_print(self, check_channels=[]):
        (ss, rv) = self.amc7823_string(check_channels)
        sys.stdout.write(ss)
        return rv


def usage():
    print("python prc.py -a $IP [-r [-b bitfile] ]")


if __name__ == "__main__":
    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:rb:m:s:w:u', [
        'help', 'addr=', 'port=', 'reset', 'scan=', 'filewritepath=',
        'usespartan'
    ])
    ip_addr = '192.168.21.11'
    port = 50006
    reset = False
    regmappath = './live_prc_regmap.json'
    bitfilepath = None
    do_scan = False
    filewritepath = None
    use_spartan = False
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg
        elif opt in ('-p', '--port'):
            port = int(arg)
        elif opt in ('-r', '--reset'):
            reset = True
        elif opt in ('-b', '--bitfile'):
            bitfilepath = arg
        elif opt in ('-m', '--regMapfile'):
            regmappath = arg
        elif opt in ('-s', '--scan'):
            do_scan = True
            scan_incr = int(arg)
        elif opt in ('-w', '--filewritepath'):
            filewritepath = arg
        elif opt in ('-u', '--usespartan'):
            use_spartan = True
    prc = c_prc(
        ip_addr,
        50006,
        regmappath=regmappath,
        bitfilepath=bitfilepath,
        reset=reset,
        filewritepath=filewritepath,
        use_spartan=use_spartan)

    if do_scan:
        prc.pntest3(scan_incr)

    onewire_status(prc, 0x150000, "Upconverter  ")
    onewire_status(prc, 0x151000, "Downconverter")
