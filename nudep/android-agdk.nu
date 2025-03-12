export def config [] {
    let version = "2023.3.0.0";
    let url = $"https://dl.google.com/developers/android/agdk/agdk-libraries-($version).zip"
    let root_dir = $"($env.GODOT_SRC_DIR)/gitignore/android-adgk"
    let version_dir = $"($root_dir)/agdk-libraries-($version)"
    let zip = $"($root_dir)/agdk-libraries-($version).zip"


    return {
        version: $version,
        url: $url,
        root_dir: $root_dir,
        version_dir: $version_dir,
        zip: $zip,
    }
}

export def download [] {
    use core.nu *

    let config = config
    nudep http file $config.url $config.zip
    nudep decompress $config.zip $config.version_dir
}