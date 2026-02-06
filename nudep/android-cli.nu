export def config [] {
    let cli_version = "11076708_latest";
    let cli_platform = match $nu.os-info.name {
        "windows" => "win",
        "linux" => "linux",
        "macos" => "mac",
        _ => {
            error make { msg: $"Unsupported host os: ($nu.os-info.name)" }
        }
    }
    let cli_root_dir = $"($env.GODOT_SRC_DIR)/gitignore/android-cli"
    let cli_version_dir = $"($cli_root_dir)/($cli_version)"
    let cli_zip = $"($cli_root_dir)/($cli_platform)-($cli_version).zip"

    # Read the lines of android/detect.py
    let android_detect_lines = open $"($env.GODOT_SRC_GODOT_DIR)/platform/android/detect.py" | 
        split row "\n" | 
        where { |i| ($i | str trim) != "" }
    # Find the line where "def get_ndk_version():" is so we can get the return value on the next line
    let get_ndk_index = $android_detect_lines | 
        enumerate | 
        where { |el| ($el.item | str trim) == "def get_ndk_version():" } | 
        get index.0 
    # Get the return value on the next line and remove unneeded characters like "return" and quotes
    let ndk_version = $android_detect_lines | 
        get ($get_ndk_index + 1) | 
        str trim | 
        str substring 7.. | 
        str trim -c "\""

    let build_tools_version = "34.0.0";

    return {
        cli_version: $cli_version,
        cli_platform: $cli_platform,
        cli_root_dir: $cli_root_dir,
        cli_version_dir: $cli_version_dir,
        cli_zip: $cli_zip,
        ndk_version: $ndk_version,
        ndk_dir: $"($cli_version_dir)/ndk/($ndk_version)",
        # TODO: Get this version and ndk version from godot/platform/android/java/app/config.gradle
        build_tools_version: $build_tools_version,
        build_tools_dir: $"($cli_version_dir)/build-tools/($build_tools_version)"
    }
}

export def download [] {
    use core.nu *

    let android_config = config

    (nudep http file 
    $"https://dl.google.com/android/repository/commandlinetools-($android_config.cli_platform)-($android_config.cli_version).zip"
    $android_config.cli_zip)

    nudep decompress $android_config.cli_zip $android_config.cli_version_dir
}