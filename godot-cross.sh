#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

"$dir/nu/nu.sh" "$dir/godot-cross.nu" "$@"