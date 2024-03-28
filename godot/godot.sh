#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

# Get the godot env vars.
eval "$("$dir/godot-env.sh")"

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    godot_exe="$GODOT_CROSS_GODOT_DIR/bin/godot.linuxbsd.editor.double.x86_64.mono"
elif [[ "$OSTYPE" == "darwin"* ]]
then
        echo "ERROR: MacOS not supported yet!"
        exit 1
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    godot_exe="$GODOT_CROSS_GODOT_DIR/bin/godot.windows.editor.double.x86_64.mono.exe"
else
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

$godot_exe "$@"