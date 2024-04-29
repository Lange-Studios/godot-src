#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

if "$GODOT_SRC_NU_DIR/nu" --version > /dev/null 2>&1
then
    exit 0
fi

zip="nu-$GODOT_SRC_NU_VERSION-$GODOT_SRC_NU_ARCH-$GODOT_SRC_NU_PLATFORM.$GODOT_SRC_NU_ZIP_EXT"
url=https://github.com/nushell/nushell/releases/download/$GODOT_SRC_NU_VERSION/$zip
"$dir/../utils/http.sh" "$url" "$GODOT_SRC_NU_DIR/../$zip"

if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]
then
    tar -xvf "$GODOT_SRC_NU_DIR/../$zip" -C "$GODOT_SRC_NU_DIR/../"
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    unzip "$GODOT_SRC_NU_DIR/../$zip" -d "$GODOT_SRC_NU_DIR/"
else
    # TODO?  Free BSD?  Redux?  Chrome OS?  Idk could be fun :)
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

"$GODOT_SRC_NU_DIR/nu" --version