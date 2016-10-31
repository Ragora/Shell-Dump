#!/bin/bash

# chroot-execute.sh
# Inner execution script for the chroot-build.sh script. Currently, this only builds OpenTESArena.
#
# Copyright (c) 2016 Robert MacGregor
# This software is licensed under the MIT license. See LICENSE.txt for more information.

created=$2
distribution=$1

# For now, we just do everything in /tmp
cd /tmp

# Install required packages as well as upgrade everything
apt-get -y update
apt-get -y upgrade
apt-get -y install git wget libx11-dev mesa-common-dev libglu1-mesa-dev libxrandr-dev cmake wget libopenal-dev opencl-headers ocl-icd-libopencl1 nano software-properties-common sudo

# If we're using trusty, we need to use GCC 4.9 for std::regex concerns
if [[ $distribution == "trusty" && $created == 1 ]]
then
  # Pull down GCC 4.9 and force the system to use it
  add-apt-repository -y ppa:ubuntu-toolchain-r/test
  apt-get -y update
  apt-get -y install gcc-4.9 g++-4.9
  update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.9
fi

# Make sure the cl2.hpp is installed
if [ ! -f /usr/include/CL/cl2.hpp ]
then
    wget https://github.com/KhronosGroup/OpenCL-CLHPP/releases/download/v2.0.10/cl2.hpp
    mv cl2.hpp /usr/include/CL/
fi

# Build and install wildmidi
if [ ! -d /tmp/wildmidi-0.4.0 ]
then
  cd /tmp
  wget https://github.com/Mindwerks/wildmidi/archive/wildmidi-0.4.0.tar.gz
  tar -xvf wildmidi-0.4.0.tar.gz
  cd wildmidi-wildmidi-0.4.0
  mkdir out
  cd out
  cmake .. -DCMAKE_BUILD_TYPE=Release -DWANT_STATIC=1
  make -j32
  make install
fi

# Build and install SDL
if [ ! -d /tmp/SDL2-2.0.5 ]
then
  cd /tmp
  wget https://www.libsdl.org/release/SDL2-2.0.5.tar.gz
  tar -xvf SDL2-2.0.5.tar.gz
  cd SDL2-2.0.5
  mkdir out
  cd out
  cmake .. -DCMAKE_BUILD_TYPE=Release
  make -j32
  make install
fi

# GIT clone TESArena if it doesn't already exist
if [ ! -d /tmp/OpenTESArena ]
then
  cd /tmp
  git clone https://github.com/afritz1/OpenTESArena.git
  cd OpenTESArena
  cmake . -DCMAKE_BUILD_TYPE=Release
  make -j32
else
  cd /tmp/OpenTESArena
  git pull origin
  make -j32
fi

# Cleanup
cd /tmp
rm *.tar.gz
