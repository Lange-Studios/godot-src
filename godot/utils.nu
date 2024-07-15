# Converts the os standard platform to the godot equivalent.
export def godot-platform [platform: string] {
    if $platform == "linux" {
        return "linuxbsd"
    }

    return $platform
}

# Converts a windows style path to a unix style path if current os is windows or
# if --force is passed.
export def "to unix-path" [
    --force # Always execute even if the host machine isn't windows
]: string -> string {
    let start = $in
    if not $force and $nu.os-info.name != "windows" {
        return $start
    }

    $start | str substring ((($in | str index-of ":") + 1)..) | str replace --all '\' '/'
}