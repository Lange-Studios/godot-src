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
            echo "--help          - Print a helpful message"
            echo "--release       - Exports using the release template"
            echo "--debug         - Exports using the debug template"
            echo "--skip-template - Skips building the export template"
            echo "--project       - The path to the godot project to export"
            echo "--output        - The path where the executable should be exported too.  Including the name of the executable."
            echo "==================================================="
            "$dir/godot-build-linux-template.sh" --help
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
    "$dir/godot-build-linux-template.sh" "${args[@]}"
fi

cd "$project"
output_dir="$(dirname "$output")"
rm -rf "$output_dir"
mkdir -p "$output_dir"
"$dir/godot.sh" --headless --export-$target "Linux" "$output"
cd "$prev_pwd"
echo "Export Success!  Find your build at: $(realpath "$output_dir")"