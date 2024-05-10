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

# Execute a zig command.  Will install zig if it doesn't exist.
export def --wrapped "main zig cc run" [
    ...rest
] {
    use nudep

    # If we run into issues on specific platforms, uses -target arch-os-abi to detect which
    # filtering to use
    mut filtered_args = []

    for arg in $rest {
        let arg = if $arg == "-lgcc_s" {
            "-lunwind"
        } else if $arg == "-lgcc_eh" {
            "-lc++"
        } else if ($arg | str starts-with "-Wl,") and ($arg | str ends-with "list.def") {
            $arg | str substring 4..
        } else if (
            ($arg | str contains "libcompiler_builtins-") or
            ($arg | str starts-with "--target=") or
            ($arg | str starts-with "-lwindows") or
            ($arg == "-Wl,--disable-auto-image-base") or
            ($arg == "-lmsvcrt") or
            ($arg == "-lgcc") or
            ($arg == "-l:libpthread.a")
        ) {
            continue
        } else {
            $arg
        }

        $filtered_args = ($filtered_args | append $arg)
    }

    nudep zig run cc ...$filtered_args
}