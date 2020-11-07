#!/bin/bash

set -ex
cd $(dirname $0)
. ../common/functions

TARGET=$(tc_target $1)
SRCDIR=$(pwd)

case $TARGET in
i686-linux)
   $SRCDIR/build.sh i686-linux
   $SRCDIR/build.sh x86_64-linux
   ;;
x86_64-linux)
   $SRCDIR/build.sh x86_64-linux
   ;;
esac

