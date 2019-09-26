# riscv (riscv32-unknown-elf) production toolchain from scratch
# Larry Doolittle <ldoolitt@recycle.lbl.gov>  2019-09-12
# Tested good, sufficient for use with firmware in ATG's bedrock/soc/picorv32/
#
# Meant to run under any Bourne shell, e.g., bash, dash.
# Works out-of-tree, with read-only access to sources,
# and without network access (drop_net).
#
# Still wish for:
#  - reproducible-build
#  - run installs as third user
#  - test in schroot
#
# I tried to peek at
#   https://github.com/riscv/riscv-gnu-toolchain
# but that's kind of obfuscated.
#   http://www.ifp.illinois.edu/~nakazato/tips/xgcc.html
# is more to-the-point, but out-of-date.
# The numbered flow below is straight from nakazato.
# This script is meant to be as short, sweet, and concrete as possible.
# You can cut-and-paste from it to follow along step-by-step.
#
# 1. What do you need?
#
# bootstrap tools on Debian Stretch or Buster:
#   apt-get install build-essential libgmp-dev libmpfr-dev libmpc-dev
#
# Versions:
#   binutils-2.32, released 2019-02-02
#     http://www.gnu.org/software/binutils/
#   gcc-8.3.0, released 2019-02-22
#     http://www.gnu.org/software/gcc/
#   newlib-3.1.0, released 2018-12-31
#     ftp://sourceware.org/pub/newlib/index.html
#
# 0ab6c55dd86a92ed561972ba15b9b70a8b9f75557f896446c82e8b36e473ee04  binutils-2.32.tar.xz
# 64baadfe6cc0f4947a84cb12d7f0dfaf45bb58b7e92461639596c21e02d97d2c  gcc-8.3.0.tar.xz
# fb4fa1cc21e9060719208300a61420e4089d6de6ef59cf533b57fe74801d102a  newlib-3.1.0.tar.gz
#
# 1a. How to use this script?
#
# Unpack those sources into a directory of your choice, and then provide that
# directory name as the command line argument for this script.  Or, you can follow
# along line-by-line by cutting-and-pasting from here; in that case, just make sure
# that directory is named in $SRC.  The following process is tested and works
# even when the sources are available read-only.
#
# Run this script from a directory in which you have write privs.  I recommend
# an empty directory, so that your equivalent of "make clean" will be "rm -r *".
# It will take up about 7.9 GiB here, and another 1.7 GiB in $PREFIX, where the
# binaries will be installed (and feel free to modify the choice of $PREFIX below).
# This doesn't count the downloads (0.095 GiB) or the unpacked sources (1.1 GiB).
# Expect it to take a while to run, too!  I don't know what kind of computer you
# have, but a 2.2 GHz i5 of mine with SSD took about 40 min using make -j3.
#
# My favorite way of running this script is
#   drop_net sh toolchain2.sh $HOME/src 2>&1 | tee buildlog
# where drop_net is optional, and beyond the scope of these instructions.
#
# When you're done, to get access to the binaries, $PATH needs to be set as below.
# Demonstrate at least partial success with
#   riscv32-unknown-elf-gcc --version
# which should print
#   riscv32-unknown-elf-gcc (GCC) 8.3.0
# followed by copyright and warranty information.
#
#
# 2. Set environment variables
# Choose to put $PREFIX/bin at the _head_ of the $PATH, so executables
# we build will win out over any older versions that might already be in $PATH.
#
SRC=$1
PREFIX=${2:-$HOME/opt}
TARGET=riscv32-unknown-elf
PATH=$PREFIX/bin:$PATH
MAKE_J=-j3
#
# 2a. Cross-check that this script has a chance of working
#
set -e
test -r $SRC/binutils-2.32/COPYING
test -r $SRC/gcc-8.3.0/COPYING
test -r $SRC/newlib-3.1.0/COPYING
mkdir -p $PREFIX
touch $PREFIX/foo.$$
rm $PREFIX/foo.$$
# Don't bother testing writability of $PWD, the first line of step 3 will do that.
test ! -e binutils-2.32-bin
test ! -e gcc-8.3.0-boot
test ! -e newlib-3.1.0-bin
test ! -e gcc-8.3.0-bin
#
# 3. Build binutils
#
mkdir binutils-2.32-bin
cd    binutils-2.32-bin
$SRC/binutils-2.32/configure --target=$TARGET --prefix=$PREFIX --with-arch=rv32gc
make $MAKE_J
make install
cd ..
#
# 4. Build bootstrap GCC
#
mkdir gcc-8.3.0-boot
cd    gcc-8.3.0-boot
$SRC/gcc-8.3.0/configure --target=$TARGET --prefix=$PREFIX --with-arch=rv32gc --without-headers --with-newlib --with-gnu-as --with-gnu-ld
make $MAKE_J all-gcc
make install-gcc
cd ..
#
# 5. Build newlib
#
mkdir newlib-3.1.0-bin
cd    newlib-3.1.0-bin
$SRC/newlib-3.1.0/configure --target=$TARGET --prefix=$PREFIX
make $MAKE_J all
make install
cd ..
#
# 6. Build GCC again with newlib
#
mkdir gcc-8.3.0-bin
cd    gcc-8.3.0-bin
$SRC/gcc-8.3.0/configure --target=$TARGET --prefix=$PREFIX --with-arch=rv32gc --with-newlib --with-gnu-as --with-gnu-ld --disable-shared --disable-libssp
make $MAKE_J all
make install
# overwrites bootstrap binaries
cd ..
#
# 7. GDB with PSIM
#
# TBD
