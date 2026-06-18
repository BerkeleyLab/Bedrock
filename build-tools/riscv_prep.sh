# See riscv_meta.sh for documentation
# Should be run from an empty directory into which we have write privileges
# Will create ref and src directories there
# Pro tip: first apt-get install wget
set -e

# Get upstream stable sources
mkdir ref
cd ref
wget --no-verbose https://mirrors.kernel.org/gnu/binutils/binutils-2.32.tar.xz
wget --no-verbose https://bigsearcher.com/mirrors/gcc/releases/gcc-8.3.0/gcc-8.3.0.tar.xz
wget --no-verbose ftp://sourceware.org/pub/newlib/newlib-3.1.0.tar.gz

# Check file integrity
sha256sum -c << EOT
0ab6c55dd86a92ed561972ba15b9b70a8b9f75557f896446c82e8b36e473ee04  binutils-2.32.tar.xz
64baadfe6cc0f4947a84cb12d7f0dfaf45bb58b7e92461639596c21e02d97d2c  gcc-8.3.0.tar.xz
fb4fa1cc21e9060719208300a61420e4089d6de6ef59cf533b57fe74801d102a  newlib-3.1.0.tar.gz
EOT

# unpack
cd ..
mkdir src
cd src
tar -xaf ../ref/binutils-2.32.tar.xz
tar -xaf ../ref/gcc-8.3.0.tar.xz
tar -xaf ../ref/newlib-3.1.0.tar.gz
echo DONE
