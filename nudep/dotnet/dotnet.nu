use ../core.nu *

export def config [] {
    let dir = $"($env.GODOT_SRC_DIR)/($DEP_DIR)/dotnet"

    return {
        dir: $dir,
        bin: $"($dir)/dotnet"
    }
}

# Install scripts are here: https://github.com/dotnet/install-scripts
# See: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script#recommended-version
export def download [
    channel: string # The channel to install dotnet from. Example: 6.0, 7.0, 8.0, etc.
] {
    let config = config

    let install_script = match $nu.os-info.name {
        "windows" => $"($env.GODOT_SRC_DIR)/nudep/dotnet/dotnet-install.ps1",
        "linux" | "macos" => $"($env.GODOT_SRC_DIR)/nudep/dotnet/dotnet-install.sh",
        _ => {
            error make { msg: $"Unsupported os: ($nu.os-info.name)", }
        }
    }

    run-external $install_script "--no-path" "--channel" $channel "--install-dir" $config.dir
}

# Execute a ninja command.  Will install ninja if it doesn't exist.
export def --wrapped run [channel: string, ...rest] {
    let config = config
    download $channel
    run-external $config.bin ...$rest
}

