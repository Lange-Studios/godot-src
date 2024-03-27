#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

"$dir/../../godot/godot-export-windows.sh" --debug --project "$dir/hello_world-godot" --output "$dir/../gitignore/hello_world/bin/windows/debug/hello_world.exe"