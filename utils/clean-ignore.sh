#!/bin/bash

# This delets all of the files that are ignored by git.  This is useful for build systems that don't have
# a clean command or if the build system isn't correctly detecting which files to clean.
#
# Example: Take a look at the godot-clean-dotnet.sh script.  This is because godot generates a lot of
#          c# glue code including nuget packages.  The nuget packages don't get cleaned with "dotnet clean"
#          or "dotnet restore".  Seems like a bug somewhere, but this helps fix it.
#
# Sometimes its just useful for getting back to square one and testing rebuilding without any cache.

set -e

prev_pwd="$PWD"

dir_to_clean="$1"
cd "$dir_to_clean"
echo "cleaning directory: $dir_to_clean"
files_to_remove="$(git status . --ignored --short)"

if [[ "$files_to_remove" == "" ]]
then
    echo "$dir_to_clean: nothing to remove"
    exit 0
fi

echo "Removing the following files and folders:"
echo "${files_to_remove[@]}"

# This command removes all files that are gitignored.  This is useful for removing files that 
# ``scons --clean`` doesn't remove such as the mono glue.
#
# Explanation of commands:
#
# Lists all the files and folders that are being ignored due .gitignore
# git status --ignored --short
#
# Removes the !! that ``git status --ignored --short`` outputs.
# NOTE: This could be an issue if we ever name a file or folder with !
# sed 's/!//g'
#
# Replaces all newline charactes with a ' ' so ``git status --ignored --short`` is space delimited
# tr '\n' ' '
#
# Removes all of the files and folders returned after formatting the output
# rm -rf
#
rm -rf $(echo "${files_to_remove[@]}" | sed 's/!//g' | tr '\n' ' ')

cd "$prev_pwd"