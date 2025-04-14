use core.nu *
use platform_constants.nu *

const GODOT_SRC_ZIG_VERSION_DEFAULT = "0.14.0"

export def config [] {
    let zig_dir = ($"($env.GODOT_SRC_DIR)/($DEP_DIR)/zig" | str replace --all "\\" "/")
    let version = ($env.GODOT_SRC_ZIG_VERSION? | default $GODOT_SRC_ZIG_VERSION_DEFAULT)

    return {
        zig_dir: $zig_dir,
        version: $version
        local_cache_dir: $"($zig_dir)/cache/($version)",
        global_cache_dir: $"($zig_dir)/cache/($version)"
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

    if ($zig_bin | path exists) {
        return (run-external $zig_bin ...$rest)
    }

    let file_extension = match $nu.os-info.name {
        "linux" | "macos" => "tar.xz",
        "windows" => "zip",
        _ => $"The host os '($nu.os-info.name)' is currently not supported",
    }

    let zip_file = $"zig-($nu.os-info.name)-($nu.os-info.arch)-($version).($file_extension)"
    let zip_path = $"($zig_dir)/($zip_file)"
    
    nudep http file $"https://ziglang.org/download/($version)/($zip_file)" $zip_path
    nudep decompress $zip_path $zig_version_dir

    let patch_files = [
        "lib/libc/glibc/sysdeps/nptl/bits/thread-shared-types.h"
        "lib/libc/glibc/sysdeps/nptl/pthread.h"
        "lib/libc/include/generic-glibc/bits/thread-shared-types.h"
        "lib/libc/include/generic-glibc/pthread.h"
    ]

    $patch_files | par-each { |patch_file|
        let patch_url = $"https://raw.githubusercontent.com/Lange-Studios/zig/0133746045cca5bec00fe6c98e90ac939ff6faa9/($patch_file)"
        let patch_file = $"(bin_dir)/($patch_file)"
        print $"downloading patch for '($patch_file)' from '($patch_url)'"
        http get $patch_url | save -f $patch_file
    }

    return (run-external $zig_bin ...$rest)
}

# returns the path to the zig binary
export def bin [] {
    return ($"(bin_dir)/zig" | str replace --all "\\" "/")
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
