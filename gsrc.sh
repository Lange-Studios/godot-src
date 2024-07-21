#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

export PIXI_NO_PATH_UPDATE="true"
export PIXI_VERSION=${PIXI_VERSION:-latest}
export PIXI_HOME=${PIXI_HOME:-"$dir/gitignore/pixi"}
export GSRC_SCRIPT=${GSRC_SCRIPT:-"$dir/gsrc.nu"}

if ! test -f "$dir/gitignore/pixi/bin/pixi"
then
    if curl --version
    then
        curl -fsSL https://pixi.sh/install.sh | bash
    elif wget --version
    then
        wget -qO- --max-redirect=20 https://pixi.sh/install.sh | bash
    else
        echo "ERROR: tried to install pixi. wget or curl must be installed"
        exit 1
    fi
fi

# For some reason passing $@ directly does't work, so we assign to an intermediate args
args=$@
"$dir/gitignore/pixi/bin/pixi" run --manifest-path "$dir/pixi.toml" --frozen nu -c "source \"$GSRC_SCRIPT\";gsrc $args"
