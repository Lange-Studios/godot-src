#!/bin/bash

url="$1"
out_file="$2"
out_dir="$(dirname "$out_file")"
mkdir -p "$out_dir"

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    if wget --version
    then
        wget "$url" -O "$out_file"
    elif curl --version
    then
        curl "$url" -o "$out_file"
    else
        # TODO: Prompt a user to manually download from a url instead and then continue
        echo "ERROR: wget or curl must be installed"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]
then
    if wget --version
    then
        wget "$url" -O "$out_file"
    elif curl --version
    then
        curl "$url" -o "$out_file"
    else
        # TODO: Prompt a user to manually download from a url instead and then continue
        echo "ERROR: wget or curl must be installed"
        exit 1
    fi
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    # TODO: Add support for the windows http cli
    if wget --version
    then
        wget "$url" -O "$out_file"
    elif curl --version
    then
        curl "$url" -o "$out_file"
    else
        # TODO: Prompt a user to manually download from a url instead and then continue
        echo "ERROR: wget or curl must be installed"
        exit 1
    fi
else
    # TODO?  Free BSD?  Redux?  Chrome OS?  Idk could be fun :)
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi