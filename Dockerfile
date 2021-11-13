FROM debian:bullseye-slim as testing_base_bullseye

# Vivado needs libtinfo5, at least for Artix?
# libz-dev required for Verilator FST support
RUN apt-get update && \
	apt-get install -y \
	git \
	iverilog \
	libz-dev \
	libbsd-dev \
	xc3sprog \
	build-essential \
	libtinfo5 \
	wget \
	iputils-ping \
	iproute2 \
	bsdmainutils \
	curl \
	gawk \
	flake8 \
	python3-pip \
	python3-numpy \
	python3-scipy \
	python3-matplotlib && \
	rm -rf /var/lib/apt/lists/* && \
	python3 -c "import numpy; print('LRD Test %f' % numpy.pi)" && \
	pip3 --version

# Replaces previous build-riscv-gcc-from-source step
RUN apt-get install -y gcc-riscv64-unknown-elf

# flex and bison required for building vhd2vl
RUN apt-get install -y \
	cmake \
	flex \
	bison \
	libftdi1-dev \
	libusb-dev \
	pkg-config && \
	rm -rf /var/lib/apt/lists/*

# Must follow iverilog installation
RUN git clone https://github.com/ldoolitt/vhd2vl && \
	cd vhd2vl && \
	git checkout 37e3143395ce4e7d2f2e301e12a538caf52b983c && \
	make && \
	install src/vhd2vl /usr/local/bin && \
	cd .. && \
	rm -rf vhd2vl

# No longer build yosys or verilator from source
RUN apt-get install -y yosys verilator openocd

RUN pip3 install pyyaml==5.1.2 nmigen==0.2 pyserial==3.4

# SymbiYosys formal verification tool + Yices 2 solver (`sby` command)
RUN apt-get install -y build-essential clang bison flex libreadline-dev \
					 gawk tcl-dev libffi-dev git mercurial graphviz   \
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
	make install

