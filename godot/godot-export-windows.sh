#!/bin/bash

set -e

prev_pwd="$PWD"
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/.."
zig_dir="$root_dir/zig"
gitignore_dir="$root_dir/gitignore"
vcredist_dir="$gitignore_dir/vcredist"
eval "$("$zig_dir/zig-env.sh")"
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
        --project)
            shift
            project="$1"
            ;;
        --output)
            shift
            output="$1"
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

cd "$project"
output_dir="$(dirname "$output")"
output_exe="$(basename "$output")"
rm -rf "$output_dir"
mkdir -p "$output_dir"
"$dir/godot.sh" --headless --export-$target "Windows Desktop" "$output"
cp "$root_dir/gitignore/dxc/dxc_2024_03_22/bin/x64/dxil.dll" "$output_dir/dxil.dll"
cp "$vcredist_dir/vc_redist.x64.exe" "$output_dir/vc_redist.x64.exe"
# Current solution is to open a bat file, but I'd actually like to bundle together in a single exe.
# This way a cmd window doesn't open first.
cat > $output.bat<< EOF
@echo off
%~dp0\vc_redist.x64.exe /install /quiet /norestart
start %~dp0\\$output_exe %*
EOF
cd "$prev_pwd"
echo "Export Success!  Find your build at: $(realpath "$output_dir")"
echo "NOTE: Due to windows requiring vc_redist to be installed, executing the .bat file will ensure its installed before starting the application.  Hopefully this can be bundled in the exe in the future."