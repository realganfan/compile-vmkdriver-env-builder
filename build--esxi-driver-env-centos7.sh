#!/bin/bash

chmod 755 ./src/binutils-2.22/*.sh ./src/gcc-4.8.0/*.sh ./src/glibc-2.3.4-2.41/*.sh ./src/common/brp*
yum -y groupinstall 'Development Tools'
yum -y install ncurses-devel
yum -y install wget

rm -rf /build/toolchain/*
mkdir -p /build/toolchain/src

CURDIR=$(pwd)
cp -r ./src/* /build/toolchain/src


cd /build/toolchain/src
rpm -i texinfo-4.13a-8.el6.x86_64.rpm

cd glibc-2.3.4-2.41
./install.sh
cd ..

cd binutils-2.22
./install.sh
cd ..

cd gcc-4.8.0
wget https://ftp.gnu.org/gnu/gcc/gcc-4.8.0/gcc-4.8.0.tar.gz
./install.sh
cd ..

cd $CURDIR

cp -r ./vmkdrivers-gpl /build/
cd /build/vmkdrivers-gpl
tar xf vmkdrivers-gpl.tgz
cd $CURDIR

echo
echo -e "\e[1m\e[32m**************************************************************************"
echo -e " Build completed,please comfirm your /build/toolchain/lin64 has 3 subfolders.                         "
echo -e " Remember changing your build-xxxx.sh: "
echo -e "    binutil version: 	2.22"
echo -e "    gcc version: 		4.8.0"
echo -e "    glibc version: 	2.3.4-2.41"
echo -e "**************************************************************************\e[0m"
