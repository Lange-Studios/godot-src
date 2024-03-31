# Converts the os standard platform to the godot equivalent.
export def godot-platform [platform: string] {
    match $platform {
        "windows" => "windows",
        "macos" => "macos"
        "linux" => "linuxbsd"
    }
}