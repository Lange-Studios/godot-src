use core.nu *
use platform_constants.nu *

const GODOT_SRC_ZIG_VERSION_DEFAULT = "0.12.0-dev.3496+a2df84d0f"

export def config [] {
    let zig_dir = ($"($env.GODOT_SRC_DIR)/($DEP_DIR)/zig" | str replace --all "\\" "/")
    mkdir $"($zig_dir)/cache"

    return {
        zig_dir: $zig_dir,
        version: ($env.GODOT_SRC_ZIG_VERSION? | default $GODOT_SRC_ZIG_VERSION_DEFAULT)
        local_cache_dir: $"($zig_dir)/cache",
        global_cache_dir: $"($zig_dir)/cache"
    }
}

# Execute a zig command.  Will install zig if it doesn't exist.
export def --wrapped run [
    ...rest
] {
    let config = config
    let version = $config.version
    let zig_dir = $config.zig_dir;
    let zig_version_dir = $"($zig_dir)/($version)"
    let zig_bin = bin

    $env.ZIG_GLOBAL_CACHE_DIR = $config.local_cache_dir
    $env.ZIG_LOCAL_CACHE_DIR = $config.global_cache_dir

    run-external $zig_bin ...$rest
}

# returns the path to the zig binary
export def bin [] {
    let zig_env = zig env | from json

    return ($"($zig_env.zig_exe)" | str replace --all "\\" "/")
}

export def bin_dir [] {
    let config = config
    let zig_version_dir = $"($config.zig_dir)/($config.version)"
    return ($"($zig_version_dir)/zig-($nu.os-info.name)-($nu.os-info.arch)-($config.version)" | str replace --all "\\" "/")
}

# Deletes zig and the directory where it is installed
export def remove [] {
    rm -r (zig_dir)
}
