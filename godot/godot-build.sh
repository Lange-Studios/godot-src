#!/bin/bash

set -e

prev_pwd="$PWD"
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/.."
eval "$("$dir/zig/zig-env.sh")"
"$root_dir/zig/zig-install.sh"

# Get the godot env vars.
eval "$("$dir/godot-env.sh")"

# Test that the godot source code exists.  If not, we will clone it in this folder
if ! test -f "$GODOT_DIR/LICENSE.txt"
then
    git clone --depth 1 https://github.com/godotengine/godot.git "$GODOT_DIR"
fi

cc="$root_dir/zig/zig cc"
cxx="$root_dir/zig/zig c++"

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    platform="linuxbsd"
elif [[ "$OSTYPE" == "darwin"* ]]
then
        echo "ERROR: MacOS not supported yet!"
        exit 1
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    platform="windows"
else
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

cd "$GODOT_DIR"

# TODO: Allow users to pass custom scons commands
scons \
    platform="$platform" \
    debug_symbols=yes \
    module_mono_enabled=yes \
    compiledb=yes \
    precision=double \
    import_env_vars=ZIG_GLOBAL_CACHE_DIR,ZIG_LOCAL_CACHE_DIR \
    CC="$cc" \
    CXX="$cxx"

# TODO: Pass custom commands for cs development as well... or maybe move this to a seperate script
if [[ "$1" != "--skip-cs" ]]
then
    "$dir/godot-clean-dotnet.sh"
    # The directory where godot will be built out to
    mkdir -p "$GODOT_DIR/bin/"
    # This folder needs to exist in order for the nuget packages to be output here
    mkdir -p "$GODOT_DIR/bin/GodotSharp/Tools/nupkgs"
    "$dir/godot.sh" --headless --generate-mono-glue "$GODOT_DIR/modules/mono/glue" --precision=double
    "$GODOT_DIR/modules/mono/build_scripts/build_assemblies.py" \
        --godot-output-dir="$GODOT_DIR/bin" \
        --precision=double \
        --godot-platform="$platform"
fi

cd "$prev_pwd"