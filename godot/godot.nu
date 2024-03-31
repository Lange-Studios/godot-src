def config [] {
    use ../nudep/core.nu *
    use utils.nu
    let godot_dir = ($env.GODOT_CROSS_GODOT_DIR? | default $"($env.GODOT_CROSS_DIR)/($DEP_DIR)/gitignore");
    let godot_platform = utils godot-platform $nu.os-info.name
    let arch = $nu.os-info.arch

    let extension = match $godot_platform {
        "windows" => ".exe",
        _ => ""
    }

    let godot_bin = $"($godot_dir)/bin/godot.($godot_platform).editor.double.($arch).mono($extension)"

    return {
        godot_dir: $godot_dir,
        godot_bin: $godot_bin,
        auto_install_godot: ($env.GODOT_CROSS_AUTO_INSTALL_GODOT? | default true),
        import_env_vars: ($env.GODOT_CROSS_IMPORT_ENV_VARS? | default ""),
        custom_modules: ($env.GODOT_CROSS_CUSTOM_MODULES? | default "")
    }
}

# Execute a godot command.  Will install zig if it doesn't exist.
export def --wrapped "main godot run" [
    ...rest
] {
    use ../nudep/core.nu *
    use ../nudep/platform_constants.nu *
    
    let config = config;

    let is_valid = try {
        run-external --redirect-combine $config.godot_bin "--version" | complete | get exit_code | $in == 0
    } catch {
        false
    }

    if $is_valid {
        run-external $config.godot_bin ...$rest
        return
    }

    if $config.auto_install_godot {
        if not ($"($config.godot_dir)/LICENSE.txt" | path exists) {
            git clone --depth 1 https://github.com/godotengine/godot.git $config.godot_dir
        }
    }

    main godot build editor
    run-external $config.godot_bin ...$rest
}

# Build the godot editor for the host platform
export def "main godot build editor" [
    --skip-cs
] {
    use ../nudep
    use ../nudep/platform_constants.nu *
    use utils.nu

    let config = config;

    if $config.auto_install_godot {
        if not ($"($config.godot_dir)/LICENSE.txt" | path exists) {
            git clone --depth 1 https://github.com/godotengine/godot.git $config.godot_dir
        }
    }
    
    # require zig to be installed
    nudep zig run version

    let cc = $"(nudep zig bin) cc"
    let cxx = $"(nudep zig bin) c++"
    
    let platform = utils godot-platform $nu.os-info.name
    
    cd $config.godot_dir
    
    # Set the global and local cache directories since scons requires it
    let zig_config = nudep zig config
    $env.ZIG_GLOBAL_CACHE_DIR = $zig_config.local_cache_dir
    $env.ZIG_LOCAL_CACHE_DIR = $zig_config.global_cache_dir

    # TODO: Allow users to pass custom scons commands
    (run-external scons 
        $"platform=($platform)" 
        "debug_symbols=yes"
        "module_mono_enabled=yes"
        "compiledb=yes"
        "precision=double"
        $"import_env_vars=ZIG_GLOBAL_CACHE_DIR,ZIG_LOCAL_CACHE_DIR($config.import_env_vars)"
        $"custom_modules=($config.custom_modules)"
        $"CC=($cc)"
        $"CXX=($cxx)")

    if not $skip_cs {
        main godot clean dotnet
        # The directory where godot will be built out to
        mkdir $"($config.godot_dir)/bin"
        # This folder needs to exist in order for the nuget packages to be output here
        mkdir $"($config.godot_dir)/bin/GodotSharp/Tools/nupkgs"
        (run-external 
            $config.godot_bin 
            "--headless" 
            "--generate-mono-glue" 
            $"($config.godot_dir)/modules/mono/glue" 
            "--precision=double")
        (run-external 
            $"($config.godot_dir)/modules/mono/build_scripts/build_assemblies.py"
            $"--godot-output-dir=($config.godot_dir)/bin"
            "--precision=double"
            $"--godot-platform=($platform)")
    }
}

export def "main godot clean editor" [] {
    use ../nudep
    use ../nudep/platform_constants.nu *
    use utils.nu

    let config = config

    rm $config.godot_bin
    mkdir $"($config.godot_dir)/submodules/godot/bin/GodotSharp/Tools/nupkgs"
    let platform = utils godot-platform $nu.os-info.name
    cd $config.godot_dir
    (run-external scons 
        "--clean"
        $"platform=($platform)"
        "use_llvm=yes"
        "linker=lld"
        "debug_symbols=yes"
        "module_mono_enabled=yes"
        "compiledb=yes"
        "precision=double")
}

export def "main godot clean all" [] {
    use ../nudep
    use ../nudep/platform_constants.nu *
    use ../utils/utils.nu

    let config = config
    utils git remove ignored $config.godot_dir ...($config.custom_modules | split row ",")
}

# Deletes godot and the directory where it is installed.  Only runs if auto_install_godot is true
export def "main godot remove" [] {
    let config = config;

    if not $config.auto_install_godot {
        error make {
            msg: "Godot not auto installed. Therefore not removing godot."
        }
    }

    rm -r $config.godot_dir
}

export def "main godot clean dotnet" [] {
    use ../utils/utils.nu
    let config = config
    rm -rf $"($config.godot_dir)/bin/GodotSharp"
    utils git remove ignored $"($config.godot_dir)/modules/mono/glue/GodotSharp"
    utils git remove ignored $"($config.godot_dir)/modules/mono/editor/Godot.NET.Sdk"
    utils git remove ignored $"($config.godot_dir)/modules/mono/editor/GodotTools"
}

# use --help to see commands and details
export def "main godot" [] {

}

# use --help to see commands and details
export def "main godot build" [] {

}

# use --help to see commands and details
export def "main godot clean" [] {
}