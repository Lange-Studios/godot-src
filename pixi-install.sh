#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

export PIXI_NO_PATH_UPDATE="true"
export PIXI_VERSION=${PIXI_VERSION:-"v0.45.0"}
export PIXI_HOME=${PIXI_HOME:-"$dir/gitignore/pixi"}
export GSRC_SCRIPT=${GSRC_SCRIPT:-"$dir/gsrc.nu"}

if ! test -f "$dir/gitignore/pixi/bin/pixi" || [[ "$($dir/gitignore/pixi/bin/pixi --version)" != "pixi ${PIXI_VERSION:1}" ]]
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
