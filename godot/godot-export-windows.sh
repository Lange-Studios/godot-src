#!/bin/bash

set -e

prev_pwd="$PWD"
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/../.."
zig_dir="$root_dir/zig"
gitignore_dir="$root_dir/gitignore"
vcredist_dir="$gitignore_dir/vcredist"
"$zig_dir/zig-install.sh"
export MINGW_PREFIX="$zig_dir/mingw"

# Get the godot env vars.
eval "$("$dir/godot-env.sh")"

args=()

while test $# -gt 0
do
    args+=("$1")
    case "$1" in
        --skip-template) skip_template=true
            ;;
        --release) 
            target=release
            cargo_target_arg=--release
            ;;
        --debug) 
            target=debug
            carg_target_arg=""
            ;;
        --help)
            echo "==================================================="
            echo "Export Help Message"
            echo ""
            echo "--help          - print a helpful message"
            echo "--release       - exports using the release template"
            echo "--debug         - exports using the debug template"
            echo "--skip-template - skips building the export template"
            echo "==================================================="
            "$dir/godot-build-windows-template.sh" --help
            exit 0
            ;;
        *)
            ;;
    esac
    shift
done

if [[ "$target" != "release" && "$target" != "debug" ]]
then
    echo "no target arg was supplied. Must supply '--release' or '--debug'"
    exit 1
fi

if [[ "$skip_template" != "true" ]]
then
    "$dir/godot-build-windows-template.sh" "${args[@]}"
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    export GODOT4_BIN="$GODOT_DIR/bin/godot.linuxbsd.editor.double.x86_64.mono"
elif [[ "$OSTYPE" == "darwin"* ]]
then
        echo "ERROR: MacOS not supported yet!"
        exit 1
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    export GODOT4_BIN="$GODOT_DIR\bin\godot.windows.editor.double.x86_64.mono.exe"
else
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

# Microsoft talks about how they intend for vc_redist to be used here: 
#   https://learn.microsoft.com/en-us/cpp/windows/deploying-visual-cpp-application-by-using-the-vcpp-redistributable-package?view=msvc-170
#   https://learn.microsoft.com/en-us/cpp/windows/determining-which-dlls-to-redistribute?view=msvc-170&source=recommendations
#   https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170
# And here's a helpful tutorial for using it without window popup prompts:
#   https://www.asawicki.info/news_1597_installing_visual_c_redistributable_package_from_command_line.html
if ! test -f "$vcredist_dir/vc_redist.x64.exe"
then
    rm -rf "$vcredist_dir"
    mkdir -p "$vcredist_dir"
    vcredist_url="https://aka.ms/vs/17/release/vc_redist.x64.exe"

    if wget --version
    then
        wget "$vcredist_url" -O "$vcredist_dir/vc_redist.x64.exe"
    elif curl --version
    then
        curl "$vcredist_url" -o "$vcredist_dir/vc_redist.x64.exe"
    else
        echo "ERROR: wget or curl must be installed"
        exit 1
    fi
fi

export CARGO_TARGET_DIR="$root_dir/blockyball-godot/src/rust/lib/target"
# This is for bindgen's clang-sys dependency. 
# Docs here: https://github.com/KyleMayes/clang-sys?tab=readme-ov-file#environment-variables
export CLANG_PATH="$root_dir/zig/llvm/clang"
export RUST_LOG=bindgen::builder=debug
# For some reason targeting windows-gnu results in godot not being able to load the rust dll at runtime
# PATH="$MINGW_PREFIX/bin-rust:$PATH" cargo build --target=x86_64-pc-windows-gnu -p blockyball-godot-rust $cargo_target_arg
# Here we use xwin to target msvc.  But I'm wondering if we can use zig and spoof the link.exe as well.
cargo xwin build --target=x86_64-pc-windows-msvc -p blockyball-godot-rust $cargo_target_arg
cd "$root_dir/blockyball-godot"
target_dir="$root_dir/blockyball-godot-target/windows/x86_64/$target"
rm -rf "$target_dir"
mkdir -p "$target_dir"
"$root_dir/godot.sh" --headless --export-$target "Windows Desktop" "$target_dir/blockyballot.exe"
cp "$root_dir/gitignore/dxc/dxc_2024_03_22/bin/x64/dxil.dll" "$target_dir/dxil.dll"
cp "$vcredist_dir/vc_redist.x64.exe" "$target_dir/vc_redist.x64.exe"
# Current solution is to open a bat file, but I'd actually like to bundle together in a single exe.
# This way a cmd window doesn't open first.
cat > $target_dir/blockyballot.bat<< EOF
@echo off
%~dp0\vc_redist.x64.exe /install /quiet /norestart
start %~dp0\blockyballot.exe %*
EOF
cd "$prev_pwd"