marble.bit:
	python3 marble.py --no-compile-gateware --csr-csv csr.csv --cpu-type picorv32 --uart-name crossover+bridge && cd firmware && make && cd .. && python3 marble.py --build --load --csr-csv csr.csv --cpu-type picorv32 --uart-name crossover+bridge

load:
	python3 marble.py --load --no-compile-gateware --no-compile-software

clean:
	rm -rf build
