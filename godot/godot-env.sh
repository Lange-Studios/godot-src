#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

root_dir="$dir/.."
godot_repo_dir="${GODOT_DIR:="$root_dir/gitignore/godot"}"

echo "export GODOT_DIR=\"$godot_repo_dir\""