#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

export PIXI_NO_PATH_UPDATE="true"
export PIXI_VERSION=${PIXI_VERSION:-latest}
export PIXI_HOME=${PIXI_HOME:-"$dir/gitignore/pixi"}

if ! test -f "$dir/gitignore/pixi/bin/pixi"
then
    curl -fsSL https://pixi.sh/install.sh | bash
fi

# For some reason passing $@ directly does't work, so we assing to an intermediate args
args=$@
"$dir/gitignore/pixi/bin/pixi" run nu -c "source \"$dir/gsrc.nu\";main $args"
