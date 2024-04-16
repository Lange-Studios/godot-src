use core.nu *
use platform_constants.nu *

const GODOT_SRC_CMAKE_VERSION_DEFAULT = "3.29.1"

export def config [] {
    let dir = $"($env.GODOT_SRC_DIR)/($DEP_DIR)/cmake"
    let version = ($env.GODOT_SRC_CMAKE_VERSION? | default $GODOT_SRC_CMAKE_VERSION_DEFAULT)

    return {
        dir: $dir,
        version: $version,
        bin_dir: $"($dir)/($version)/cmake-($version)-($nu.os-info.name)-($nu.os-info.arch)/bin"
    }
}

export def download [] {
    let config = config
    let cmake_version_dir = $"($config.dir)/($config.version)"

    let file_extension = match $nu.os-info.name {
        $OS_LINUX | $OS_MACOS => "tar.gz",
        $OS_WINDOWS => "zip",
        _ => $"The host os '($nu.os-info.name)' is currently not supported",
    }

    let zip_file = $"cmake-($config.version)-($nu.os-info.name)-($nu.os-info.arch).($file_extension)"
    let zip_path = $"($config.dir)/($zip_file)"
    
    nudep http file $"https://github.com/Kitware/CMake/releases/download/v($config.version)/($zip_file)" $zip_path
    nudep decompress $zip_path $cmake_version_dir
}

# Execute a cmake command.  Will install cmake if it doesn't exist.
export def --wrapped run [
    cmd: string,
    ...rest
] {
    let config = config
    if ($"($config.bin_dir)/cmake" | path exists) {
        run-external $"($config.bin_dir)/($cmd)" ...$rest
        return
    }

    download
    run-external $"($config.bin_dir)/($cmd)" ...$rest
}

