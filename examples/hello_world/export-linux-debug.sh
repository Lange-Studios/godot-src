#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

"$dir/../../godot/godot-export-linux.sh" --debug --project "$dir/hello_world-godot" --output "$dir/../gitignore/hello_world/bin/linux/debug/hello_world.x86_64"