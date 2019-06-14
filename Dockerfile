# Install riscv cross compiler

FROM python:3-slim-stretch as riscv-builder

RUN apt-get update && apt-get install -y autoconf automake autotools-dev curl\
	libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev\
	gawk build-essential bison flex texinfo gperf\
	libtool patchutils bc zlib1g-dev device-tree-compiler git\
	pkg-config libexpat-dev

RUN mkdir software && \
	cd software && \
	git clone --recursive https://github.com/riscv/riscv-gnu-toolchain && \
	cd riscv-gnu-toolchain && mkdir build && cd build && \
	../configure --with-arch=rv32i --prefix=/riscv32i --enable-multilib && \
	make -j$(nproc) && make install && \
	ls /riscv32i/bin/riscv32-unknown-elf-gcc && \
	cd && rm -rf software/riscv-gnu-toolchain && \
	rm -rf /var/lib/apt/lists/*

# Basing of Lucas Russo's iverilog container
# "https://github.com/lerwys/docker-iverilog.git"

FROM python:3-slim-stretch as basic-iverilog

ENV IVERILOG_VERSION=v10_2

# This is a debian flag: Picks default answers for apt questions
# Largely unnecessary if -y is being given
# ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get install -y \
	gawk \
	automake \
        autoconf \
        gperf \
        build-essential \
        flex \
        bison \
	git \
	subversion && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --trusted-host pypi.python.org flake8 numpy scipy matplotlib

RUN git clone --branch=${IVERILOG_VERSION} https://github.com/steveicarus/iverilog && \
    cd iverilog && \
    bash autoconf.sh && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd && \
    rm -rf iverilog

FROM basic-iverilog as litex

ENV LITEX_VERSION=master
ENV LITEX_ROOT_URL="http://github.com/yetifrisstlama/"
RUN apt-get update && apt-get install -y wget && \
	mkdir litex_setup_dir && \
	cd litex_setup_dir && \
	wget https://raw.githubusercontent.com/yetifrisstlama/litex/${LITEX_VERSION}/litex_setup.py && \
	python litex_setup.py init install && \
	ln -s /non-free/Xilinx /opt/Xilinx

COPY --from=riscv-builder /riscv32i /riscv32i

ENV PATH="/riscv32i/bin:${PATH}"

RUN apt-get install -y verilator libbsd-dev yosys && \
	pip install git+https://github.com/m-labs/nmigen.git

FROM litex as testing_base

RUN apt-get -y update && \
	apt-get install -y \
	cmake \
	libftdi1-dev \
	libusb-dev \
	pkg-config && \
	rm -rf /var/lib/apt/lists/*

RUN svn co https://svn.code.sf.net/p/xc3sprog/code/trunk xc3sprog &&\
	cd xc3sprog &&\
	mkdir build && \
	cd build &&\
	cmake .. &&\
	make &&\
	make install &&\
	rm -rf xc3sprog
