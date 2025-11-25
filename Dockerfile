FROM debian:12.8-slim AS testing_base_bookworm

# Vivado needs libtinfo5, at least for Artix?
RUN apt-get update && \
    apt-get install -y \
    git \
    iverilog \
    libbsd-dev \
    xc3sprog \
    build-essential \
    yosys \
    verilator \
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
    python3-yaml \
    python3-serial \
    python3-setuptools-scm \
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

# Allow pip to install packages
RUN mkdir -p $HOME/.config/pip && \
    printf "[global]\nbreak-system-packages = true\n" > \
        $HOME/.config/pip/pip.conf && \
    cat $HOME/.config/pip/pip.conf

# vhd2vl
RUN git clone https://github.com/ldoolitt/vhd2vl && \
    cd vhd2vl && \
    git checkout bbe3198c435a4a6325bdd08b7b43a47b6dacf5de && \
    make && \
    install src/vhd2vl /usr/local/bin && \
    cd .. && \
    rm -rf vhd2vl

# Yosys and Verilator are no longer built from source, just included
# in apt-get list above.  Tested good in Debian Bookworm.

# Because we are running inside docker, installing
# python packages system wide should be ok
RUN pip3 install \
    nmigen==0.2

# SymbiYosys formal verification tool + Yices 2 solver (`sby` command)
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        clang \
        bison \
        flex \
        libreadline-dev \
        tcl-dev \
        libffi-dev \
        git \
        graphviz \
        xdot \
        pkg-config \
        python3 \
        libftdi-dev \
        gperf \
        libboost-program-options-dev \
        autoconf \
        libgmp-dev \
        cmake && \
    rm -rf /var/lib/apt/lists/* && \
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

# Add some configuration for Vivado here, so we don't break the cache
RUN apt-get update && \
    apt-get install -y \
        x11-utils \
        xvfb \
        locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale -a && \
    cat /etc/locale.gen && \
    localedef -i en_US -f UTF-8 en_US.UTF-8

# Shady stuff to make cmake work with libidn12
RUN apt-get update && \
    apt-get install -y \
        libidn12 && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s libidn.so.12 /usr/lib/x86_64-linux-gnu/libidn.so.11

# Install litex
RUN apt-get update && \
    apt-get install -y \
        ninja-build \
        gcc-aarch64-linux-gnu \
        ghdl && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install \
        meson

COPY build-tools/litex_meta.sh /

ENV LITEX_INSTALL_PATH=/litex

RUN mkdir ${LITEX_INSTALL_PATH} && \
    cd ${LITEX_INSTALL_PATH} && \
    sh /litex_meta.sh

# Install leep
RUN apt-get update && \
    pip3 install git+https://github.com/BerkeleyLab/leep.git

# Install sv2v
RUN apt-get update && \
    apt-get install -y \
        haskell-stack && \
    rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/zachjs/sv2v /sv2v && \
    cd /sv2v && \
    git checkout 7808819c48c167978aeb5ef34c6e5ed416e90875 && \
    make && \
    rm -rf $HOME/.stack && \
    cp bin/sv2v /usr/local/bin/
