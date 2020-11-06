#!/bin/bash

# Usage: ./install.sh [target]
#
# Examples:
#
#   ./install.sh i686-linux		# cross build for i686-linux
#   ./install.sh x86_64-linux		# cross build for x86_64-linux

set -ex
cd $(dirname $0)
. ../common/functions

NAME=gcc
VERSION=4.8.0
TARGET=$(tc_target $1)
#gcc prerequisites
GMP_VERSION=5.0.5
MPFR_VERSION=3.0.1
MPC_VERSION=1.0.1

PREFIX=$(tc_prefix $(tc_hosttype))	# Prefix for host (not target) platform
export PATH=$(tc_path $(tc_hosttype))
DESTDIR=/var/tmp/$NAME-$VERSION
BUILDDIR=build-$TARGET
export BUVER=2.22
BINUTILS=$(tc_hostroot)/binutils-$BUVER

tc_extract
# Extract gmp and move to gcc src directory
tar -xjf gmp-$GMP_VERSION.tar.bz2
mv gmp-$GMP_VERSION  $NAME-$VERSION/gmp

# Extract mpfr and move to gcc src directory
tar -xzf mpfr-$MPFR_VERSION.tar.gz
mv mpfr-$MPFR_VERSION  $NAME-$VERSION/mpfr

# Extract mpc and move to gcc src directory
tar -xzf mpc-$MPC_VERSION.tar.gz
mv mpc-$MPC_VERSION  $NAME-$VERSION/mpc

# Tell collect2 not to search for gnm and gstrip to prevent leak to /usr
tc_patch gcc-collect2.patch
# Tell gcc not to look under /usr/local/include for header files
tc_patch gcc-localinclude.patch
tc_patch gcc-asan.patch
tc_patch smallhigh.patch

case $TARGET in
i686-linux)
   CONFIG_OPTS="--enable-__cxa_atexit \
                --with-sysroot=$TROOT/lin32/glibc-2.3.4-2.41/ \
		--without-libelf \
                --enable-clocale=gnu"
   ;;  
x86_64-linux)
   CONFIG_OPTS="--enable-__cxa_atexit \
                --with-sysroot=$TROOT/lin64/glibc-2.3.4-2.41/ \
		--without-libelf \
                --enable-clocale=gnu"
   ;;
esac

rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $BUILDDIR

export PATH=$BINUTILS/bin:$PATH
../gcc-$VERSION/configure		\
   --prefix=$PREFIX			\
   --disable-nls			\
   --enable-shared			\
   --enable-threads=posix		\
   --enable-languages=c,c++		\
   --with-gnu-as			\
   --with-gnu-ld			\
   --target=$TARGET			\
   --with-as=$BINUTILS/bin/$TARGET-as	\
   --with-ld=$BINUTILS/bin/$TARGET-ld	\
   $CONFIG_OPTS

make -j8 all

# As gcc for different targets share the same install tree we can't
# do "rm -rf $PREFIX". For native builds we do full install. For cross
# builds we install only the target-specific files.

if [ "$TARGET" = $(tc_hosttype) ]; then
   make install
   find $PREFIX -type f -name \*.so.\* | xargs chmod 755
   find $PREFIX -name \*.la | xargs rm
   rm -f $PREFIX/bin/$TARGET-{gcc-$VERSION,c++,$TARGET-*}

   TARGET=$TARGET $COMMONDIR/brp-vmware $PREFIX/{bin,lib,libexec}
else
   rm -rf $DESTDIR
   make install DESTDIR=$DESTDIR
   pushd $DESTDIR/$PREFIX
   find . -type f -name \*.so.\* -exec chmod 755 '{}' \;
   find . -name \*.la | xargs rm
   rm -f bin/$TARGET-{gcc-$VERSION,c++}
   TARGET=$(tc_hosttype) $COMMONDIR/brp-vmware bin libexec/gcc/$TARGET
   TARGET=$TARGET $COMMONDIR/brp-vmware lib/gcc/$TARGET $TARGET
   mkdir -p $PREFIX || :
   rm -rf $PREFIX/{bin/$TARGET-*,include/c++/$VERSION/$TARGET,lib/gcc/$TARGET,libexec/gcc/$TARGET,$TARGET}
   cp -a --parents bin/$TARGET-* \
      lib/gcc/$TARGET libexec/gcc/$TARGET $TARGET $PREFIX
   popd
fi

# GCC follows a certain search order to look for things provided by binutils
# such as "as", "ld", "nm", etc. By adding the links below we ensure that
# GCC find the correct tool we desire no matter what PATH is set to.

mkdir -p $PREFIX/$TARGET || :
ln -s $BINUTILS/$TARGET/bin $PREFIX/$TARGET
pushd $PREFIX/libexec/gcc/$TARGET/$VERSION
ln -s ../../../../$TARGET/bin/* .
popd

