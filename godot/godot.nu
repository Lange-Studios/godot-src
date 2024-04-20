use ../nudep
use utils.nu

$env.GODOT_SRC_DOTNET_ENABLED = ($env.GODOT_SRC_DOTNET_ENABLED? | default false)
$env.GODOT_SRC_DOTNET_USE_SYSTEM = ($env.GODOT_SRC_DOTNET_USE_SYSTEM? | default false)
$env.GODOT_SRC_PRECISION = ($env.GODOT_SRC_PRECISION? | default "single")

# Default godot's platform to the host machine unless specified otherwise and make sure dotnet
# is set up for the host machine
$env.GODOT_SRC_GODOT_PLATFORM = ($env.GODOT_SRC_GODOT_PLATFORM? | default (utils godot-platform $nu.os-info.name))
$env.PATH = (nudep dotnet init)

export def "main godot config" [
    --target: string = "editor",
    --release-mode: string,
    --arch: string,
    --platform: string
] {
    use ../nudep/core.nu *
    use utils.nu
    let godot_dir = ($env.GODOT_SRC_GODOT_DIR? | default $"($env.GODOT_SRC_DIR)/($DEP_DIR)/godot");
    let godot_platform = utils godot-platform ($platform | default $nu.os-info.name)    
    let extra_suffix = ($env.GODOT_SRC_GODOT_EXTRA_SUFFIX? | default "")

    let target_name = match $target {
        "template" => $"($target)_($release_mode)",
        _ => $target,
    }

    mut godot_bin_name = [
        (match $godot_platform {
            "ios" => "libgodot",
            _ => "godot",
        }),
        $godot_platform,
        $target_name,
    ]

    if $env.GODOT_SRC_PRECISION == "double" {
        $godot_bin_name = ($godot_bin_name | append "double")
    }

    let arch = ($arch | default $nu.os-info.arch)

    $godot_bin_name = ($godot_bin_name | append (match $arch {
        "aarch32" => "arm32",
        "aarch64" => "arm64",
        _ => $arch,
    }))

    if $env.GODOT_SRC_GODOT_EXTRA_SUFFIX? != null and ($env.GODOT_SRC_GODOT_EXTRA_SUFFIX | str trim) != "" {
        $godot_bin_name = ($godot_bin_name | append $env.GODOT_SRC_GODOT_EXTRA_SUFFIX)
    }

    if $env.GODOT_SRC_DOTNET_ENABLED and $godot_platform != "ios" {
        $godot_bin_name = ($godot_bin_name | append "mono")
    }

    if $godot_platform == "windows" {
        $godot_bin_name = ($godot_bin_name | append "exe")
    }

    if $godot_platform == "ios" {
        $godot_bin_name = ($godot_bin_name | append "a")
    }

    let godot_bin_name = ($godot_bin_name | str join ".")
    let godot_bin = $"($godot_dir)/bin/($godot_bin_name)"

    return {
        godot_dir: $godot_dir,
        godot_bin: $godot_bin,
        godot_bin_name: $godot_bin_name,
        auto_install_godot: ($env.GODOT_SRC_AUTO_INSTALL_GODOT? | default true),
        import_env_vars: ($env.GODOT_SRC_IMPORT_ENV_VARS? | default ""),
        custom_modules: ($env.GODOT_SRC_CUSTOM_MODULES? | default "")
    }
}

# Execute a godot command.  Will install zig if it doesn't exist.
export def --wrapped "main godot run" [
    ...rest
] {
    use ../nudep/core.nu *
    use ../nudep/platform_constants.nu *
    use ../nudep

    # Update the path with dotnet if we are using it
    $env.PATH = (nudep dotnet init)

    let config = main godot config;

    if $config.auto_install_godot {
        if not ($"($config.godot_dir)/LICENSE.txt" | path exists) {
            git clone --depth 1 https://github.com/godotengine/godot.git $config.godot_dir
        }
    }

    if not ($config.godot_bin | path exists) {
        main godot build editor
    }
    
    print $"Running godot command: ($config.godot_bin) ($rest | str join ' ')"
    run-external $config.godot_bin ...$rest
}

# Build the godot editor for the host platform
export def "main godot build editor" [
    --skip-cs-glue,
    --extra-scons-args: list<string>
] {
    (main godot build 
        --release-mode "debug" 
        --skip-cs-glue=$skip_cs_glue 
        --compiledb 
        --platform $nu.os-info.name 
        --extra-scons-args $extra_scons_args)
}

export def "main godot clean editor" [] {
    use ../nudep
    use ../nudep/platform_constants.nu *
    use utils.nu

    let config = main godot config

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
        $"module_mono_enabled=($env.GODOT_SRC_DOTNET_ENABLED)"
        "compiledb=yes"
        $"precision=($env.GODOT_SRC_PRECISION)")
}

export def "main godot clean all" [] {
    use ../nudep
    use ../nudep/platform_constants.nu *
    use ../utils/utils.nu

    let config = main godot config
    utils git remove ignored $config.godot_dir
}

# Deletes godot and the directory where it is installed.  Only runs if auto_install_godot is true
export def "main godot remove" [] {
    let config = main godot config;

    if not $config.auto_install_godot {
        error make {
            msg: "Godot not auto installed. Therefore not removing godot."
        }
    }

    rm -r $config.godot_dir
}

# Build the linux template
export def "main godot build template linux" [
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
] {
    (main godot build 
        --release-mode $release_mode 
        --skip-cs-glue
        --target "template" 
        --platform "linux")
}

# Build the macos template
export def "main godot build template macos" [
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --arch: string,
] {
    let config = (main godot config --target "template" --release-mode $release_mode --arch $arch)
    cd $config.godot_dir

    if $arch == "universal" {
        let config_x86_64 = (main godot config --target "template" --release-mode $release_mode --arch "x86_64")
        let config_arm64 = (main godot config --target "template" --release-mode $release_mode --arch "arm64")

        (main godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "macos"
            --arch "x86_64")

        (main godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "macos"
            --arch "arm64")

        (lipo 
            -create 
                $"bin/($config_x86_64.godot_bin_name)"
                $"bin/($config_arm64.godot_bin_name)"
            -output $"bin/($config.godot_bin_name)")
    } else {
        (main godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "macos"
            --arch $arch)
    }

    return $config
}

# Build the macos app template.  This is the zip file that godot looks for and contains
# the debug and release macos templates.
export def "main godot build template macos app" [
    --arch: string,
    --skip-zip,
] {
    let config_debug = (main godot build template macos --arch $arch --release-mode "debug")
    let config_release = (main godot build template macos --arch $arch --release-mode "release")
    let godot_dir = $config_debug.godot_dir
    rm -rf $"($godot_dir)/bin/macos_template.app"
    cp -r $"($godot_dir)/misc/dist/macos_template.app" $"($godot_dir)/bin/"
    mkdir $"($godot_dir)/bin/macos_template.app/Contents/MacOS"
    mv $config_debug.godot_bin $"($godot_dir)/bin/macos_template.app/Contents/MacOS/godot_macos_debug.($arch)"
    mv $config_release.godot_bin $"($godot_dir)/bin/macos_template.app/Contents/MacOS/godot_macos_release.($arch)"
    chmod +x ...(glob $"($godot_dir)/bin/macos_template.app/Contents/MacOS/godot_macos*")

    if not $skip_zip {
        print $"zipping ($godot_dir)/bin/macos_template.app"
        cd $"($godot_dir)/bin"
        rm -f "macos.zip"
        run-external zip "-q" "-9" "-r" "macos.zip" "macos_template.app"
    }
}

# Build the macos template
export def "main godot build template ios" [
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --arch: string,
] {
    let config = (main godot config --target "template" --release-mode $release_mode --arch $arch --platform "ios")
    cd $config.godot_dir

    if $arch == "universal" {
        let config_x86_64 = (main godot config --target "template" --release-mode $release_mode --arch "x86_64" --platform "ios")
        let config_arm64 = (main godot config --target "template" --release-mode $release_mode --arch "arm64" --platform "ios")

        (main godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "ios"
            --arch "x86_64")

        (main godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "ios"
            --arch "arm64")

        # (lipo 
        #     -create 
        #         $"bin/($config_x86_64.godot_bin_name)"
        #         $"bin/($config_arm64.godot_bin_name)"
        #     -output $"bin/($config.godot_bin_name)")
    } else {
        (main godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "ios"
            --arch $arch)
    }

    return $config
}

# Build the macos app template.  This is the zip file that godot looks for and contains
# the debug and release macos templates.
export def "main godot build template ios app" [
    --arch: string,
    --skip-zip,
] {
    use ../nudep/multen-vk-ios.nu

    let multen_vk_config = (multen-vk-ios download)
    let config_debug = (main godot build template ios --arch $arch --release-mode "debug")
    let config_release = (main godot build template ios --arch $arch --release-mode "release")
    let godot_dir = $config_debug.godot_dir
    rm -rf $"($godot_dir)/bin/ios_xcode"
    cp -r $"($godot_dir)/misc/dist/ios_xcode" $"($godot_dir)/bin/"
    mv $config_debug.godot_bin $"($godot_dir)/bin/ios_xcode/libgodot.ios.debug.xcframework/ios-arm64/libgodot.a"
    mv $config_release.godot_bin $"($godot_dir)/bin/ios_xcode/libgodot.ios.release.xcframework/ios-arm64/libgodot.a"
    cp -r $"($multen_vk_config.version_dir)/MoltenVK/MoltenVK/static/MoltenVK.xcframework" $"($godot_dir)/bin/ios_xcode/"

    if not $skip_zip {
        print $"zipping ($godot_dir)/bin/ios_xcode"
        cd $"($godot_dir)/bin"
        rm -f "ios.zip"
        run-external zip "-q" "-9" "-r" "ios.zip" "ios_xcode"
    }
}

# Build the windows template
export def "main godot build template windows" [
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
] {
    use ../nudep/core.nu *
    use ../nudep

    # require zig to be installed
    nudep zig run version
    let zig_bin_dir = ($"(nudep zig bin)/.." | path expand)

    let godot_nir_dir = $env.GODOT_SRC_GODOT_NIR_DIR

    let prev_dir = $env.PWD
    cd $godot_nir_dir

    $env.MINGW_PREFIX = $"($env.GODOT_SRC_DIR)/zig/mingw"

    pip3 install mako

    ./update_mesa.sh

    $env.PATH = ($env.PATH | prepend $"($env.MINGW_PREFIX)/bin")
    $env.PATH = ($env.PATH | prepend $zig_bin_dir) 

    scons "platform=windows" "arch=x86_64" "use_llvm=yes"

    cd $prev_dir

    let dxc_dir = $"($env.GODOT_SRC_DIR)/gitignore/dxc"

    nudep http file $"https://github.com/microsoft/DirectXShaderCompiler/releases/download/($env.GODOT_SRC_DXC_VERSION)/($env.GODOT_SRC_DXC_DATE).zip" $"($dxc_dir)/($env.GODOT_SRC_DXC_VERSION)/($env.GODOT_SRC_DXC_DATE).zip"
    nudep decompress $"($dxc_dir)/($env.GODOT_SRC_DXC_VERSION)/($env.GODOT_SRC_DXC_DATE).zip" $"($dxc_dir)/($env.GODOT_SRC_DXC_VERSION)/dxc"

    (main godot build 
        --release-mode $release_mode 
        --skip-cs-glue 
        --target "template" 
        --platform "windows")
}

export def "main android config" [] {
    use ../nudep/android-cli.nu
    android-cli config
}

export def "main jdk config" [] {
    use ../nudep/jdk.nu
    jdk config
}

export def --wrapped "main jdk run" [
    command: string, 
    ...rest
] {
    use ../nudep/jdk.nu
    jdk run $command ...$rest
}

# Prints the fingerprint of the keystore at the provided path
export def "main android key fingerprint" [
    keystore_path: string
] {
    main jdk run keytool -keystore $keystore_path -list -v
}

# Documented here: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html#create-a-debug-keystore
# 
# Uses the following environment variables: 
# 
# GODOT_ANDROID_KEYSTORE_DEBUG_PATH
# GODOT_ANDROID_KEYSTORE_DEBUG_USER
# GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
export def "main android key create debug" [] {
    $env.GODOT_ANDROID_KEYSTORE_DEBUG_PATH = ($env.GODOT_ANDROID_KEYSTORE_DEBUG_PATH? | default $"($env.FILE_PWD)/debug.keystore")
    $env.GODOT_ANDROID_KEYSTORE_DEBUG_USER = ($env.GODOT_ANDROID_KEYSTORE_DEBUG_USER? | default "androiddebugkey")
    $env.GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = ($env.GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD? | default "android")

    (main android key create
        $env.GODOT_ANDROID_KEYSTORE_DEBUG_PATH
        $env.GODOT_ANDROID_KEYSTORE_DEBUG_USER
        $env.GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
        $env.GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
        "CN=Android Debug,O=Android,C=US"
        9999)
}

export def "main android key create" [
    keystore_path: string,
    alias: string,
    keypass: string,
    storepass: string,
    dname: string,
    validity: int
] {
    if ($keystore_path | path exists) {
        print $"Keystore at path already exists: ($keystore_path)"
        return
    }

    print $"Creating keystore at path: ($keystore_path)"

    (main jdk run keytool 
        "-keyalg" "RSA" 
        "-genkeypair" 
        "-alias" $alias 
        "-keypass" $keypass 
        "-keystore" $keystore_path 
        "-storepass" $storepass 
        "-dname" $dname 
        "-validity" $validity 
        "-deststoretype" "pkcs12")
}

export def --wrapped "main android adb run" [
    ...rest
] {
    run-external $"(main android config | get "cli_version_dir")/sdk/platform-tools/adb" ...$rest
}

# Build the android template
export def "main godot build template android" [
    # The architectures to build for. Defaults to: [ "arm32", "arm64", "x86_32", "x86_64" ]
    --archs: list<string> = [ "arm32", "arm64", "x86_32", "x86_64" ],
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
] {
    use ../utils/utils.nu
    use ../nudep/jdk.nu
    use ../nudep/android-cli.nu

    jdk download
    android-cli download

    let godot_config = main godot config

    # Gradle doesn't seem to rebuild when godot source changes.  So we need to force it.
    # Fortunately this part of the build seems to be rather quick.
    utils git remove ignored $"($godot_config.godot_dir)/platform/android/java"
    rm -rf $"($godot_config.godot_dir)/bin/android_source.zip"
    rm -rf $"($godot_config.godot_dir)/bin/android_($release_mode).apk"
    rm -rf $"($godot_config.godot_dir)/bin/godot-lib.template_($release_mode).aar"

    let android_config = main android config
    let jdk_config = main jdk config
    
    $env.PATH = ($env.PATH | prepend $jdk_config.bin_dir)
    $env.ANDROID_HOME = $"($android_config.cli_version_dir)"

    if not ($"($env.ANDROID_HOME)/cmdline-tools/latest/bin/sdkmanager" | path exists) {
        mkdir $"($env.ANDROID_HOME)/cmdline-tools/latest"
        ls -f $"($env.ANDROID_HOME)/cmdline-tools" | 
            where { |item| $item.name != $"($env.ANDROID_HOME)/cmdline-tools/latest" } | 
            each { |item| mv $item.name $"($env.ANDROID_HOME)/cmdline-tools/latest" }
    }

    (run-external $"($env.ANDROID_HOME)/cmdline-tools/latest/bin/sdkmanager" 
        $"--sdk_root=($env.ANDROID_HOME)/sdk" 
        "--licenses")
    (run-external $"($env.ANDROID_HOME)/cmdline-tools/latest/bin/sdkmanager" 
        $"--sdk_root=($env.ANDROID_HOME)/sdk" 
        "platform-tools" 
        "build-tools;30.0.3" 
        "platforms;android-29" 
        "cmdline-tools;latest" 
        "cmake;3.10.2.4988404")

    $archs | enumerate | each { |arch|
        # Always generate the apk last
        let extra_args = match ($arch.index == (($archs | length) - 1)) {
            true => [ "generate_apk=yes" ],
            false => []
        }

        (main godot build 
            --release-mode $release_mode 
            --skip-cs-glue 
            --target "template" 
            --platform "android"
            --arch $arch.item
            --extra-scons-args $extra_args)
    }
}

export def "main godot clean dotnet" [] {
    use ../utils/utils.nu
    let config = main godot config
    rm -rf $"($config.godot_dir)/bin/GodotSharp"
    utils git remove ignored $"($config.godot_dir)/modules/mono/glue/GodotSharp"
    utils git remove ignored $"($config.godot_dir)/modules/mono/editor/Godot.NET.Sdk"
    utils git remove ignored $"($config.godot_dir)/modules/mono/editor/GodotTools"
    # Remove all cached godot nuget packages to ensure they get rebuilt
    # TODO: Figure out how to publish them to a local folder
    rm -rf $"($env.HOME)/.nuget/packages/godot.net.sdk"
    rm -rf $"($env.HOME)/.nuget/packages/godot.sourcegenerators"
    rm -rf $"($env.HOME)/.nuget/packages/godotsharp"
    rm -rf $"($env.HOME)/.nuget/packages/godotsharpeditor"
}

# use --help to see commands and details
export def "main godot" [] {

}

# use --help to see commands and details
export def "main godot build" [
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --skip-cs-glue # Skips generating or rebuilding the csharp glue
    --platform: string # the platform to build for
    --compiledb, # Whether or not to compile the databse for ides
    --target: string # specify a target such as template
    --arch: string,
    --extra-scons-args: list<string>
] {
    use utils.nu godot-platform
    use ../utils/utils.nu validate_arg
    use ../nudep/platform_constants.nu *
    use ../nudep
    validate_arg $release_mode "--release-mode" ((metadata $release_mode).span) "release" "debug"

    let config = main godot config;

    if $config.auto_install_godot {
        if not ($"($config.godot_dir)/LICENSE.txt" | path exists) {
            git clone --depth 1 https://github.com/godotengine/godot.git $config.godot_dir
        }
    }

    mut scons_args = ([
        $"module_mono_enabled=($env.GODOT_SRC_DOTNET_ENABLED)",
        $"precision=($env.GODOT_SRC_PRECISION)",
        $"compiledb=($compiledb)"
    ] | append $extra_scons_args)

    if ($env.GODOT_SRC_GODOT_EXTRA_SUFFIX? | default "") != "" {
        $scons_args = ($scons_args | append [
            $"extra_suffix=($env.GODOT_SRC_GODOT_EXTRA_SUFFIX)", 
            $"object_prefix=($env.GODOT_SRC_GODOT_EXTRA_SUFFIX)", 
        ])
    }

    let zig_arch = match $arch {
        "arm64" => "aarch64"
        "arm32" | "x86_32" | "x86_64" => $arch,
        null => "x86_64",
        _ => {
            error make { msg: $"unsupported arch: ($arch)" }
        }
    }

    if $arch != null {
        $scons_args = ($scons_args | append [
            $"arch=($arch)"
        ])
    }

    match $platform {
        "windows" => {
            # require zig to be installed
            nudep zig run version
            $scons_args = ($scons_args | append [
                $"CC=(nudep zig bin) cc -target x86_64-windows"
                $"CXX=(nudep zig bin) c++ -target x86_64-windows"
                "d3d12=yes",
                "vulkan=no"
                $"dxc_path=($env.GODOT_SRC_DIR)/gitignore/dxc/($env.GODOT_SRC_DXC_VERSION)/dxc",
                $"mesa_libs=($env.GODOT_SRC_GODOT_NIR_DIR)"
            ])
        },
        "linux" => {
            # require zig to be installed
            nudep zig run version
            $scons_args = ($scons_args | append [
                $"CC=(nudep zig bin) cc -target x86_64-linux-gnu",
                $"CXX=(nudep zig bin) c++ -target x86_64-linux-gnu"
            ])
        },
        "android" => {
            $scons_args = ($scons_args | append [
                "vulkan=yes"
            ])
        },
        "macos" => {
            # TODO: Add support for building with zig
        },
        "ios" => {
            # TODO: Add support for building with zig
        },
        _ => { 
            error make {
                msg: $"unsupported platform: ($platform)"
            }
        }
    }

    let platform = godot-platform $platform
    let debug_symbols = $release_mode == "debug"

    $scons_args = ($scons_args | append [
        $"platform=($platform)",
        $"debug_symbols=($release_mode == "debug")"
    ])

    match $target {
        "template" => {
            $scons_args = ($scons_args | append $"target=template_($release_mode)")
        }
        null => {},
        _ => {
            $scons_args = ($scons_args | append $"target=($target)")
        }
    }

    # Don't use zig to compile android.  Use Google's ndk
    if $platform != "android" and $platform != "macos" and $platform != "ios" {
        # Set the global and local cache directories since scons requires it
        let zig_config = nudep zig config
        $env.ZIG_GLOBAL_CACHE_DIR = $zig_config.local_cache_dir
        $env.ZIG_LOCAL_CACHE_DIR = $zig_config.global_cache_dir
    
        match $config.import_env_vars {
            null | "" => { 
                $scons_args = ($scons_args | append "import_env_vars=ZIG_GLOBAL_CACHE_DIR,ZIG_LOCAL_CACHE_DIR")
            },
            _ => {
                $scons_args = ($scons_args | append $"import_env_vars=ZIG_GLOBAL_CACHE_DIR,ZIG_LOCAL_CACHE_DIR,($config.import_env_vars)")
            }
        }
    
        if $config.custom_modules != null and $config.custom_modules != "" {
            $scons_args = ($scons_args | append $"custom_modules=($config.custom_modules)")
        }
    }

    cd $config.godot_dir

    print $"running scons: scons ($scons_args | str join ' ')"

    # NOTE: lto=full is breaking things for now so not passing it
    run-external scons ...$scons_args

    if $env.GODOT_SRC_DOTNET_ENABLED and not $skip_cs_glue {
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
            $"--precision=($env.GODOT_SRC_PRECISION)")
        (run-external 
            $"($config.godot_dir)/modules/mono/build_scripts/build_assemblies.py"
            $"--godot-output-dir=($config.godot_dir)/bin"
            $"--precision=($env.GODOT_SRC_PRECISION)"
            $"--godot-platform=($platform)")
    }
}

# use --help to see commands and details
export def "main godot clean" [] {
}

export def --wrapped "main godot export" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --out-file: string
    --preset: string
    ...rest
] {
    use ../utils/utils.nu
    utils validate_arg_exists $out_file "--out-file" ((metadata $out_file).span)

    let out_dir = ($"($out_file)/.." | path expand)
    rm -rf $out_dir
    mkdir $out_dir
    
    main godot run --headless --path $project $"--export-($release_mode)" $preset ...$rest $out_file
}

export def "main godot export linux" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "Linux",
    --out-file: string
] {
    if not $skip_template {
        main godot build template linux --release-mode=$release_mode
    }

    $env.GODOT_SRC_GODOT_PLATFORM = "linuxbsd"
    main godot export --project=$project --release-mode=$release_mode --out-file=$out_file --preset=$preset
}

export def "main godot export windows" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "Windows Desktop"
    --out-file: string
] {
    use ../nudep/core.nu *

    if not $skip_template {
        main godot build template windows --release-mode=$release_mode
    }

    # Microsoft talks about how they intend for vc_redist to be used here: 
    #   https://learn.microsoft.com/en-us/cpp/windows/deploying-visual-cpp-application-by-using-the-vcpp-redistributable-package?view=msvc-170
    #   https://learn.microsoft.com/en-us/cpp/windows/determining-which-dlls-to-redistribute?view=msvc-170&source=recommendations
    #   https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170
    # And here's a helpful tutorial for using it without window popup prompts:
    #   https://www.asawicki.info/news_1597_installing_visual_c_redistributable_package_from_command_line.html
    let vc_redist_path = $"($env.GODOT_SRC_DIR)/gitignore/vc_redist/vc_redist.x64.exe"
    nudep http file https://aka.ms/vs/17/release/vc_redist.x64.exe $vc_redist_path

    let dxil_path = $"($env.GODOT_SRC_DIR)/gitignore/dxc/($env.GODOT_SRC_DXC_VERSION)/dxc/bin/x64/dxil.dll"
    $env.GODOT_SRC_GODOT_PLATFORM = "windows"
    main godot export --project=$project --release-mode=$release_mode --out-file=$out_file --preset=$preset
    let out_dir = ($"($out_file)/.." | path expand)
    cp $vc_redist_path $out_dir
    cp $dxil_path $out_dir
    let out_basename = ($out_file | path basename
    )
    # This is a temporary workaround until we figure out how to create an exe that installs dependencies silently before launching
    $"@echo off
    %~dp0\\vc_redist.x64.exe /install /quiet /norestart
    start %~dp0\\($out_file | path basename) %" | 
        save -f $"($out_dir)/start.bat"
}

export def --wrapped "main godot export android" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "Android"
    --out-file: string
    ...rest
] {
    if not $skip_template {
        main godot build template android --release-mode=$release_mode
    }

    let android_config = main android config
    let jdk_config = main jdk config

    $env.GODOT_SRC_GODOT_PLATFORM = "android"
    (main godot export 
        --project=$project 
        --release-mode=$release_mode 
        --out-file=$out_file 
        --preset=$preset
        ...$rest)
}

export def --wrapped "main godot export macos" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "macOS"
    --arch: string = "universal"
    --out-file: string
    ...rest
] {
    use ../utils/utils.nu validate_arg
    validate_arg $release_mode "--release-mode" ((metadata $release_mode).span) "release" "debug"

    if not $skip_template {
        main godot build template macos app --arch=$arch
    }

    $env.GODOT_SRC_GODOT_PLATFORM = "macos"
    (main godot export 
        --project=$project 
        --release-mode=$release_mode 
        --out-file=$out_file 
        --preset=$preset
        ...$rest)
}

export def --wrapped "main godot export ios" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "iOS"
    --arch: string = "arm64"
    --out-file: string
    ...rest
] {
    use ../utils/utils.nu validate_arg
    validate_arg $release_mode "--release-mode" ((metadata $release_mode).span) "release" "debug"

    if not $skip_template {
        main godot build template ios app --arch=$arch
    }

    $env.GODOT_SRC_GODOT_PLATFORM = "ios"
    (main godot export 
        --project=$project 
        --release-mode=$release_mode 
        --out-file=$out_file 
        --preset=$preset
        ...$rest)
}

export def --wrapped "main cmake run" [
    cmd: string, 
    ...rest
] {
    use ../nudep/cmake.nu
    cmake run $cmd ...$rest
}

export def --wrapped "main ninja run" [...rest] {
    use ../nudep/ninja.nu
    ninja run ...$rest
}

export def "main vulkan compile validation android" [
    android_libs_path: string,
    --release-mode: string,
] {
    use ../nudep/vulkan-validation-layers.nu
    vulkan-validation-layers compile android $android_libs_path "arm64-v8a" --release-mode=$release_mode
    # vulkan-validation-layers compile android $android_libs_path "x86_64" --release-mode=$release_mode
}