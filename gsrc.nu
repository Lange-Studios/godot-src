# Append the current running new instance to the path
$env.GODOT_SRC_DIR = ($env.GODOT_SRC_DIR? | default (($env.GSRC_SCRIPT? | default $"($env.PWD)/gsrc.nu") | path expand | path dirname))
$env.PIXI_NO_PATH_UPDATE = "true"
$env.PIXI_VERSION = ($env.PIXI_VERSION? | default "v0.26.1")
$env.PIXI_HOME = ($env.PIXI_HOME? | default $"($env.GODOT_SRC_DIR)/gitignore/pixi")
$env.PATH = ($env.PATH | prepend $"($env.GODOT_SRC_DIR)/.pixi/envs/default")
$env.PATH = ($env.PATH | prepend $"($env.GODOT_SRC_DIR)/.pixi/envs/default/bin")
# Uncomment this when going back to pixi
# $env.PATH = ($env.PATH | prepend (
#     $env.GODOT_SRC_ZIG_BIN_DIR? | (
#         default (gsrc pixi run --manifest-path $"($env.GODOT_SRC_DIR)/pixi.toml" python -m ziglang env | from json).zig_exe | path dirname
#     )
# ))
# Comment the below zig path setting when going back to pixi
$env.PATH = ($env.PATH | prepend (
    $env.GODOT_SRC_ZIG_BIN_DIR? | (
        default (gsrc zig run env | from json).zig_exe | path dirname
    )
))
$env.PIXI_HOME = ($env.PIXI_HOME? | default $"($env.GODOT_SRC_DIR)/gitignore/python-wrapper")

$env.PATH = match ($nu.os-info.name == "windows") {
    true => {
        mkdir $"($env.GODOT_SRC_DIR)/gitignore/python-link"
        rm -f $"($env.GODOT_SRC_DIR)\\gitignore\\python-link\\python3.exe"
        mklink $"($env.GODOT_SRC_DIR)\\gitignore\\python-link\\python3.exe" $"($env.GODOT_SRC_DIR)\\.pixi\\envs\\default\\python.exe" | complete
        ($env.PATH | prepend $"($env.GODOT_SRC_DIR)/gitignore/python-link")
    },
    false => $env.PATH
}

if $nu.os-info.name == "windows" and not ($"($env.PIXI_HOME)/bin/pixi.exe" | path exists) {
    powershell -Command "iwr -useb https://pixi.sh/install.ps1 | iex"
} else if $nu.os-info.name != "windows" and not ($"($env.PIXI_HOME)/bin/pixi" | path exists) {
    http get https://pixi.sh/install.sh | bash
}

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