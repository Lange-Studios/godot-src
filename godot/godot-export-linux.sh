#!/bin/bash

set -e

prev_pwd="$PWD"
dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/../.."

# Get the godot env vars.
eval "$("$dir/godot-env.sh")"

args=()

while test $# -gt 0
do
    args+=("$1")
    case "$1" in
        --skip-template) skip_template=true
            ;;
        --release) target=release
            ;;
        --debug) target=debug
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
            "$dir/godot-build-linux-template.sh" --help
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
    "$dir/godot-build-linux-template.sh" "${args[@]}"
fi

"$root_dir/cargo-build-$target.sh"
cd "$root_dir/blockyball-godot"
target_dir="$root_dir/blockyball-godot-target/linux/x86_64/$target"
rm -rf "$target_dir"
mkdir -p "$target_dir"
"$root_dir/godot.sh" --headless --export-$target "Linux" "$target_dir/blockyballot.x86_64"
cd "$prev_pwd"