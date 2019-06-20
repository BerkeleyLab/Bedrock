all: clean
	$(MAKE) -C ./bootLoad
	$(MAKE) -C ./fmc150
	$(MAKE) -C ./gpio
	$(MAKE) -C ./i2c
# 	$(MAKE) -C ./iserdes
	$(MAKE) -C ./lb_bridge
	$(MAKE) -C ./mpack
	$(MAKE) -C ./onewire
	$(MAKE) -C ./spi
	$(MAKE) -C ./uart
	$(MAKE) -C ./uart_fifo
# 	$(MAKE) -C ./xadc
# iserdes, xadc disabled as they require the xilinx unisims library on CI

clean:
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
