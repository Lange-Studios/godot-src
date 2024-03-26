#!/bin/bash

set -e

prev_pwd="$PWD"
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/.."
zig_dir="$root_dir/other/zig"
gitignore_dir="$root_dir/gitignore"
dxc_version_date="$(cat "$root_dir/config/dxc-version.txt")"
# dxc does versioning in format: version number / date
IFS='/' read -ra dxc_version_date_arr <<< "$dxc_version_date"
dxc_version="${dxc_version_date_arr[0]}"
dxc_date="${dxc_version_date_arr[1]}"
godot_nir_version="$(cat "$root_dir/config/godot-nir-version.txt")"
"$zig_dir/zig-install.sh"

# Get the godot env vars.
eval "$("$dir/godot-env.sh")"

# Spoof scons into thinking zig is mingw :)
export MINGW_PREFIX="$zig_dir/mingw"

cc="$zig_dir/zig cc -target x86_64-windows"
cxx="$zig_dir/zig c++ -target x86_64-windows"

while test $# -gt 0
do
    case "$1" in
        --skip-cs) skip_cs=true
            ;;
        --release) target=release
            ;;
        --debug) target=debug
            ;;
        --clean) clean_arg="--clean"
            ;;
        --help)
            echo "==================================================="
            echo "Template Help Message"
            echo ""
            echo "--help    - print a helpful message"
            echo "--skip-cs - don't generate the csharp sdk and glue"
            echo "--release - builds the release template"
            echo "--debug   - builds the debug template"
            echo "--clean   - clean the cached build output"
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
    # lto results in compiler errors on windows
    # lto_arg="lto=full"
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
    "$root_dir/other/scripts/clean-dotnet.sh"
    # The directory where godot will be built out to
    mkdir -p "$GODOT_DIR/bin/"
    # This folder needs to exist in order for the nuget packages to be output here
    mkdir -p "$GODOT_DIR/bin/GodotSharp/Tools/nupkgs"

    # We assume the godot editor is already built
    "$root_dir/godot.sh" \
        --headless \
        --generate-mono-glue \
        "$GODOT_DIR/modules/mono/glue" \
        --precision=double

    "$GODOT_DIR/modules/mono/build_scripts/build_assemblies.py" \
        --godot-output-dir="$GODOT_DIR/bin" \
        --precision=double \
        --godot-platform=windows
fi

# godot_nir_dir="$gitignore_dir/godot_nir"

# if ! test -f "$godot_nir_dir/godot-nir-$godot_nir_version/bin/libNIR.windows.x86_32.a"
# then
#     rm -rf "$godot_nir_dir"
#     mkdir -p "$godot_nir_dir"
#     godot_nir_zip="godot-nir-$godot_nir_version.zip"
#     godot_nir_url="https://github.com/godotengine/godot-nir-static/releases/download/$godot_nir_version/$godot_nir_zip"

#     if wget --version
#     then
#         wget "$godot_nir_url" -O "$godot_nir_dir/$godot_nir_zip"
#         unzip "$godot_nir_dir/$godot_nir_zip" -d "$godot_nir_dir/godot-nir-$godot_nir_version"
#     elif curl --version
#     then
#         curl "$godot_nir_url" -o "$godot_nir_dir/$godot_nir_zip"
#     else
#         echo "ERROR: wget or curl must be installed"
#         exit 1
#     fi
# fi

prev_dir="$PWD"
cd "$GODOT_DIR-nir-static"

if ! make --version
then
    pip3 install mako
fi

./update_mesa.sh

PATH="$MINGW_PREFIX/bin:$PATH" scons \
    platform=windows \
    arch=x86_64 \
    use_llvm=yes

cd "$prev_dir"

dxc_dir="$gitignore_dir/dxc"

if ! test -f "$dxc_dir/$dxc_date/bin/x64/dxc.exe"
then
    rm -rf "$dxc_dir"
    mkdir -p "$dxc_dir"
    dxc_zip="$dxc_date.zip"
    dxc_url="https://github.com/microsoft/DirectXShaderCompiler/releases/download/$dxc_version_date.zip"

    if wget --version
    then
        wget "$dxc_url" -O "$dxc_dir/$dxc_zip"
        unzip "$dxc_dir/$dxc_zip" -d "$dxc_dir/$dxc_date"
    elif curl --version
    then
        curl "$dxc_url" -o "$dxc_dir/$dxc_zip"
        unzip "$dxc_dir/$dxc_zip" -d "$dxc_dir/$dxc_date"
    else
        echo "ERROR: wget or curl must be installed"
        exit 1
    fi
fi

cd "$GODOT_DIR"

scons \
    "$clean_arg" \
    "$lto_arg" \
    platform=windows \
    d3d12=yes \
    vulkan=no \
    dxc_path="$dxc_dir/$dxc_date" \
    mesa_libs="$GODOT_DIR-nir-static" \
    target=template_$target \
    debug_symbols=$debug_symbols \
    module_mono_enabled=yes \
    compiledb=no \
    precision=double \
    import_env_vars=ZIG_GLOBAL_CACHE_DIR,ZIG_LOCAL_CACHE_DIR \
    CC="$cc" \
    CXX="$cxx"

cd "$prev_pwd"