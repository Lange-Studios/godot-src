#!/bin/bash

set -e

# The absolute directory this script is stored in.  That way it can be invoked from anywhere without
# having to worry about the PWD env var
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
eval "$("$dir/zig-env.sh")"
# Reassign because it may (likely) have been overwritten by the sourced . export above
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

root_dir="$dir/.."
version="${ZIG_VERSION:="$(cat "$root_dir/config/zig-version.txt")"}"
zip="zig-$version.xz"

if [[ "$IS_CUSTOM_ZIG" == "true" ]]
then
    exit 0
fi

# If zig is already instealled, no need to continue
if "$dir/zig" version
then
    exit 0
fi

# clear the dir in case it is corrupt
rm -rf "$ZIG_DIR"
mkdir -p "$ZIG_DIR"

zig_parent_dir="$ZIG_DIR/.."

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    url=https://ziglang.org/builds/zig-linux-x86_64-$version.tar.xz
    zip="zig-linux-x86_64-$version.zip"

    if wget --version
    then
        wget "$url" -O "$zig_parent_dir/$zip"
    elif curl --version
    then
        curl "$url" -o "$zig_parent_dir/$zip"
    else
        # TODO: Prompt a user to manually download from a url instead and then continue
        echo "ERROR: wget or curl must be installed"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]
then
    # TODO
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    # TODO
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
else
    # TODO?  Free BSD?  Redux?  Chrome OS?  Idk could be fun :)
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

tar -xvf "$zig_parent_dir/$zip" -C "$zig_parent_dir"

if ! "$dir/zig" version
then
    echo "failed to install zig version: $version"
    exit 1
fi