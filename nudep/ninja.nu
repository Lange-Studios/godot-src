use core.nu *
use platform_constants.nu *

const GODOT_SRC_NINJA_VERSION_DEFAULT = "1.11.1"

export def config [] {
    let dir = $"($env.GODOT_SRC_DIR)/($DEP_DIR)/ninja"
    let version = ($env.GODOT_SRC_NINJA_VERSION? | default $GODOT_SRC_NINJA_VERSION_DEFAULT)

    return {
        dir: $dir,
        version: $version,
        bin_dir: $"($dir)/($version)"
    }
}

# Execute a ninja command.  Will install ninja if it doesn't exist.
export def download [] {
    let config = config
    let ninja_version_dir = $"($config.dir)/($config.version)"

    let zip_file = $"ninja-($config.version)-($nu.os-info.name).zip"
    let zip_path = $"($config.dir)/($zip_file)"
    
    nudep http file $"https://github.com/ninja-build/ninja/releases/download/v($config.version)/ninja-($nu.os-info.name).zip" $zip_path
    nudep decompress $zip_path $ninja_version_dir
}

# Execute a ninja command.  Will install ninja if it doesn't exist.
export def --wrapped run [...rest] {
    let config = config

    if ($"($config.bin_dir)/ninja" | path exists) {
        run-external $"($config.bin_dir)/ninja" ...$rest
        return
    }

    download
    run-external $"($config.bin_dir)/ninja" ...$rest
}

