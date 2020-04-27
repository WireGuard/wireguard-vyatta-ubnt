#!/bin/bash -ex

# FROM: https://github.com/Lochnair/dockerfiles/tree/musl-buildenv

BUILD_ROOT="/usr/src/build"
SRC_ROOT="/usr/src/sources"

# Download source archives
mkdir -p $BUILD_ROOT/binutils $BUILD_ROOT/gcc $BUILD_ROOT/musl $SRC_ROOT
cd /usr/src
wget -nv \
	http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.xz \
	http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-$GCC_VER.tar.xz \
	http://ftp.gnu.org/gnu/gmp/gmp-$GMP_VER.tar.xz \
	http://isl.gforge.inria.fr/isl-$ISL_VER.tar.xz \
	https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VER.tar.xz \
	http://ftp.gnu.org/gnu/mpc/mpc-$MPC_VER.tar.gz \
	http://ftp.gnu.org/gnu/mpfr/mpfr-$MPFR_VER.tar.xz \
	https://www.musl-libc.org/releases/musl-$MUSL_VER.tar.gz


# Extract source archives
cd $SRC_ROOT
for file in ../*.tar.*; do tar xf "$file"; done

# Create symlinks to GCC dependencies
cd $SRC_ROOT/gcc-$GCC_VER
ln -s ../gmp-$GMP_VER gmp
ln -s ../isl-$ISL_VER isl
ln -s ../mpc-$MPC_VER mpc
ln -s ../mpfr-$MPFR_VER mpfr

# Kernel headers
cd $SRC_ROOT/linux-$KERNEL_VER
make ARCH=mips INSTALL_HDR_PATH=/opt/cross/$TARGET/ headers_install

# Binutils
cd $BUILD_ROOT/binutils
$SRC_ROOT/binutils-$BINUTILS_VER/configure --prefix=/opt/cross --target=$TARGET --disable-multilib --disable-werror
make -j$(nproc)
make install

# GCC - stage 1
cd $BUILD_ROOT/gcc
$SRC_ROOT/gcc-$GCC_VER/configure --prefix=/opt/cross --target=$TARGET --disable-multilib --disable-sim --enable-languages=c,c++ --with-abi=32 --with-mips-plt
make -j$(nproc) all-gcc
make install-gcc

# musl - stage 1
cd $BUILD_ROOT/musl
$SRC_ROOT/musl-$MUSL_VER/configure --prefix=/opt/cross/$TARGET/ --host=$TARGET
make obj/crt/crt1.o
make obj/crt/mips/crti.o
make obj/crt/mips/crtn.o
install obj/crt/crt1.o /opt/cross/$TARGET/lib
install obj/crt/mips/* /opt/cross/$TARGET/lib
$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o /opt/cross/$TARGET/lib/libc.so
make install-headers

# GCC - stage 2
cd $BUILD_ROOT/gcc
make -j$(nproc) all-target-libgcc
make install-target-libgcc

# musl - stage 2
cd $BUILD_ROOT/musl
$SRC_ROOT/musl-$MUSL_VER/configure --prefix=/opt/cross/$TARGET/ --host=$TARGET
make -j$(nproc)
make install

# GCC - stage 3
cd $BUILD_ROOT/gcc
make -j$(nproc)
make install
cd /root

# Cleanup
rm -rf /usr/src
