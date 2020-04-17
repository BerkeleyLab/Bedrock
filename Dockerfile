# Install riscv cross compiler

FROM debian:buster-slim as riscv-builder

# prerequisites for building gcc
# wget is used by riscv_prep.sh
RUN apt-get update && apt-get install -y \
	libmpc-dev libmpfr-dev libgmp-dev \
	build-essential wget

# Documentation and rationale for this process in build-tools/riscv_meta.sh
# Note that "sh riscv_prep.sh" requires network access to pull in tarballs.
RUN cd && pwd && ls && mkdir software
COPY build-tools/riscv_prep.sh software/riscv_prep.sh
COPY build-tools/riscv_meta.sh software/riscv_meta.sh
RUN cd software && \
	sh riscv_prep.sh && \
	sh riscv_meta.sh $PWD/src /riscv32i && \
	ls /riscv32i/bin/riscv32-unknown-elf-gcc && \
	cd && rm -rf software && \
	rm -rf /var/lib/apt/lists/*

FROM debian:buster-slim as basic-iverilog

# Vivado needs libtinfo5, at least for Artix?
RUN apt-get update && \
	apt-get install -y \
	git \
	iverilog \
	verilator \
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

FROM basic-iverilog as testing_base

COPY --from=riscv-builder /riscv32i /riscv32i

ENV PATH="/riscv32i/bin:${PATH}"

# flex and bison required for building vhd2vl
RUN apt-get update && \
	apt-get install -y \
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

# Yosys
# For now we need to build yosys-0.9 from source, since Debian Buster
# is stuck at yosys-0.8 that doesn't have the features we need.
# Revisit this choice when Debian cetches up, maybe in Bullseye,
# and hope to get back to "apt-get install yosys" then.

# Note that the standard yosys build process used here requires
# network access to download abc from https://github.com/berkeley-abc/abc.

RUN git clone https://github.com/cliffordwolf/yosys.git && \
	cd yosys && git checkout yosys-0.9 && \
	apt-get update && \
	apt-get install -y clang libreadline-dev tcl-dev libffi-dev graphviz \
	xdot libboost-system-dev libboost-python-dev libboost-filesystem-dev zlib1g-dev && \
	make config-clang && make -j4 && make install && \
	cd .. && rm -rf yosys && \
	rm -rf /var/lib/apt/lists/*

RUN pip3 install pyyaml nmigen pyserial
