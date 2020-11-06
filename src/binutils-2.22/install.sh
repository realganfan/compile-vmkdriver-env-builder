#!/bin/bash

# Usage: ./install.sh [target]
#
# Examples:
#
#   ./install.sh i686-linux		# cross  build for i686-linux
#   ./install.sh x86_64-linux		# cross  build for x86_64-linux

set -ex
cd $(dirname $0)
. ../common/functions

NAME=binutils
VERSION=2.22
TARGET=$(tc_target $1)

PREFIX=$(tc_prefix $(tc_hosttype))	# Prefix for host (not target) platform
export PATH=$(tc_path $(tc_hosttype))
DESTDIR=/var/tmp/$NAME-$VERSION
BUILDDIR=build-$TARGET

case $TARGET in
i686-linux)           CONFIG_OPTS="--with-sysroot=$TROOT/lin32/glibc-2.2.5-44";;
x86_64-linux)         CONFIG_OPTS="--with-sysroot=$TROOT/lin64/glibc-2.3.4-2.41 --enable-64-bit-bfd";;
i686-linux5.0)        CONFIG_OPTS="--with-sysroot=$TROOT/lin32/RHEL5";;
x86_64-linux5.0)      CONFIG_OPTS="--with-sysroot=$TROOT/lin64/glibc-2.3.4-2.41 --enable-64-bit-bfd";;
*) echo "$TARGET not implemented"
   exit;;
esac

BUILD_USING_BINUTILS=2.16.1
BUILD_USING_GCC=4.1.2

tc_extract

rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $BUILDDIR

../$NAME-$VERSION/configure \
   --prefix=$PREFIX \
   --disable-nls \
   --target=$TARGET \
   --disable-werror \
   $CONFIG_OPTS
   
make

# As binutils for different targets share the same install tree we can't
# do "rm -rf $PREFIX". We do full install only for lin32 target. For all
# other targets we install only the target-specific files.

if [ $TARGET = $(tc_hosttype) ]; then
   make install
   find $PREFIX/lib -name \*.la -exec rm {} \;
else
   rm -rf $DESTDIR
   make install DESTDIR=$DESTDIR
   mkdir -p $PREFIX || :
   rm -rf $PREFIX/{bin/$TARGET-*,$TARGET}
   cp -a $DESTDIR/$PREFIX/{bin,$TARGET} $PREFIX
fi

TARGET=$(tc_hosttype)

# "ld" for x86_64 looks for ld-linux-x86-64.so.2 (for -m64) or ld-linux.so.2
# (for -m32) here so we have to copy them from extracted glibc directory.
# This step must be performed before we can even build gcc for x86_64,
# otherwise the configure script for libstdc++ would fail when testing
# whether xgcc can be used to compile and link an executable.

case $TARGET in
x86_64-linux)
   cp -p $TROOT/lin64/glibc-2.3.4-2.41/{lib/ld-linux.so.2,lib64/ld-linux-x86-64.so.2} $PREFIX/$TARGET/lib
   ;;
esac
