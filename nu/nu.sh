#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
echo "Here at: $GODOT_CROSS_NU_DIR"

eval "$("$dir/nu-env.sh")"
echo "Here2 at: $GODOT_CROSS_NU_DIR"
echo "nu at: $GODOT_CROSS_NU_DIR"
echo test dir: "$DIRTEST"
"$dir/nu-install.sh"

"$GODOT_CROSS_NU_DIR/nu" "$@"