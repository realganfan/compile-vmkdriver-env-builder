#!/bin/bash

# Usage: ./install-lin64.sh [target]
#
# Example:
# ./install-lin64.sh x86_64-linux		# build for x86_64-linux
# ./install-lin64.sh x86_64-linux5.0		# build for x86_64-linux5.0
#
# Running on lin64 build machine with gcc 4.1.2 and binutil-2.16.1
#

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
x86_64-linux)      CONFIG_OPTS="--with-sysroot=$TROOT/lin64/glibc-2.3.2-95.44 --enable-64-bit-bfd --enable-install-libbfd";;
x86_64-linux5.0)   CONFIG_OPTS="--with-sysroot=$TROOT/lin64/RHEL5 --enable-64-bit-bfd";;
*) echo "$TARGET not implemented"
   exit;;
esac

BUILD_USING_BINUTILS=2.16.1
BUILD_USING_GCC=4.1.2

# To ensure reproducibility, build with a fixed version of binutils/gcc.
if [ $(ld -v | sed -e 's/^GNU ld version \(.*\)$/\1/') != $BUILD_USING_BINUTILS ]; then
   echo "Must build with binutils version $BUILD_USING_VERSION."
   exit 1
fi
if [ $(gcc -dumpversion) != $BUILD_USING_GCC ]; then
   echo "Must build with gcc version $BUILD_USING_GCC."
   exit 1
fi

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
   
make CFLAGS="$CFLAGS -fPIC"

# As binutils for different targets share the same install tree we can't
# do "rm -rf $PREFIX". We do full install only for lin64 target. For all
# other targets we install only the target-specific files.

if [ $TARGET = "x86_64-linux" ]; then
  make install
  make target_header_dir=$PREFIX/include -C libiberty install_to_libdir
  mv $PREFIX/x86_64-unknown-linux-gnu/x86_64-linux/lib/* $PREFIX/lib64
  mv $PREFIX/x86_64-unknown-linux-gnu/x86_64-linux/include/* $PREFIX/include
  rm -rf $PREFIX/x86_64-unknown-linux-gnu
  find $PREFIX/lib -name \*.la -exec rm {} \;
  find $PREFIX/lib64 -name \*.la -exec rm {} \;
else
   rm -rf $DESTDIR
   make install DESTDIR=$DESTDIR
   mkdir -p $PREFIX || :
   rm -rf $PREFIX/{bin/$TARGET-*,$TARGET}
   cp -a $DESTDIR/$PREFIX/{bin,$TARGET} $PREFIX
fi

TARGET=$(tc_hosttype) $COMMONDIR/brp-vmware $PREFIX/{bin/$TARGET-*,$TARGET}

# "ld" for x86_64 looks for ld-linux-x86-64.so.2 (for -m64) or ld-linux.so.2
# (for -m32) here so we have to copy them from extracted glibc directory.
# This step must be performed before we can even build gcc for x86_64,
# otherwise the configure script for libstdc++ would fail when testing
# whether xgcc can be used to compile and link an executable.

case $TARGET in
x86_64-linux)
   SYSROOT=$TROOT/lin64/glibc-2.3.2-95.44
   cp -p $SYSROOT/{lib/ld-linux.so.2,lib64/ld-linux-x86-64.so.2} $PREFIX/$TARGET/lib
   ;;
esac
