#!/bin/bash

# chroot-build.sh
# Helper bash script to initialize Ubuntu chroot systems to then execute an inner script that will go about
# building a piece of software within the context of the chroot.
#
# Copyright (c) 2016 Robert MacGregor
# This software is licensed under the MIT license. See LICENSE.txt for more information.

if [ $# != 3 ]
then
  echo "Usage: $0 <xenial|trusty|lucid> <directory> <architecture=i386|amd64>"
  exit 1
fi

# Assign the parameters to friendly names
distribution=$1
directory=$2
architecture=$3
created=0

# Only setup the chroot directory if it doesn't exist
if [ ! -d $2 ]
then
  echo "Setting up chroot directory ..."
  created=1

  mkdir $2
  sudo debootstrap --variant=buildd --arch $architecture $distribution $directory http://ubuntu.cs.utah.edu/ubuntu/

  if [ $! != 0 ]
  then
    echo "Failed to bootstrap chroot."
    exit 2
  fi

  # Ensure that the package lists are good
  echo "deb http://archive.ubuntu.com/ubuntu/ $distribution main restricted universe multiverse" | sudo tee -a "$directory/etc/apt/sources.list"
  echo "deb http://archive.ubuntu.com/ubuntu/ $distribution-security main restricted universe multiverse" | sudo tee -a "$directory/etc/apt/sources.list"
  echo "deb http://archive.ubuntu.com/ubuntu/ $distribution-updates main restricted universe multiverse" | sudo tee -a "$directory/etc/apt/sources.list"
  echo "deb http://archive.ubuntu.com/ubuntu/ $distribution-proposed main restricted universe multiverse" | sudo tee -a "$directory/etc/apt/sources.list"
  echo "deb http://archive.ubuntu.com/ubuntu/ $distribution-backports main restricted universe multiverse" | sudo tee -a "$directory/etc/apt/sources.list"

  if [ $! != 0 ]
  then
      echo "Failed to initialize default package lists."
      exit 3
  fi
fi

# Setup the chroot to use the native system /proc and resolv.conf
sudo mount -o bind /proc "$directory/proc"
sudo cp /etc/resolv.conf "$directory/etc/resolv.conf"

# Ensure the chroot can see our inner script and enable the chroot, telling it to execute the inner script so we can continue.
echo "Entering chroot."
sudo cp chroot-execute.sh "$directory"
sudo chmod +x "$directory/chroot-execute.sh"
sudo chroot $directory ./chroot-execute.sh $distribution $created

if [ ! $! == 0 ]
then
  echo "Failed to chroot."
  exit 2
fi
