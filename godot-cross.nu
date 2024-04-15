$env.GODOT_CROSS_DIR = $env.GODOT_CROSS_DIR? | $env.FILE_PWD

source zig/nu/zig.nu
source godot/godot.nu

# use '--help' to see the platforms you can build for
def "main build" [] {
}

# use --help to see the commands that can be run
def main [] {
}

# prints the contents of $env visible to the root of godot-cross
def "main env" [] {
    print $env
}