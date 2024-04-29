export def config [] {
    let version = ($env.GODOT_SRC_MULTEN_VK_VERSION? | default "1.2.8")
    let root_dir = $"($env.GODOT_SRC_DIR)/gitignore/multen-vk-ios"
    let version_dir = $"($root_dir)/($version)"
    let zip = $"($root_dir)/multen-vk-ios-($version).zip"
    let url = $"https://github.com/KhronosGroup/MoltenVK/releases/download/v($version)/MoltenVK-ios.tar"

    return {
        version: $version,
        root_dir: $root_dir,
        version_dir: $version_dir,
        zip: $zip,
        url: $url,
    }
}

export def download [] {
    use core.nu *

    let config = config

    nudep http file $config.url $config.zip
    nudep decompress tar $config.zip $config.version_dir
    return $config
}