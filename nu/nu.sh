#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    export GODOT_SRC_NU_VERSION=${GODOT_SRC_NU_VERSION:="0.91.0"}
    export GODOT_SRC_NU_DIR=${GODOT_SRC_NU_DIR:="$dir/../gitignore/nu/nu-$GODOT_SRC_NU_VERSION-$(arch)-unknown-linux-musl"}
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

"$dir/nu-install.sh"

"$GODOT_SRC_NU_DIR/nu" "$@"