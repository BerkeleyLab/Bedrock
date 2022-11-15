FROM debian:bullseye-slim as testing_base_bullseye

# Vivado needs libtinfo5, at least for Artix?
RUN apt-get update && \
	apt-get install -y \
	git \
	iverilog \
	libbsd-dev \
	xc3sprog \
	build-essential \
	libtinfo5 \
	wget \
	iputils-ping \
	iproute2 \
	bsdmainutils \
	curl \
	flake8 \
	python3-pip \
	python3-numpy \
	python3-scipy \
	python3-matplotlib \
	gcc-riscv64-unknown-elf \
	picolibc-riscv64-unknown-elf \
	cmake \
	flex \
	bison \
	libftdi1-dev \
	libusb-dev \
	openocd \
	pkg-config && \
	rm -rf /var/lib/apt/lists/* && \
	python3 -c "import numpy; print('LRD Test %f' % numpy.pi)" && \
	pip3 --version
# Note that flex, bison, and iverilog (above) required for building vhd2vl.
# gcc-riscv64-unknown-elf above replace our previous
#   approach, used in Buster, of building from source

# vhd2vl
RUN git clone https://github.com/ldoolitt/vhd2vl && \
	cd vhd2vl && \
	git checkout 37e3143395ce4e7d2f2e301e12a538caf52b983c && \
	make && \
	install src/vhd2vl /usr/local/bin && \
	cd .. && \
	rm -rf vhd2vl

# Yosys
# For now we need to build yosys from source, since Debian Bullseye
# is stuck at yosys-0.9 that doesn't have the features we need.
# Revisit this choice when Debian catches up, maybe in Bookworm,
# and hope to get back to "apt-get install yosys" then.
# Note that the standard yosys build process used here requires
# network access to download abc from https://github.com/berkeley-abc/abc.
RUN git clone https://github.com/cliffordwolf/yosys.git && \
	cd yosys && \
	git checkout 40e35993af6ecb6207f15cc176455ff8d66bcc69 && \
	apt-get update && \
	apt-get install -y clang libreadline-dev tcl-dev libffi-dev graphviz \
	xdot libboost-system-dev libboost-python-dev libboost-filesystem-dev zlib1g-dev && \
	make config-clang && make -j4 && make install && \
	cd .. && rm -rf yosys && \
	rm -rf /var/lib/apt/lists/*

RUN pip3 install pyyaml==5.1.2 nmigen==0.2 pyserial==3.4

# we need a version of verilator with more than 20000, issue #1574,
# any version > v4.110 should have this limit increased to 40000,
# or change the LINE_TOKEN_MAX macro to the desired value
# libz-dev required for Verilator FST support
RUN apt-get update && \
	apt-get install -y \
	libfl2 \
	libfl-dev \
	libz-dev \
	zlib1g \
	zlib1g-dev \
	autoconf && \
	rm -rf /var/lib/apt/lists/* && \
	git clone https://github.com/verilator/verilator && \
	cd verilator && \
    git checkout v4.034 && \
    sed -i -e '/LINE_TOKEN_MAX/s/20000/40000/' src/V3PreProc.h && \
	autoconf && \
	./configure && \
	make -j4 && \
	make install && \
	cd ../ && \
	rm -rf verilator && \
	verilator -V

# SymbiYosys formal verification tool + Yices 2 solver (`sby` command)
RUN apt-get update && \
	apt-get install -y \
		build-essential clang bison flex libreadline-dev \
		tcl-dev libffi-dev git graphviz   \
		xdot pkg-config python python3 libftdi-dev gperf \
		libboost-program-options-dev autoconf libgmp-dev \
		cmake && \
	git clone https://github.com/YosysHQ/SymbiYosys.git SymbiYosys && \
	cd SymbiYosys && \
	git checkout 091222b87febb10fad87fcbe98a57599a54c5fd3 && \
	make install && \
	cd .. && \
	git clone https://github.com/SRI-CSL/yices2.git yices2 && \
	cd yices2 && \
	autoconf && \
	./configure && \
	make -j$(nproc) && \
	make install && \
	rm -rf /var/lib/apt/lists/*
