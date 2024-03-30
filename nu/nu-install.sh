#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

eval "$("$dir/nu-env.sh")"

if "$GODOT_CROSS_NU_DIR/nu" --version > /dev/null 2>&1
then
    exit 0
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    zip=nu-$GODOT_CROSS_NU_VERSION-$(arch)-unknown-linux-musl.tar.gz
    url=https://github.com/nushell/nushell/releases/download/$GODOT_CROSS_NU_VERSION/$zip
    "$dir/../utils/http.sh" "$url" "$GODOT_CROSS_NU_DIR/../$zip"
    tar -xvf "$GODOT_CROSS_NU_DIR/../$zip" -C "$GODOT_CROSS_NU_DIR/../"
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

"$GODOT_CROSS_NU_DIR/nu" --version