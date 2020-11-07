#!/bin/bash

set -ex
cd $(dirname $0)
. ../common/functions

SRCDIR=$(pwd)
TARGET=$(tc_target $1)
PREFIX=$(tc_prefix $TARGET)

rm -rf $PREFIX
mkdir -p $PREFIX
pushd $PREFIX

case $TARGET in
i686-linux)
  for i in \
    glibc-2.3.4-2.41.i686.rpm \
    glibc-devel-2.3.4-2.41.i386.rpm \
    glibc-kernheaders-2.4-9.1.103.EL.i386.rpm \
    glibc-profile-2.3.4-2.41.i386.rpm \
    glibc-headers-2.3.4-2.41.i386.rpm; do 
    rpm2cpio $SRCDIR/$i | cpio -idm
  done
   # Fix absolute paths of libc.
   patch -p1 < $SRCDIR/glibc-2.3.4-2.41-i386.patch
  ;;
x86_64-linux)
  for i in \
    glibc-2.3.4-2.41.i686.rpm \
    glibc-devel-2.3.4-2.41.i386.rpm \
    glibc-2.3.4-2.41.x86_64.rpm \
    glibc-devel-2.3.4-2.41.x86_64.rpm \
    glibc-headers-2.3.4-2.41.x86_64.rpm \
    glibc-profile-2.3.4-2.41.x86_64.rpm \
    glibc-kernheaders-2.4-9.1.103.EL.x86_64.rpm; do
    rpm2cpio $SRCDIR/$i | cpio -idm
  done
  # Fix absolute paths of libc.
  patch -p1 < $SRCDIR/glibc-2.3.4-2.41-x86_64.patch
  ;;
esac

popd
