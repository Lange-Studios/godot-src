# Append the current running new instance to the path
$env.PATH = ($env.PATH | prepend ($nu.current-exe | path dirname))
$env.GODOT_SRC_DIR = ($env.GODOT_SRC_DIR? | default $env.FILE_PWD)

source godot/godot.nu

# use '--help' to see the platforms you can build for
export def "gsrc build" [] {
}

# use --help to see the commands that can be run
export def gsrc [] {
}

# prints the contents of $env visible to the root of gsrc
export def "gsrc env" [] {
    print $env
}

# Start and enter nu as an interactive shell
export def --wrapped "gsrc nu" [...rest] {
    run-external $nu.current-exe "--no-config-file" ...$rest
}

# Execute a dotnet command
export def --wrapped "gsrc dotnet run" [
    channel: string, # The channel of .net to use.  Example: 6.0, 7.0, 8.0, etc.
    ...rest
] {
    use nudep

    nudep dotnet run $channel ...$rest
}

# Execute a zig command.  Will install zig if it doesn't exist.
export def --wrapped "gsrc zig run" [
    ...rest
] {
    use nudep

    nudep zig run ...$rest
}
