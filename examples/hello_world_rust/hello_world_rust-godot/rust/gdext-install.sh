#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/../../../.."

if ! test -f "$root_dir/gitignore/gdext/License.txt"
then
    git clone --depth 1 https://github.com/godot-rust/gdext.git "$root_dir/gitignore/gdext"
fi
