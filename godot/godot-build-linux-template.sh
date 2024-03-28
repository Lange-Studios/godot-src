#!/bin/bash

set -e

prev_pwd="$PWD"
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/.."
zig_dir="$root_dir/zig"
eval "$("$zig_dir/zig-env.sh")"
"$zig_dir/zig-install.sh"

# Get the godot env vars.
eval "$("$dir/godot-env.sh")"

cc="$zig_dir/zig cc"
cxx="$zig_dir/zig c++"

while test $# -gt 0
do
    case "$1" in
        --skip-cs) skip_cs=true
            ;;
        --release) target=release
            ;;
        --debug) target=debug
            ;;
        --custom-modules)
            shift
            custom_modules_arg="custom_modules="$1""
            ;;
        --help)
            echo "==================================================="
            echo "Template Help Message"
            echo ""
            echo "--help    - print a helpful message"
            echo "--skip-cs - don't generate the csharp sdk and glue"
            echo "--release - builds the release template"
            echo "--debug   - builds the debug template"
            echo "==================================================="
            exit 0
            ;;
        *)
            ;;
    esac
    shift
done

if [[ "$target" == "release" ]]
then
    lto_arg="lto=full"
    debug_symbols="no"
elif [[ "$target" == "debug" ]]
then
    lto_arg=""
    debug_symbols="yes"
else
    echo "no target arg was supplied. Must supply '--release' or '--debug'"
    exit 1
fi

if [[ "$skip_cs" != "true" ]]
then
    "$root_dir/godot/godot-clean-dotnet.sh"
    # The directory where godot will be built out to
    mkdir -p "$GODOT_CROSS_GODOT_DIR/bin/"
    # This folder needs to exist in order for the nuget packages to be output here
    mkdir -p "$GODOT_CROSS_GODOT_DIR/bin/GodotSharp/Tools/nupkgs"

    # We assume the godot editor is already built
    # TODO: Allow customizing these flags
    "$dir/godot.sh" \
        --headless \
        --generate-mono-glue \
        "$GODOT_CROSS_GODOT_DIR/modules/mono/glue" \
        --precision=double

    # TODO: Allow customizing these flags
    "$GODOT_CROSS_GODOT_DIR/modules/mono/build_scripts/build_assemblies.py" \
        --godot-output-dir="$GODOT_CROSS_GODOT_DIR/bin" \
        --precision=double \
        --godot-platform=linuxbsd
fi

cd "$GODOT_CROSS_GODOT_DIR"

scons \
    "$lto_arg" \
    platform=linuxbsd \
    target=template_$target \
    debug_symbols=$debug_symbols \
    module_mono_enabled=yes \
    compiledb=no \
    precision=double \
    import_env_vars="$GODOT_CROSS_IMPORT_ENV_VARS" \
    custom_modules="$GODOT_CROSS_CUSTOM_MODULES" \
    CC="$cc" \
    CXX="$cxx"

cd "$prev_pwd"

echo "Template build success!  Find your template at: $(realpath "$GODOT_CROSS_GODOT_DIR/bin")"