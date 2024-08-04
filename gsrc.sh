#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

"$dir/pixi-install.sh"
# For some reason passing $@ directly does't work, so we assign to an intermediate args
args=$@
"$dir/gitignore/pixi/bin/pixi" run --manifest-path "$dir/pixi.toml" --frozen nu -c "source \"$GSRC_SCRIPT\";gsrc $args"
