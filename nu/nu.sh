#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

cpu_arch="$(arch)"

if [[ "$cpu_arch" == "arm64" ]]
then
    cpu_arch="aarch64"
fi

export GODOT_SRC_NU_VERSION=${GODOT_SRC_NU_VERSION:="0.92.2"}
export GODOT_SRC_NU_ARCH=${GODOT_SRC_NU_ARCH:="$cpu_arch"}

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    export GODOT_SRC_NU_PLATFORM=${GODOT_SRC_NU_PLATFORM:="unknown-linux-musl"}
    export GODOT_SRC_NU_ZIP_EXT="tar.gz"
elif [[ "$OSTYPE" == "darwin"* ]]
then
    export GODOT_SRC_NU_PLATFORM=${GODOT_SRC_NU_PLATFORM:="apple-darwin"}
    export GODOT_SRC_NU_ZIP_EXT="tar.gz"
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    export GODOT_SRC_NU_PLATFORM=${GODOT_SRC_NU_PLATFORM:="pc-windows-msvc"}
    export GODOT_SRC_NU_ZIP_EXT="zip"
else
    # TODO?  Free BSD?  Redux?  Chrome OS?  Idk could be fun :)
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

export GODOT_SRC_NU_DIR=${GODOT_SRC_NU_DIR:="$dir/../gitignore/nu/nu-$GODOT_SRC_NU_VERSION-$GODOT_SRC_NU_ARCH-$GODOT_SRC_NU_PLATFORM"}

"$dir/nu-install.sh"

"$GODOT_SRC_NU_DIR/nu" "$@"