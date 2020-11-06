#!/bin/bash

set -e
cd $(dirname $0)
. ../common/functions

rm -rf $(tc_prefix $(tc_hosttype))

./install.sh i686-linux
./install.sh x86_64-linux
./install.sh x86_64-linux5.0
