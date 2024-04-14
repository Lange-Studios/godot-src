# dotnet builds require libssl and libcrypto to be pacakged manually for .net.  Issue here: https://github.com/godotengine/godot/issues/84559
export def config [] {
    let root_dir = $"($env.GODOT_CROSS_DIR)/gitignore/android-openssl"
    let version = "1.1.1p-beta-1"
    let version_dir = $"($root_dir)/openssl-($version)"
    let zip_name = $"openssl-($version).aar"
    let zip_url = $"https://dl.google.com/android/maven2/com/android/ndk/thirdparty/openssl/($version)/($zip_name)"
    let zip_path = $"($root_dir)/($zip_name)"

    {
        root_dir: $root_dir,
        version_dir: $version_dir,
        zip_name: $zip_name,
        zip_url: $zip_url,
        zip_path: $zip_path,
    }
}

export def download [] {
    use core.nu *

    let config = config
    nudep http file $config.zip_url $config.zip_path
    #.aar files are in zip format
    nudep decompress zip $config.zip_path $config.version_dir
}

# Copies the libraries to the android lib folder
export def install [
    lib_dir: string # The lib directory for android build
    arch: string # The arch to install for
] {
    download
    let config = config

    mkdir $"($lib_dir)/debug/($arch)"
    cp $"($config.version_dir)/prefab/modules/crypto/libs/android.($arch)/libcrypto.so" $"($lib_dir)/debug/($arch)/libcrypto.so"
    cp $"($config.version_dir)/prefab/modules/ssl/libs/android.($arch)/libssl.so" $"($lib_dir)/debug/($arch)/libssl.so"
}