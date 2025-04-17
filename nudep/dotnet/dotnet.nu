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
export def download [] {
    # First attempts to grab the explicitly set GODOT_SRC_DOTNET_CHANNEL.  Then queries the .csproj.
    let channel = ($env.GODOT_SRC_DOTNET_CHANNEL? | default (match $env.GODOT_SRC_CS_PROJ {
        null | "" => {
            error make { msg: "Either set GODOT_SRC_DOTNET_CHANNEL environment or set GODOT_SRC_CS_PROJ environment variable" }
        },
        _ => {
            try {
                # First try getting the dotnet channel specific to the target platform
                open $env.GODOT_SRC_CS_PROJ |
                    from xml |
                    get content |
                    filter { |el| $el.tag == "PropertyGroup" } |
                    first |
                    get content |
                    filter { |el|
                        $el.tag == "TargetFramework" and ($el.attributes | any { |el|
                            $el.Condition? | default "" | str contains $env.GODOT_SRC_GODOT_PLATFORM
                        })
                    } |
                    get content.0.0.content |
                    str substring 3..
            } catch {
                # Then try getting the default dotnet target
                open $env.GODOT_SRC_CS_PROJ |
                    from xml |
                    get content |
                    filter { |el| $el.tag == "PropertyGroup" } |
                    first |
                    get content |
                    filter { |el|
                        $el.tag == "TargetFramework" and ($el.attributes | any { |el|
                            $el.Condition? | $in == null
                        })
                    } |
                    get content.0.0.content |
                    str substring 3..
            }
        }
    }))

    if $channel == null or ($channel | str trim) == "" {
        error make { msg: { "Failed to get the dotnet channel.  Try setting explicitly with environment variable GODOT_SRC_DOTNET_CHANNEL to '6.0', '7.0', '8.0', etc." } }
    }

    let config = config

    let install_script = match $nu.os-info.name {
        "windows" => {
            command: "powershell", 
            args: [
                $"Set-ExecutionPolicy -scope Process Unrestricted; ($env.GODOT_SRC_DIR)/nudep/dotnet/dotnet-install.ps1" "-NoPath" "-Channel" $channel "-InstallDir" $config.dir
            ] 
        },
        "linux" | "macos" => {
            command: $"($env.GODOT_SRC_DIR)/nudep/dotnet/dotnet-install.sh",
            args: [
                "--no-path" "--channel" $channel "--install-dir" $config.dir
            ]
        },
        _ => {
            error make { msg: $"Unsupported os: ($nu.os-info.name)", }
        }
    }

    print "Installing dotnet if missing. This may take a minute..."
    print $"($install_script.command) ($install_script.args | str join ' ')"
    run-external $install_script.command ...$install_script.args
}

# Execute a dotnet command.  Will install dotnet if it doesn't exist.
export def --wrapped run [channel: string, ...rest] {
    let config = config
    download
    run-external $config.bin ...$rest
}

export def env-path [] {
    if $env.GODOT_SRC_DOTNET_ENABLED and not $env.GODOT_SRC_DOTNET_USE_SYSTEM {
        let dotnet_config = config
        return ($env.PATH | prepend $dotnet_config.dir)
    } else {
        return $env.PATH
    }
}

# Downloads dotnet and returns a string that can be assigned to the path environment variable
# if we are setup to use dotnet via ``$env.GODOT_SRC_DOTNET_ENABLED``.  Otherwise, it returns
# ``$env.PATH``
export def init [] -> string {
    if $env.GODOT_SRC_DOTNET_ENABLED and not $env.GODOT_SRC_DOTNET_USE_SYSTEM {
        download
    } else {
        print "using system installed dotnet"
    }
}