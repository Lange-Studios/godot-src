#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

eval "$("$dir/../../godot/godot-env.sh")"

# The GODOT4_BIN env var is used by gdext to generate bindings between gdext rust and godot
if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    export GODOT4_BIN="$GODOT_SRC_GODOT_DIR/bin/godot.linuxbsd.editor.double.x86_64.mono"
elif [[ "$OSTYPE" == "darwin"* ]]
then
        echo "ERROR: MacOS not supported yet!"
        exit 1
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    export GODOT4_BIN="$GODOT_SRC_GODOT_DIR/bin/godot.windows.editor.double.x86_64.mono.exe"
else
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

echo "bin is: $GODOT4_BIN"

"$dir/hello_world_rust-godot/rust/gdext-install.sh"
cd "$dir/hello_world_rust-godot/rust/lib"
cargo build --target x86_64-unknown-linux-gnu

"$dir/../../godot/godot-export-linux.sh" --debug --project "$dir/hello_world_rust-godot" --output "$dir/../gitignore/hello_world_rust/bin/linux/debug/hello_world_rust.x86_64"