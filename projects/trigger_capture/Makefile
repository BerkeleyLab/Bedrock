PYTHON = python3
marble.bit:
	echo "dummy" > firmware/app.bin
	$(PYTHON) marble.py --no-compile-gateware --csr-csv csr.csv --cpu-type picorv32 --uart-name crossover
	make -C firmware clean all
	$(PYTHON) marble.py --build --csr-csv csr.csv --cpu-type picorv32 --uart-name crossover+uartbone

load:
	$(PYTHON) marble.py --load --no-compile-gateware --no-compile-software

clean:
	rm -rf build
	rm -f analyzer.csv csr.csv
