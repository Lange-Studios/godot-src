# Converts the os standard platform to the godot equivalent.
export def godot-platform [platform: string] {
    if $platform == "linux" {
        return "linuxbsd"
    }

    return $platform
}