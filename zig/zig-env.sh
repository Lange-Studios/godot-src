#!/bin/bash

set -e

dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

root_dir="$dir/.."
version="$(cat "$root_dir/config/zig-version.txt")"
zig_parent_dir="$root_dir/gitignore/zig"

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
    platform=linux-x86_64
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

# Only assign if unset. Allow for users to override.  Otherwise, default to the gitignore folder.
ZIG_DIR="${ZIG_DIR:="$zig_parent_dir/zig-$platform-$version"}"
# This is required in order for godot to be built with scons.  Scons operates with its own env and if
# these aren't set, zig will fail to compile godot.  Comment out the below 2 lines to see :)
ZIG_GLOBAL_CACHE_DIR="${ZIG_GLOBAL_CACHE_DIR:="$zig_parent_dir/cache"}"
ZIG_LOCAL_CACHE_DIR="${ZIG_LOCAL_CACHE_DIR:="$zig_parent_dir/cache"}"

echo "export ZIG_DIR=\"$ZIG_DIR\""
echo "export ZIG_GLOBAL_CACHE_DIR=\"$ZIG_GLOBAL_CACHE_DIR\""
echo "export ZIG_LOCAL_CACHE_DIR=\"ZIG_LOCAL_CACHE_DIR\""