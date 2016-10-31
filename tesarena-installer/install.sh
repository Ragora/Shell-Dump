#!/bin/bash

# install.sh
# A bash script to automatically download and build OpenTESArena for your Linux box. This is useful for quickly getting a development
# environment up and running or for Linux distributions that do not have OpenTESArena available through official repositories.
#
# Copyright (c) 2016 Robert MacGregor
# This software is licensed under the MIT license. See LICENSE.txt for more information.

if [ $# != 1 ]
then
    echo "This is an auto install program for OpenTESArena on Linux. This script will attempt to automatically setup and build OpenTESArena for your system if it is not provided officially."
    echo "Usage: $0 <generic|vendor> [job count = cores*2]"
    echo "If generic is specified, the generic OpenCL ICD will be installed. If vendor is specified, the script will attempt to find the appropriate ICD package for your system."
    exit 1
fi

echo "WARNING: Please be sure to review what packages will be installed to ensure that no unintended side effects occur as a result of running this script."
echo "Press enter to continue."
read

# Installation process for an Nvidia ICD
install_nvidia ()
{
    echo "Attempting to install for NVidia..."
    version="$(glxinfo | grep 'OpenGL core profile version string:' | awk '{print $8}' | awk -F '.' '{print $1}')"

    echo "Installing ICD for NVidia driver ${version}"
    sudo apt-get install nvidia-libopencl1-$version

    # If there isn't a package available or we otherwise screwed up
    if [ $? != 0 ]
    then
        echo "Failed to install NVidia ICD package."
        echo "This either means there is no ICD for your driver version or the script has a bug."
        exit 2
    fi
}

# Automatically determine the vendor and call the appropriate subroutine
determine_vendor()
{
    # Check for a Nvidia card and attempt to install the appropriate ICD.
    glxinfo | grep NVIDIA > /dev/null
    if [ $? == 0 ]
    then
        install_nvidia
    fi

    # TODO: Checks and subroutines for other vendors.

    # Couldn't determine vendor, exit.
    if [ $? != 0 ]
    then
        echo "Could not determine the vendor for your system. This is probably a script bug."
        exit 3
    fi
}

# Switch on if we want to install the generic ICD or grab a vendor specific one
if [ $1 == "generic" ]
then
    sudo apt-get install ocl-icd-libopencl1

    if [ $? != 0 ]
    then
        echo "Failed to install generic ICD package. Either the package is not available for your system or the script has a bug."
        exit 4
    fi
else
    determine_vendor
fi

# Install prerequisites
sudo apt-get install build-essential git libopenal-dev opencl-headers wildmidi libwildmidi-dev libsdl2-dev
wget https://github.com/KhronosGroup/OpenCL-CLHPP/releases/download/v2.0.10/cl2.hpp
sudo mv cl2.hpp /usr/include/CL/

# Download OpenTESArena via GIT and build it
git clone https://github.com/afritz1/OpenTESArena.git

if [ $? != 0 ]
then
    echo "Failed to GIT clone OpenTESArena. Does the folder already exist?"
    exit 5
fi

cd OpenTESArena
cmake .

# Determine core count
get_job_count()
{
    if [ $# == 2 ]
    then
        jobs="$2"
    else
        cores="$(cat /proc/cpuinfo | grep 'processor' | wc -l)"

        if [ $? != 0 ]
        then
            jobs="1"
            echo "Failed to determine processor core count. Not specifying the job count."
        else
            jobs=$(($cores * 2))
        fi
    fi

    echo "Building using $jobs jobs"
}

get_job_count

# Green for go
make "-j$jobs"
