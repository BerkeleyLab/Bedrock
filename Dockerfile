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

# The rest of this file defines a "stable" environment,
# but LiteX is the exception.  It's an open question whether LiteX-based designs
# should currently be considered usable for production.  If so, it would be
# helpful to freeze a version of LiteX here -- preferably an upstream one that
# doesn't involve yetifrisstlama.
FROM basic-iverilog as litex

ENV LITEX_VERSION=master
ENV LITEX_ROOT_URL="http://github.com/yetifrisstlama/"
RUN mkdir litex_setup_dir && \
	cd litex_setup_dir && \
	wget https://raw.githubusercontent.com/yetifrisstlama/litex/${LITEX_VERSION}/litex_setup.py && \
	python3 litex_setup.py init install && \
	ln -s /non-free/Xilinx /opt/Xilinx

COPY --from=riscv-builder /riscv32i /riscv32i

ENV PATH="/riscv32i/bin:${PATH}"

RUN pip3 install git+https://github.com/m-labs/nmigen.git

FROM litex as testing_base

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
