$env.GODOT_CROSS_DIR = $env.FILE_PWD

source godot/build-android-template.nu
source godot/build-linux-template.nu
source zig/nu/zig.nu

# All of our subcommands are defined as build commands. Main is required for nu
# to have an entrypoint.  Without main, it will not do anything.
def main [] {
}