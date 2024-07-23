# Append the current running new instance to the path
$env.GODOT_SRC_DIR = ($env.GODOT_SRC_DIR? | default ($env.GSRC_SCRIPT | path expand | path dirname))
$env.PATH = ($env.PATH | prepend ($nu.current-exe | path dirname))
$env.PATH = ($env.PATH | prepend $"($env.GODOT_SRC_DIR)/.pixi/envs/default/bin")
$env.PATH = ($env.PATH | prepend (
    (gsrc pixi run --manifest-path $"($env.GODOT_SRC_DIR)/pixi.toml" python3 -m ziglang env | from json).zig_exe | path dirname
))

# Unset this since we want to support other pixi.toml's after startup
$env.PIXI_PROJECT_MANIFEST = null

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

# Run a pixi command
export def --wrapped "gsrc pixi" [...rest] {
    run-external $"($env.PIXI_HOME)/bin/pixi" ...$rest
}