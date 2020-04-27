#!/bin/bash -ex
# Based on work by github.com/Lochnair

BUILD_ROOT="/usr/src/build"
SRC_ROOT="/usr/src/sources"

# Download source archives
mkdir -p $BUILD_ROOT/binutils $BUILD_ROOT/gcc $SRC_ROOT
cd /usr/src
wget -nv \
	https://github.com/MarvellEmbeddedProcessors/Octeon-Toolchain/raw/master/toolchain-build-54.tar.bz2

# Extract source archives
cd $SRC_ROOT
tar -xvf ../toolchain-build-54.tar.bz2

# Move sources
mv -v toolchain/gits/binutils .
mv -v toolchain/gits/gcc .
mv -v toolchain/src/gmp .
mv -v toolchain/src/mpc .
mv -v toolchain/src/mpfr .

# Create symlinks to GCC dependencies
cd $SRC_ROOT/gcc
ln -s ../gmp gmp
ln -s ../isl isl
ln -s ../mpc mpc
ln -s ../mpfr mpfr

# Binutils
cd $BUILD_ROOT/binutils
$SRC_ROOT/binutils/configure --prefix=/opt/cross --target=mips64-octeon-linux --disable-multilib --disable-werror
make -j$(nproc)
make install

# GCC - stage 1
cd $BUILD_ROOT/gcc
MAKEINFO=missing $SRC_ROOT/gcc/configure --prefix=/opt/cross --target=mips64-octeon-linux --disable-fixed-point --disable-multilib --disable-sim --enable-languages=c --with-abi=64 --with-float=soft --with-mips-plt
make -j$(nproc) all-gcc
make install-gcc

cd /root

# Cleanup
rm -rf /usr/src
