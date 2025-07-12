export def config [] {
    let jdk_zip_extension = match $nu.os-info.name {
        "windows" => "zip",
        _ => "tar.gz"
    }

    let os = match $nu.os-info.name {
        "macos" => "mac",
        _ => $nu.os-info.name
    }

    let jdk_root_dir = $"($env.GODOT_SRC_DIR)/gitignore/jdk"
    let jdk_version_dir = $"($jdk_root_dir)/OpenJDK17U-jdk_hotspot_17.0.10_7"
    let jdk_root_url = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10%2B7"
    let jdk_zip_name = $"OpenJDK17U-jdk_x64_($os)_hotspot_17.0.10_7.($jdk_zip_extension)"
    let jdk_zip_url = $"($jdk_root_url)/($jdk_zip_name)"
    let jdk_zip_path = $"($jdk_root_dir)/($jdk_zip_name)";
    mut jdk_home_dir = $"($jdk_version_dir)/jdk-17.0.10+7"

    if $nu.os-info.name == "macos" {
        $jdk_home_dir = ($jdk_home_dir | path join "Contents/Home")
    }

    let jdk_bin_dir = $"($jdk_home_dir)/bin"

    {
        zip_extension: $jdk_zip_extension,
        root_dir: $jdk_root_dir,
        version_dir: $jdk_version_dir,
        root_url: $jdk_root_url,
        zip_name: $jdk_zip_name,
        zip_url: $jdk_zip_url,
        zip_path: $jdk_zip_path,
        home_dir: $jdk_home_dir,
        bin_dir: $jdk_bin_dir,
    }
}

export def download [] {
    use core.nu *

    let jdk_config = config
    nudep http file $jdk_config.zip_url $jdk_config.zip_path
    nudep decompress $jdk_config.zip_path $jdk_config.version_dir
}

export def --wrapped run [
    command: string, 
    ...rest
] {
    download
    run-external $"(config | get "bin_dir")/($command)" ...$rest
}
