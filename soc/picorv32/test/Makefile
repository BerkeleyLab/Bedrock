# iserdes, xadc disabled as they require the xilinx unisims library on CI
all: clean check fv

check:
	$(MAKE) -C ./badger_loopback
	$(MAKE) -C ./bootLoad
	$(MAKE) -C ./fmc150
	$(MAKE) -C ./gpio
	$(MAKE) -C ./i2c
#   $(MAKE) -C ./iserdes
#   $(MAKE) -C ./lb_bridge  # TODO lb_bridge: fix & improve PASS / FAIL logic
	$(MAKE) -C ./mpack
	$(MAKE) -C ./onewire
	$(MAKE) -C ./spi
	$(MAKE) -C ./uart
	$(MAKE) -C ./uart_fifo
#    $(MAKE) -C ./xadc
	$(MAKE) -C ./sram
	$(MAKE) -C ./memio
	$(MAKE) -C ../project/cmod_a7/sim
	$(MAKE) -C ./wfm
	$(MAKE) -C ./awg

fv:
	# Formal verification of some components
	cd fv && sby f_pack.sby
	cd fv && sby fifo.sby
	cd fv && sby shortfifo.sby

clean:
	$(MAKE) -C ./badger_loopback clean
	$(MAKE) -C ./bootLoad  clean
	$(MAKE) -C ./fmc150    clean
	$(MAKE) -C ./gpio      clean
	$(MAKE) -C ./i2c       clean
	$(MAKE) -C ./iserdes   clean
	$(MAKE) -C ./lb_bridge clean
	$(MAKE) -C ./mpack     clean
	$(MAKE) -C ./onewire   clean
	$(MAKE) -C ./spi       clean
	$(MAKE) -C ./uart      clean
	$(MAKE) -C ./uart_fifo clean
	$(MAKE) -C ./xadc      clean
	$(MAKE) -C ./sram      clean
	$(MAKE) -C ./memio     clean
	$(MAKE) -C ./zest      clean
	$(MAKE) -C ../project/cmod_a7/sim clean
	$(MAKE) -C ./wfm       clean
	$(MAKE) -C ./awg       clean
	rm -rf fv/f_pack_sfr_pack fv/f_pack_uart_pack fv/fifo/ fv/shortfifo/
