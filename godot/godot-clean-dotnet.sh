#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
root_dir="$dir/.."

# Get the godot env vars.
eval "$("$dir/godot-env.sh")"

# Clean the dotnet build cache because the cache is not being cleared as the godot documentation
# suggests it should.  And this is just another level of certainty that the cache is cleared.
rm -rf "$GODOT_CROSS_GODOT_DIR/bin/GodotSharp"
"$dir/../utils/clean-ignore.sh" "$GODOT_CROSS_GODOT_DIR/modules/mono/glue/GodotSharp"
"$dir/../utils/clean-ignore.sh" "$GODOT_CROSS_GODOT_DIR/modules/mono/editor/Godot.NET.Sdk"
"$dir/../utils/clean-ignore.sh" "$GODOT_CROSS_GODOT_DIR/modules/mono/editor/GodotTools"