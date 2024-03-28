#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

eval "$("$dir/../../godot/godot-env.sh")"

# The GODOT4_BIN env var is used by gdext to generate bindings between gdext rust and godot
if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    export GODOT4_BIN="$GODOT_CROSS_GODOT_DIR/bin/godot.linuxbsd.editor.double.x86_64.mono"
elif [[ "$OSTYPE" == "darwin"* ]]
then
        echo "ERROR: MacOS not supported yet!"
        exit 1
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    export GODOT4_BIN="$GODOT_CROSS_GODOT_DIR/bin/godot.windows.editor.double.x86_64.mono.exe"
else
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

echo "bin is: $GODOT4_BIN"

"$dir/hello_world_rust-godot/rust/gdext-install.sh"
cd "$dir/hello_world_rust-godot/rust/lib"
# This is for bindgen's clang-sys dependency. 
# Docs here: https://github.com/KyleMayes/clang-sys?tab=readme-ov-file#environment-variables
export CLANG_PATH="$root_dir/other/zig/llvm/clang"
# For some reason targeting windows-gnu results in godot not being able to load the rust dll at runtime
# PATH="$MINGW_PREFIX/bin-rust:$PATH" cargo build --target=x86_64-pc-windows-gnu -p blockyball-godot-rust $cargo_target_arg
# Here we use xwin to target msvc.  But I'm wondering if we can use zig and spoof the link.exe as well.
#
# This is for xwin
cargo xwin build --target=x86_64-pc-windows-msvc

"$dir/../../godot/godot-export-windows.sh" --debug --project "$dir/hello_world_rust-godot" --output "$dir/../gitignore/hello_world_rust/bin/windows/debug/hello_world_rust.exe"