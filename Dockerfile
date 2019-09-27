# Install riscv cross compiler

FROM debian:buster-slim as riscv-builder

# May only need wget build-essential libgmp-dev libmpfr-dev libmpc-dev
# test that hypothesis later
RUN apt-get update && apt-get install -y wget coreutils autoconf automake autotools-dev \
	libmpc-dev libmpfr-dev libgmp-dev \
	gawk build-essential bison flex texinfo gperf \
	libtool

# Documentation and rationale for this process in build-tools/riscv_meta.sh
RUN cd && pwd && ls && \
	mkdir software && \
	cd software && \
	wget http://recycle.lbl.gov/~ldoolitt/riscv/riscv_prep.sh && \
	wget http://recycle.lbl.gov/~ldoolitt/riscv/riscv_meta.sh && \
	echo "6d25bceb73e09aa611a4efcc0b90b40b66104cb7485a29686a95478eeb230718  riscv_prep.sh" | sha256sum -c && \
	echo "aaf2ae35d0a96399eee9d7e2adf185b49e702e1c10fc10fd7e0b9ce70b1fedcc  riscv_meta.sh" | sha256sum -c && \
	sh riscv_prep.sh && \
	sh riscv_meta.sh $PWD/src /riscv32i && \
	ls /riscv32i/bin/riscv32-unknown-elf-gcc && \
	cd && rm -rf software && \
	rm -rf /var/lib/apt/lists/*

FROM debian:buster-slim as basic-iverilog

RUN apt-get update && \
	apt-get install -y \
	git \
	iverilog \
	verilator \
	libbsd-dev \
	xc3sprog \
	build-essential \
	wget \
	iputils-ping \
	iproute2 \
	bsdmainutils \
	curl \
	gawk \
	flake8 \
	python3-numpy \
	python3-scipy \
	python3-matplotlib && \
	rm -rf /var/lib/apt/lists/* && \
	python3 -c "import numpy; print('LRD Test1 %f' % numpy.pi)"

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

RUN pip install git+https://github.com/m-labs/nmigen.git

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
	rm -rf /var/lib/apt/lists/* && \
	python3 -c "import numpy; print('LRD Test2 %f' % numpy.pi)"

# Must follow iverilog installation
RUN git clone https://github.com/ldoolitt/vhd2vl && \
	cd vhd2vl && \
	git checkout 37e3143395ce4e7d2f2e301e12a538caf52b983c && \
	make && \
	install src/vhd2vl /usr/local/bin && \
	cd .. && \
	rm -rf vhd2vl
