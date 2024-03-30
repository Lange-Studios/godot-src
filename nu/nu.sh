#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

eval "$("$dir/nu-env.sh")"
"$dir/nu-install.sh"

"$GODOT_CROSS_NU_DIR/nu" "$@"