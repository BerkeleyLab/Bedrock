#!/bin/bash
# uses bash's job control feature, and localhost's UDP port 3500
# argv[1] is the spi_test.py program (with full path, to support oot runs)
# output file is spi_flash.grab
set -e
# make udp-vpi.vpi spi_flash_tb lorem_ipsum.hex
vvp -N spi_flash_tb +udp_port=3500 +firmware=lorem_ipsum.hex > /dev/null &
sleep 3
python $1 --ip localhost --udp 3500 --wait 0.15 --power --dump spi_flash.grab --add 0 --pages 1
kill %1
