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
	gcc-riscv64-unknown-elf \
	cmake \
	flex \
	bison \
	libftdi1-dev \
	libusb-dev \
	yosys \
	verilator \
	openocd \
	pkg-config && \
	rm -rf /var/lib/apt/lists/* && \
	python3 -c "import numpy; print('LRD Test %f' % numpy.pi)" && \
	pip3 --version
# Note that flex, bison, and iverilog (above) required for building vhd2vl.
# gcc-riscv64-unknown-elf, yosys, and verilator above replace
#   Buster's approach of building from source

RUN git clone https://github.com/ldoolitt/vhd2vl && \
	cd vhd2vl && \
	git checkout 37e3143395ce4e7d2f2e301e12a538caf52b983c && \
	make && \
	install src/vhd2vl /usr/local/bin && \
	cd .. && \
	rm -rf vhd2vl

RUN pip3 install pyyaml==5.1.2 nmigen==0.2 pyserial==3.4

# SymbiYosys formal verification tool + Yices 2 solver (`sby` command)
RUN apt-get update && \
	apt-get install -y \
		build-essential clang bison flex libreadline-dev \
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
	make install && \
	rm -rf /var/lib/apt/lists/*
