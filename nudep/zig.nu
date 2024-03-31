use core.nu *
use platform_constants.nu *

def zig_dir [] {
    return $"($env.GODOT_CROSS_DIR)/($DEP_DIR)/zig"
}

# Execute a zig command.  Will install zig if it doesn't exist.
export def --wrapped main [
    ...rest
] {
    let version = "0.12.0-dev.3496+a2df84d0f"
    let zig_dir = zig_dir;
    let zig_version_dir = $"($zig_dir)/($version)"
    let zig_bin = nudep path zig bin

    $env.ZIG_GLOBAL_CACHE_DIR = $"($zig_dir)/cache"
    $env.ZIG_LOCAL_CACHE_DIR = $"($zig_dir)/cache"

    let is_valid = try {
        run-external --redirect-combine $zig_bin "version" | complete | get stdout | str trim | $in == $version
    } catch {
        false
    }

    if $is_valid {
        run-external $zig_bin ...$rest
        return
    }

    let file_extension = match $nu.os-info.name {
        $OS_LINUX | $OS_MACOS => "tar.xz",
        $OS_WINDOWS => "zip",
        _ => $"The host os '($nu.os-info.name)' is currently not supported",
    }

    let zip_file = $"zig-($nu.os-info.name)-($nu.os-info.arch)-($version).($file_extension)"
    let zip_path = $"($zig_dir)/($zip_file)"
    
    nudep http file $"https://ziglang.org/builds/($zip_file)" $zip_path
    print $zip_path
    nudep decompress $zip_path $zig_version_dir
    run-external $zig_bin ...$rest
}

# returns the path to the zig binary
export def "nudep path zig bin" [] {
    let version = "0.12.0-dev.3496+a2df84d0f"
    let zig_dir = zig_dir;
    let zig_version_dir = $"($zig_dir)/($version)"
    return $"($zig_version_dir)/zig-($nu.os-info.name)-($nu.os-info.arch)-($version)/zig";
}

# Deletes zig and the directory where it is installed
export def "nudep remove zig" [] {
    rm -r (zig_dir)
}
