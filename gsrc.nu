# Append the current running new instance to the path
$env.PATH = ($env.PATH | prepend ($nu.current-exe | path dirname))
$env.GODOT_SRC_DIR = ($env.GODOT_SRC_DIR? | default $env.FILE_PWD)

source godot/godot.nu

# use '--help' to see the platforms you can build for
def "main build" [] {
}

# use --help to see the commands that can be run
def main [] {
}

# prints the contents of $env visible to the root of gsrc
def "main env" [] {
    print $env
}

# Start and enter nu as an interactive shell
def --wrapped "main nu" [...rest] {
    run-external $nu.current-exe "--no-config-file" ...$rest
}

# Execute a dotnet command
def --wrapped "main dotnet run" [
    channel: string, # The channel of .net to use.  Example: 6.0, 7.0, 8.0, etc.
    ...rest
] {
    use nudep

    nudep dotnet run $channel ...$rest
}

# Execute a zig command.  Will install zig if it doesn't exist.
export def --wrapped "main zig run" [
    ...rest
] {
    use nudep

    nudep zig run ...$rest
}
