export def config [] {
    let version = $env.GODOT_SRC_PYPY_VERSION? | default "3.10-v7.3.16"

    let pypy_version_os = match $"($nu.os-info.name)_($nu.os-info.arch)" {
        "windows_x86_64" => $"pypy($version)-win64",
        "linux_x86_64" => $"pypy($version)-linux64",
        "linux_aarch64" => $"pypy($version)-aarch64",
        "macos_x86_64" => $"pypy($version)-macos_x86_64",
        "macos_aarch64" => $"pypy($version)-macos_arm64"
    }

    let zip_ext = match $nu.os-info.name {
        "windows" => "zip",
        _ => "tar.bz2",
    }

    let url = $"https://downloads.python.org/pypy/($pypy_version_os).($zip_ext)"

    let root_dir = $"($env.GODOT_SRC_DIR)/gitignore/pypy"
    let unzip_dir = $"($root_dir)/($version)"
    let version_dir = $"($root_dir)/($version)/($pypy_version_os)"
    let zip = $"($root_dir)/pypy-($version).($zip_ext)"

    let bin_dir = match $nu.os-info.name {
        "windows" => $version_dir,
        _ => $"($version_dir)/bin"
    }

    return {
        version: $version,
        root_dir: $root_dir,
        unzip_dir: $unzip_dir
        version_dir: $version_dir,
        bin_dir: $bin_dir,
        zip: $zip,
        url: $url,
    }
}

export def download [] {
    use core.nu *

    let config = config

    nudep http file $config.url $config.zip

    nudep decompress $config.zip $config.unzip_dir
}

export def env-path [] {
    let config = config
    return ($env.PATH | prepend $config.bin_dir | prepend $"($config.version_dir)/Scripts")
}

# Downloads pypy and returns a string that can be assigned to the path environment variable
export def init []: nothing -> string {
    download

    let config = config
    cd $config.version_dir

    $env.PATH = (env-path)
    run-external python3 "-m" "ensurepip"
    run-external python3 "-m" pip install "--upgrade" pip
}