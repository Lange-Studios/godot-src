#!/bin/bash

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

godot_cross_config_dir="${GODOT_CROSS_CONFIG_DIR:="$(realpath "$dir/../config")"}"

if ! test -f "$godot_cross_config_dir/nu-version.txt"
then
    godot_cross_config_dir="$dir/../config"
fi

if ! test -f "$godot_cross_config_dir/nu-version.txt"
then
    echo "ERROR: failed to find nu-version.txt in godot cross config directory $godot_cross_config_dir"
    exit 1
fi

godot_cross_nu_version="${GODOT_CROSS_NU_VERSION:="$(cat "$godot_cross_config_dir/nu-version.txt")"}"

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    version_dir=nu-$GODOT_CROSS_NU_VERSION-$(arch)-unknown-linux-musl
elif [[ "$OSTYPE" == "darwin"* ]]
then
    # TODO
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]
then
    # TODO
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
else
    # TODO?  Free BSD?  Redux?  Chrome OS?  Idk could be fun :)
    echo "ERROR: OS $OSTYPE is unsupported"
    exit 1
fi

godot_cross_nu_dir="${GODOT_CROSS_NU_DIR:="$(realpath "$dir/../gitignore/nu/$version_dir")"}"

echo "$(cat <<EOF
export GODOT_CROSS_NU_DIR="$godot_cross_nu_dir"
export GODOT_CROSS_NU_VERSION="$godot_cross_nu_version"
EOF
)"
