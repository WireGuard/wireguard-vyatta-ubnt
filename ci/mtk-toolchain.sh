#!/bin/bash -ex
# Based on work by github.com/Lochnair

BUILD_ROOT="/usr/src/build"
SRC_ROOT="/usr/src/sources"

# Download source archives
mkdir -p $BUILD_ROOT/binutils $BUILD_ROOT/gcc $SRC_ROOT
cd /usr/src
wget -nv \
	http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.xz \
	http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-$GCC_VER.tar.bz2 \
	http://ftp.gnu.org/gnu/gmp/gmp-$GMP_VER.tar.xz \
	http://isl.gforge.inria.fr/isl-$ISL_VER.tar.xz \
	http://ftp.gnu.org/gnu/mpc/mpc-$MPC_VER.tar.gz \
	http://ftp.gnu.org/gnu/mpfr/mpfr-$MPFR_VER.tar.xz

# Extract source archives
cd $SRC_ROOT
for file in ../*.tar.*; do tar xf "$file"; done

# Create symlinks to GCC dependencies
cd $SRC_ROOT/gcc-$GCC_VER
ln -s ../gmp-$GMP_VER gmp
ln -s ../isl-$ISL_VER isl
ln -s ../mpc-$MPC_VER mpc
ln -s ../mpfr-$MPFR_VER mpfr

# Fix issue with newer versions of makeinfo
wget -q -O- https://trac.macports.org/raw-attachment/ticket/53076/patch-gcc48-texi.diff | patch -p1

# Binutils
cd $BUILD_ROOT/binutils
$SRC_ROOT/binutils-$BINUTILS_VER/configure --prefix=/opt/cross --target=$TARGET --disable-multilib --disable-werror
make -j$(nproc)
make install

# GCC - stage 1
cd $BUILD_ROOT/gcc
$SRC_ROOT/gcc-$GCC_VER/configure --prefix=/opt/cross --target=$TARGET --disable-fixed-point --disable-multilib --disable-sim --enable-languages=c --with-abi=32 --with-float=soft --with-mips-plt
make -j$(nproc) all-gcc
make install-gcc

cd /root

# Cleanup
rm -rf /usr/src
