use ../nudep
use utils.nu

# Forcefully opt into building windows
$env.GODOT_CAN_BUILD_WINDOWS = "true"
$env.GODOT_SRC_DOTNET_ENABLED = ($env.GODOT_SRC_DOTNET_ENABLED? | default false)
$env.GODOT_SRC_DOTNET_USE_SYSTEM = ($env.GODOT_SRC_DOTNET_USE_SYSTEM? | default false)
$env.GODOT_SRC_GODOT_EXTRA_SUFFIX = ($env.GODOT_SRC_GODOT_EXTRA_SUFFIX? | default "")
$env.GODOT_SRC_PRECISION = ($env.GODOT_SRC_PRECISION? | default "single")
$env.GODOT_SRC_DXC_VERSION = ($env.GODOT_SRC_DXC_VERSION? | default "v1.8.2403.1")
$env.GODOT_SRC_DXC_DATE = ($env.GODOT_SRC_DXC_DATE? | default "dxc_2024_03_22")
$env.GODOT_SRC_GODOT_USE_LLVM = ($env.GODOT_SRC_GODOT_USE_LLVM? | default true)
# gnu or msvc. Gnu uses the mingw toolchain.
$env.GODOT_SRC_WINDOWS_ABI = ($env.GODOT_SRC_WINDOWS_ABI? | default "gnu")

# Default godot's platform to the host machine unless specified otherwise and make sure dotnet
# is set up for the host machine
$env.GODOT_SRC_GODOT_PLATFORM = ($env.GODOT_SRC_GODOT_PLATFORM? | default (utils godot-platform $nu.os-info.name))
$env.PATH = (nudep dotnet env-path)
$env.PATH = ($env.PATH | prepend $"($env.GODOT_SRC_DIR)/gitignore/pixi/bin")
$env.GODOT_SRC_ANDROID_VERSION = ($env.GODOT_SRC_ANDROID_VERSION? | default "24")
$env.GODOT_SRC_ANDROID_SC_EDITOR_SETTINGS = ($env.GODOT_SRC_ANDROID_SC_EDITOR_SETTINGS? | default true)
$env.GODOT_ANDROID_KEYSTORE_DEBUG_PATH = $env.GODOT_ANDROID_KEYSTORE_DEBUG_PATH? | default $"($env.GODOT_SRC_DIR)/debug.keystore"
$env.GODOT_ANDROID_KEYSTORE_DEBUG_USER = ($env.GODOT_ANDROID_KEYSTORE_DEBUG_USER? | default "androiddebugkey")
$env.GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = ($env.GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD? | default "android")

export def "gsrc install build-tools" [] {
    print "Installing dotnet..."
    nudep dotnet init
    print "Dotnet installed successfully!"
    print "Installing pixi dependencies..."
    gsrc pixi install --manifest-path $"($env.GODOT_SRC_DIR)/pixi.toml"
    print "Pixi dependencies installed successfully!"
}

export def "gsrc godot config" [
    --target: string = "editor",
    --release-mode: string = "debug",
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

    if $env.GODOT_SRC_GODOT_USE_LLVM and ($godot_platform == "windows" or $godot_platform == "linuxbsd") {
        $godot_bin_name = ($godot_bin_name | append "llvm")
    }

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
    let godot_bin_dir = $"($godot_dir)/bin"
    let godot_bin = $"($godot_bin_dir)/($godot_bin_name)"

    return {
        godot_dir: $godot_dir,
        godot_bin_dir: $godot_bin_dir,
        godot_bin: $godot_bin,
        godot_bin_name: $godot_bin_name,
        auto_install_godot: ($env.GODOT_SRC_AUTO_INSTALL_GODOT? | default true),
        import_env_vars: ($env.GODOT_SRC_IMPORT_ENV_VARS? | default ""),
        custom_modules: ($env.GODOT_SRC_CUSTOM_MODULES? | default "")
    }
}

# Execute a godot command.  Will install zig if it doesn't exist.
export def --wrapped "gsrc godot run" [
    ...rest
] {
    use ../nudep/core.nu *
    use ../nudep/platform_constants.nu *
    use ../nudep

    # Use the gsrc installed dotnet instead of the system dotnet
    load-env (nudep dotnet godot-dotnet-env)

    mut rest = $rest

    # Update the path with dotnet if we are using it
    $env.PATH = (nudep dotnet env-path)

    let config = gsrc godot config;

    if $config.auto_install_godot {
        if not ($"($config.godot_dir)/LICENSE.txt" | path exists) {
            git clone --depth 1 --branch 4.4-stable-ls https://github.com/Lange-Studios/godot.git $config.godot_dir
        }
    }

    if not ($config.godot_bin | path exists) {
        gsrc godot build editor
    }

    if $env.GODOT_SRC_DOTNET_ENABLED {
        gsrc godot build dotnet-glue
    }
    
    if (($env.GODOT_SRC_GODOT_CLI_ARGS? | default []) | length) > 0 {
        $rest = ($rest | append $env.GODOT_SRC_GODOT_CLI_ARGS)
    }

    print $"Running godot command: ($config.godot_bin) ($rest | str join ' ')"
    run-external $config.godot_bin ...$rest
}

# Build the godot editor for the host platform
export def "gsrc godot build editor" [
    --skip-cs-glue,
    --extra-scons-args: list<string>
] {
    (gsrc godot build 
        --release-mode "debug" 
        --skip-cs-glue=$skip_cs_glue 
        --compiledb 
        --platform $nu.os-info.name 
        --extra-scons-args $extra_scons_args
    )
}

export def "gsrc godot clean editor" [] {
    use ../nudep
    use ../nudep/platform_constants.nu *
    use utils.nu

    let config = gsrc godot config

    rm $config.godot_bin
    mkdir $"($config.godot_dir)/GodotSharp/Tools/nupkgs"
    let platform = utils godot-platform $nu.os-info.name
    cd $config.godot_dir
    (run-external "scons" 
        "--clean"
        $"platform=($platform)"
        $"use_llvm=($env.GODOT_SRC_GODOT_USE_LLVM)"
        "debug_symbols=yes"
        $"module_mono_enabled=($env.GODOT_SRC_DOTNET_ENABLED)"
        "compiledb=yes"
        $"precision=($env.GODOT_SRC_PRECISION)"
    )
}

export def "gsrc godot clean all" [] {
    use ../nudep
    use ../nudep/platform_constants.nu *
    use ../utils/utils.nu

    let config = gsrc godot config
    utils git remove ignored $config.godot_dir
}

# Deletes godot and the directory where it is installed.  Only runs if auto_install_godot is true
export def "gsrc godot remove" [] {
    let config = gsrc godot config;

    if not $config.auto_install_godot {
        error make {
            msg: "Godot not auto installed. Therefore not removing godot."
        }
    }

    rm -r $config.godot_dir
}

# Build the linux template
export def "gsrc godot build template linux" [
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
] {
    (gsrc godot build 
        --release-mode $release_mode 
        --skip-cs-glue
        --target "template" 
        --platform "linux"
    )
}

# Build the macos template
export def "gsrc godot build template macos" [
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --arch: string,
] {
    let config = (gsrc godot config --target "template" --release-mode $release_mode --arch $arch)
    cd $config.godot_dir

    if $arch == "universal" {
        let config_x86_64 = (gsrc godot config --target "template" --release-mode $release_mode --arch "x86_64")
        let config_arm64 = (gsrc godot config --target "template" --release-mode $release_mode --arch "arm64")

        (gsrc godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "macos"
            --arch "x86_64"
            )

        (gsrc godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "macos"
            --arch "arm64"
        )

        (lipo 
            -create 
                $"bin/($config_x86_64.godot_bin_name)"
                $"bin/($config_arm64.godot_bin_name)"
            -output $"bin/($config.godot_bin_name)"
        )
    } else {
        (gsrc godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "macos"
            --arch $arch
        )
    }

    return $config
}

# Build the macos app template.  This is the zip file that godot looks for and contains
# the debug and release macos templates.
export def "gsrc godot build template macos app" [
    --arch: string,
    --skip-zip,
    --skip-debug,
    --skip-release,
] {
    let godot_config = gsrc godot config
    let godot_dir = $godot_config.godot_dir
    rm -rf $"($godot_dir)/bin/macos_template.app"
    cp -r $"($godot_dir)/misc/dist/macos_template.app" $"($godot_dir)/bin/"
    mkdir $"($godot_dir)/bin/macos_template.app/Contents/MacOS"
    if not $skip_debug {
        let config_debug = (gsrc godot build template macos --arch $arch --release-mode "debug")
        mv $config_debug.godot_bin $"($godot_dir)/bin/macos_template.app/Contents/MacOS/godot_macos_debug.($arch)"
    }
    
    if not $skip_release {
        let config_release = (gsrc godot build template macos --arch $arch --release-mode "release")
        mv $config_release.godot_bin $"($godot_dir)/bin/macos_template.app/Contents/MacOS/godot_macos_release.($arch)"
    }

    chmod +x ...(glob $"($godot_dir)/bin/macos_template.app/Contents/MacOS/godot_macos*")

    if not $skip_zip {
        print $"zipping ($godot_dir)/bin/macos_template.app"
        cd $"($godot_dir)/bin"
        rm -f "macos.zip"
        run-external zip "-q" "-9" "-r" "macos.zip" "macos_template.app"
    }
}

# Build the macos template
export def "gsrc godot build template ios" [
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --arch: string,
    --skip-lto,
] {
    let config = (gsrc godot config --target "template" --release-mode $release_mode --arch $arch --platform "ios")
    cd $config.godot_dir

    if $arch == "universal" {
        let config_x86_64 = (gsrc godot config --target "template" --release-mode $release_mode --arch "x86_64" --platform "ios")
        let config_arm64 = (gsrc godot config --target "template" --release-mode $release_mode --arch "arm64" --platform "ios")

        (gsrc godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "ios"
            --arch "x86_64"
            --skip-lto=$skip_lto
        )

        (gsrc godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "ios"
            --arch "arm64"
            --skip-lto=$skip_lto
        )

        # (lipo 
        #     -create 
        #         $"bin/($config_x86_64.godot_bin_name)"
        #         $"bin/($config_arm64.godot_bin_name)"
        #     -output $"bin/($config.godot_bin_name)")
    } else {
        (gsrc godot build
            --release-mode $release_mode
            --skip-cs-glue
            --target "template"
            --platform "ios"
            --arch $arch
            --skip-lto=$skip_lto
        )
    }

    return $config
}

# Build the macos app template.  This is the zip file that godot looks for and contains
# the debug and release macos templates.
export def "gsrc godot build template ios app" [
    --arch: string,
    --skip-zip,
    --skip-debug,
    --skip-release,
    --skip-lto,
] {
    use ../nudep/multen-vk-ios.nu

    let godot_config = gsrc godot config
    let multen_vk_config = (multen-vk-ios download)
    let godot_dir = $godot_config.godot_dir
    rm -rf $"($godot_dir)/bin/ios_xcode"
    cp -r $"($godot_dir)/misc/dist/ios_xcode" $"($godot_dir)/bin/"
    
    if not $skip_debug {
        let config_debug = (gsrc godot build template ios --arch $arch --release-mode "debug" --skip-lto=$skip_lto)
        mv $config_debug.godot_bin $"($godot_dir)/bin/ios_xcode/libgodot.ios.debug.xcframework/ios-arm64/libgodot.a"
    }

    if not $skip_release {
        let config_release = (gsrc godot build template ios --arch $arch --release-mode "release" --skip-lto=$skip_lto)
        mv $config_release.godot_bin $"($godot_dir)/bin/ios_xcode/libgodot.ios.release.xcframework/ios-arm64/libgodot.a"
    }

    cp -r $"($multen_vk_config.version_dir)/MoltenVK/MoltenVK/static/MoltenVK.xcframework" $"($godot_dir)/bin/ios_xcode/"

    if not $skip_zip {
        print $"zipping ($godot_dir)/bin/ios_xcode"
        cd $"($godot_dir)/bin/ios_xcode"
        run-external zip "-q" "-9" "-r" "ios.zip" .
        mv -f "ios.zip" "../"
    }
}

export def "gsrc godot build godot-nir" [] {
    use ../nudep/core.nu *
    use ../nudep

    let zig_config = nudep zig config
    $env.ZIG_GLOBAL_CACHE_DIR = $zig_config.local_cache_dir
    $env.ZIG_LOCAL_CACHE_DIR = $zig_config.global_cache_dir

    let godot_src_dxc_version = ($env.GODOT_SRC_DXC_VERSION? | default "v1.8.2403.1")
    let godot_src_dxc_date = ($env.GODOT_SRC_DXC_DATE? | default "dxc_2024_03_22")

    let godot_nir_dir = $env.GODOT_SRC_GODOT_NIR_DIR

    let prev_dir = $env.PWD
    cd $godot_nir_dir

    bash update_mesa.sh

    let zig_target = match $env.GODOT_SRC_WINDOWS_ABI {
        "gnu" => "x86_64-windows-gnu",
        "msvc" => "x86_64-windows"
    }

    load-env (gsrc zig cxx env-vars-wrapped $zig_target)

    let extra_args = match $nu.os-info.name {
        "windows" => [
            "ARCOM=${TEMPFILE('$AR rcs $TARGET $SOURCES','$ARCOMSTR')}",
            "--ignore-errors",
        ],
        _ => []
    }

    (run-external "scons" 
        "platform=windows" 
        "arch=x86_64" 
        "use_llvm=true"
        "platform_tools=false"
        "import_env_vars=ZIG_GLOBAL_CACHE_DIR,ZIG_LOCAL_CACHE_DIR"
        "use_mingw=true"
        "-j" (sys cpu | length)
        ...$extra_args
        ...(gsrc zig cxx scons-vars $zig_target))

    cd $prev_dir

    gsrc download dxc
}

# Build the windows template
export def "gsrc godot build template windows" [
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
] {
    (gsrc godot build 
        --release-mode $release_mode 
        --skip-cs-glue 
        --target "template" 
        --platform "windows")
}

export def "gsrc android config" [] {
    use ../nudep/android-cli.nu
    android-cli config
}

export def "gsrc jdk config" [] {
    use ../nudep/jdk.nu
    jdk config
}

export def --wrapped "gsrc jdk run" [
    command: string, 
    ...rest
] {
    use ../nudep/jdk.nu
    jdk run $command ...$rest
}

# Prints the fingerprint of the keystore at the provided path
export def "gsrc android key fingerprint" [
    keystore_path: string
] {
    gsrc jdk run keytool -keystore $keystore_path -list -v
}

# Documented here: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html#create-a-debug-keystore
# 
# Uses the following environment variables: 
# 
# GODOT_ANDROID_KEYSTORE_DEBUG_PATH
# GODOT_ANDROID_KEYSTORE_DEBUG_USER
# GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
export def "gsrc android key create debug" [] {
    (gsrc android key create
        $env.GODOT_ANDROID_KEYSTORE_DEBUG_PATH
        $env.GODOT_ANDROID_KEYSTORE_DEBUG_USER
        $env.GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
        "CN=Android Debug,O=Android,C=US"
        99999
    )
}

export def "gsrc android key create" [
    keystore_path: string,
    alias: string,
    password: string,
    dname: string,
    validity: int
] {
    if ($keystore_path | path exists) {
        print $"Keystore at path already exists: ($keystore_path)"
        return
    }

    print $"Creating keystore at path: ($keystore_path)"

    (gsrc jdk run keytool 
        "-keyalg" "RSA" 
        "-genkeypair" 
        "-alias" $alias 
        "-keypass" $password 
        "-keystore" $keystore_path 
        "-storepass" $password 
        "-dname" $dname 
        "-validity" $validity 
        "-deststoretype" "pkcs12")
}

export def --wrapped "gsrc adb run" [
    ...rest
] {
    run-external $"(gsrc android config | get "cli_version_dir")/platform-tools/adb" ...$rest
}

export def "gsrc android setup-cli" [] {
    use ../utils/utils.nu
    use ../nudep/jdk.nu
    use ../nudep/android-cli.nu

    jdk download
    android-cli download

    let android_config = gsrc android config
    let jdk_config = gsrc jdk config
    
    $env.PATH = ($env.PATH | prepend $jdk_config.bin_dir)
    $env.ANDROID_HOME = $android_config.cli_version_dir
    $env.ANDROID_SDK_ROOT = $android_config.cli_version_dir
    $env.ANDROID_NDK_HOME = $android_config.ndk_dir
    $env.JAVA_HOME = $jdk_config.home_dir

    let sdk_manager_ext = match $nu.os-info.name {
        "windows" => ".bat",
        _ => ""
    }

    # Only run the installer if we haven't installed.
    if not ($"($env.ANDROID_HOME)/cmdline-tools/latest/NOTICE.txt" | path exists) {
        # Most online docs reccomend putting sdk_root in ANDROID_HOME/sdk but scons seems to want it in the
        # same directory as ANDROID_HOME
        if $"($env.GODOT_SRC_AUTO_ACCEPT_ANDROID_SDK_LICENSES? | default "false")" == "true" {
            print "auto accepting android sdkmanager licenses..."
            (yes | run-external $"($env.ANDROID_HOME)/cmdline-tools/bin/sdkmanager($sdk_manager_ext)"
                $"--sdk_root=($env.ANDROID_HOME)" 
                "--licenses"
            )
        } else {
            (run-external $"($env.ANDROID_HOME)/cmdline-tools/bin/sdkmanager($sdk_manager_ext)"
                $"--sdk_root=($env.ANDROID_HOME)" 
                "--licenses"
            )
        }
        
        (run-external $"($env.ANDROID_HOME)/cmdline-tools/bin/sdkmanager($sdk_manager_ext)"
            $"--sdk_root=($env.ANDROID_HOME)"
            "platform-tools"
            $"build-tools;($android_config.build_tools_version)"
            "platforms;android-34"
            "cmdline-tools;latest"
            "cmake;3.10.2.4988404"
            $"ndk;($android_config.ndk_version)")
    }
}

# Build the android template
export def "gsrc godot build template android" [
    # The architectures to build for. Defaults to: [ "arm32", "arm64", "x86_32", "x86_64" ]
    --archs: list<string> = [ "arm32", "arm64", "x86_32", "x86_64" ],
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
] {
    use ../utils/utils.nu
    use ../nudep/jdk.nu
    use ../nudep/android-cli.nu
    use ../nudep/android-agdk.nu

    jdk download
    android-cli download
    android-agdk download
    let android_gdk_config = android-agdk config
    let godot_config = gsrc godot config

    mkdir -v $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/arm64-v8a"
    mkdir -v $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/armeabi-v7a"
    mkdir -v $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/x86_64"
    mkdir -v $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/x86"
    (cp -fv $"($android_gdk_config.version_dir)/libs/arm64-v8a_cpp_static_Release/libswappy_static.a"
        $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/arm64-v8a/libswappy_static.a"
    )
    (cp -fv $"($android_gdk_config.version_dir)/libs/armeabi-v7a_cpp_static_Release/libswappy_static.a"
        $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/armeabi-v7a/libswappy_static.a"
    )
    (cp -fv $"($android_gdk_config.version_dir)/libs/x86_64_cpp_static_Release/libswappy_static.a"
        $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/x86_64/libswappy_static.a"
    )
    (cp -fv $"($android_gdk_config.version_dir)/libs/x86_cpp_static_Release/libswappy_static.a"
        $"($godot_config.godot_dir)/thirdparty/swappy-frame-pacing/x86/libswappy_static.a"
    )

    # Gradle doesn't seem to rebuild when godot source changes.  So we need to force it.
    # Fortunately this part of the build seems to be rather quick.
    utils git remove ignored $"($godot_config.godot_dir)/platform/android/java"
    rm -rf $"($godot_config.godot_dir)/bin/android_source.zip"
    rm -rf $"($godot_config.godot_dir)/bin/android_($release_mode).apk"
    rm -rf $"($godot_config.godot_dir)/bin/godot-lib.template_($release_mode).aar"

    let android_config = gsrc android config
    let jdk_config = gsrc jdk config
    
    $env.PATH = ($env.PATH | prepend $jdk_config.bin_dir)
    $env.ANDROID_HOME = $android_config.cli_version_dir
    $env.ANDROID_SDK_ROOT = $android_config.cli_version_dir
    $env.ANDROID_NDK_HOME = $android_config.ndk_dir
    $env.JAVA_HOME = $jdk_config.home_dir

    gsrc android setup-cli
    
    $archs | enumerate | each { |arch|
        # Always generate the apk last
        let extra_args = match ($arch.index == (($archs | length) - 1)) {
            true => [ "generate_android_binaries=yes" ],
            false => []
        }

        (gsrc godot build 
            --release-mode $release_mode 
            --skip-cs-glue 
            --target "template" 
            --platform "android"
            --arch $arch.item
            --extra-scons-args $extra_args)
    }
}

export def "gsrc godot clean dotnet" [] {
    use ../utils/utils.nu
    let config = gsrc godot config
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
export def "gsrc godot" [] {

}

# use --help to see commands and details
export def "gsrc godot build" [
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --skip-cs-glue # Skips generating or rebuilding the csharp glue
    --skip-lto # skips lto even in a release build
    --lto-mode: string = "thin" # The kind of lto to use: [auto, full, thin]
    --platform: string # the platform to build for
    --compiledb, # Whether or not to compile the databse for ides
    --target: string # specify a target such as template
    --arch: string,
    --extra-scons-args: list<string>
    --if-not-exist
] {
    use utils.nu godot-platform
    use ../utils/utils.nu validate_arg
    use ../nudep/platform_constants.nu *
    use ../nudep
    validate_arg $release_mode "--release-mode" ((metadata $release_mode).span) "release" "debug"

    let config = gsrc godot config;

    if $if_not_exist and ($config.godot_bin | path exists) {
        return
    }

    # TODO: Only do this if we are building macos with vulkan support
    if $platform == "macos" {
        run-external $"($config.godot_dir)/misc/scripts/install_vulkan_sdk_macos.sh"
    }

    let skip_nir = ($env.GODOT_SRC_SKIP_NIR? | default "false")

    mut zig_target = ""

    # Godot nir is required for windows dx12
    if $platform == "windows" and $"($skip_nir)" != "true" {
        gsrc godot build godot-nir
    }

    if $config.auto_install_godot {
        if not ($"($config.godot_dir)/LICENSE.txt" | path exists) {
            git clone --depth 1 https://github.com/godotengine/godot.git $config.godot_dir
        }
    }

    mut scons_args = ([
        $"module_mono_enabled=($env.GODOT_SRC_DOTNET_ENABLED)"
        $"precision=($env.GODOT_SRC_PRECISION)"
        $"compiledb=($compiledb)"
        $"use_llvm=($env.GODOT_SRC_GODOT_USE_LLVM)"
        "verbose=true"
        "accesskit=false" # TODO: Figure out why access kit is failing when targeting windows
        "-j" (sys cpu | length)
    ] | append $extra_scons_args | append $env.GODOT_SRC_EXTRA_SCONS_ARGS?)

    if $nu.os-info.name == "windows" {
        $scons_args = ($scons_args | append [
            "ARCOM=${TEMPFILE('$AR rcs $TARGET $SOURCES','$ARCOMSTR')}",
            "--ignore-errors",
        ])
    }

    if $platform == "windows" {
        $scons_args = ($scons_args | append "use_mingw=true")
    }

    # LTO doesn't work on windows for some reason.  Causes a lot of undefined symbols errors.
    if not $skip_lto and $release_mode == "release" {
        $scons_args = ($scons_args | append $"lto=($lto_mode)")
    }

    if ($env.GODOT_SRC_GODOT_EXTRA_SUFFIX? | default "") != "" {
        $scons_args = ($scons_args | append [
            $"extra_suffix=($env.GODOT_SRC_GODOT_EXTRA_SUFFIX)"
            $"object_prefix=($env.GODOT_SRC_GODOT_EXTRA_SUFFIX)"
        ])
    }

    let zig_arch = match $arch {
        "arm64" => "aarch64"
        "arm32" | "x86_32" | "x86_64" => $arch
        null => "x86_64"
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
            $zig_target = match $env.GODOT_SRC_WINDOWS_ABI {
                "gnu" => "x86_64-windows-gnu",
                "msvc" => "x86_64-windows"
            }
            $scons_args = ($scons_args | append (gsrc zig cxx scons-vars $zig_target) | append [
                "d3d12=yes"
                $"dxc_path=($env.GODOT_SRC_DIR)/gitignore/dxc/($env.GODOT_SRC_DXC_VERSION)/dxc"
                $"mesa_libs=($env.GODOT_SRC_GODOT_NIR_DIR)"
                "platform_tools=false"
                # Set this to false because zig automatically builds llvm's cpp from source and links statically
                # See: https://github.com/ziglang/zig/blob/master/src%2Flibcxx.zig
                "use_static_cpp=false",
                "use_windres=false",
                "validate_target_platform=false",
                "manual_build_res_file=true"
            ])
        },
        "linux" => {
            $zig_target = "x86_64-linux-gnu"
            $scons_args = ($scons_args | append (gsrc zig cxx scons-vars "x86_64-linux-gnu") | append [
                "use_libatomic=false" # false here because we are letting zig handle it
                "use_static_cpp=false" # false here because we are specifying static libc++ above
                "platform_tools=false" # Tell godot's build system to not override our CC, CXX, etc.
                # Set this to false because zig automatically builds llvm's cpp from source and links statically
                # See: https://github.com/ziglang/zig/blob/master/src%2Flibcxx.zig
                "use_static_cpp=false"
            ])
        },
        "android" => {
            # TODO: Add support for building with zig
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
    }

    if $config.custom_modules != null and not ($config.custom_modules | is-empty) {
        $scons_args = ($scons_args | append $"custom_modules=($config.custom_modules)")
    }

    cd $config.godot_dir

    print $"running scons: scons ($scons_args | str join ' ')"

    load-env (match ($zig_target != "") {
        true => {
            (gsrc zig cxx env-vars-wrapped $zig_target)
        }
        false => {{}}
    })

    run-external "scons" ...$scons_args

    if $env.GODOT_SRC_DOTNET_ENABLED and not $skip_cs_glue {
        gsrc godot build dotnet-glue --force --platform $platform
    }
}

export def "gsrc godot build dotnet-glue" [
    --platform: string = $nu.os-info.name
    --force
] {
    let platform = utils godot-platform $platform
    mut do_build = $force

    let godot_config = gsrc godot config
    let csharp_build_info = $"($godot_config.godot_bin_dir)/GodotSharp/info.txt"
    let expected_info_contents = $"($env.GODOT_SRC_GODOT_EXTRA_SUFFIX)_($env.GODOT_SRC_PRECISION)_($platform)"

    if not $do_build {
        $do_build = (not ($csharp_build_info | path exists))
    }

    mut actual_info_contents = ""

    if not $do_build {
        $actual_info_contents = ($csharp_build_info | open | str trim)
        if $actual_info_contents == "" or $actual_info_contents != $expected_info_contents {
            $do_build = true
            rm -rf $"($godot_config.godot_bin_dir)/GodotSharp_($actual_info_contents)"
            (mv -f
                $"($godot_config.godot_bin_dir)/GodotSharp"
                $"($godot_config.godot_bin_dir)/GodotSharp_($actual_info_contents)"
            )
        }
    }
    
    if $do_build {
        let cached_csharp = $"($godot_config.godot_bin_dir)/GodotSharp_($expected_info_contents)"
        if ($cached_csharp | path exists) {
            mv $cached_csharp $"($godot_config.godot_bin_dir)/GodotSharp"
            return
        }

        gsrc godot clean dotnet
        # The directory where godot will be built out to
        mkdir $godot_config.godot_bin_dir
        # This folder needs to exist in order for the nuget packages to be output here
        mkdir $"($godot_config.godot_bin_dir)/GodotSharp/Tools/nupkgs"
        (run-external 
            $godot_config.godot_bin 
            "--headless" 
            "--generate-mono-glue" 
            $"($godot_config.godot_dir)/modules/mono/glue" 
            $"--precision=($env.GODOT_SRC_PRECISION)"
        )
        (run-external 
            "python3"
            $"($godot_config.godot_dir)/modules/mono/build_scripts/build_assemblies.py"
            $"--godot-output-dir=($godot_config.godot_bin_dir)"
            $"--precision=($env.GODOT_SRC_PRECISION)"
            $"--godot-platform=($platform)"
        )

        $expected_info_contents | save -f $csharp_build_info
    }
}

# use --help to see commands and details
export def "gsrc godot clean" [] {
}

export def --wrapped "gsrc export" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --out-file: string
    --preset: string
    ...rest
] {
    use ../utils/utils.nu
    utils validate_arg_exists $out_file "--out-file" ((metadata $out_file).span)

    let out_dir = ($"($out_file)/.." | path expand)
    rm -rf $out_dir
    mkdir $out_dir
    
    gsrc godot run --path $project $"--export-($release_mode)" $preset ...$rest $out_file
    print $"Successfully exported to: ($out_file)"
}

export def --wrapped "gsrc export linux" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "Linux",
    --out-file: string
    ...rest
] {
    if not $skip_template {
        gsrc godot build template linux --release-mode=$release_mode
    }

    $env.GODOT_SRC_GODOT_PLATFORM = "linuxbsd"
    gsrc export --project=$project --release-mode=$release_mode --out-file=$out_file --preset=$preset ...$rest
}

export def "gsrc download dxc" [] {
    use ../nudep/core.nu *

    let config = gsrc godot config

    let dxc_dir = $"($env.GODOT_SRC_DIR)/gitignore/dxc"
    nudep http file $"https://github.com/microsoft/DirectXShaderCompiler/releases/download/($env.GODOT_SRC_DXC_VERSION)/($env.GODOT_SRC_DXC_DATE).zip" $"($dxc_dir)/($env.GODOT_SRC_DXC_VERSION)/($env.GODOT_SRC_DXC_DATE).zip"
    nudep decompress $"($dxc_dir)/($env.GODOT_SRC_DXC_VERSION)/($env.GODOT_SRC_DXC_DATE).zip" $"($dxc_dir)/($env.GODOT_SRC_DXC_VERSION)/dxc"
    cp -f $"($dxc_dir)/($env.GODOT_SRC_DXC_VERSION)/dxc/bin/x64/dxil.dll" $"($config.godot_bin_dir)/dxil.dll"
}

export def --wrapped "gsrc export windows" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "Windows Desktop"
    --out-file: string
    ...rest
] {
    use ../nudep/core.nu *
    $env.GODOT_SRC_GODOT_PLATFORM = "windows"

    gsrc download dxc

    if not $skip_template {
        gsrc godot build template windows --release-mode=$release_mode
    }

    gsrc export --project=$project --release-mode=$release_mode --out-file=$out_file --preset=$preset ...$rest
    let out_dir = ($"($out_file)/.." | path expand)
    let dxil_path = $"($env.GODOT_SRC_DIR)/gitignore/dxc/($env.GODOT_SRC_DXC_VERSION)/dxc/bin/x64/dxil.dll"
    mkdir $out_dir
    cp -f $dxil_path $out_dir

    if $env.GODOT_SRC_WINDOWS_ABI == "msvc" {
        # Microsoft talks about how they intend for vc_redist to be used here: 
        #   https://learn.microsoft.com/en-us/cpp/windows/deploying-visual-cpp-application-by-using-the-vcpp-redistributable-package?view=msvc-170
        #   https://learn.microsoft.com/en-us/cpp/windows/determining-which-dlls-to-redistribute?view=msvc-170&source=recommendations
        #   https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170
        # And here's a helpful tutorial for using it without window popup prompts:
        #   https://www.asawicki.info/news_1597_installing_visual_c_redistributable_package_from_command_line.html
        let vc_redist_path = $"($env.GODOT_SRC_DIR)/gitignore/vc_redist/vc_redist.x64.exe"
        nudep http file https://aka.ms/vs/17/release/vc_redist.x64.exe $vc_redist_path
        cp $vc_redist_path $out_dir
        
        # This is a temporary workaround until we figure out how to create an exe that installs dependencies silently before launching
        $"@echo off
        %~dp0\\vc_redist.x64.exe /install /quiet /norestart
        start %~dp0\\($out_file | path basename) %" | 
            save -f $"($out_dir)/start.bat"
    }
}

export def --wrapped "gsrc export android" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "Android"
    --out-file: string
    ...rest
] {
    use utils.nu "to unix-path"
    $env.GODOT_SRC_GODOT_PLATFORM = "android"

    if not $skip_template {
        gsrc godot build template android --release-mode=$release_mode
    }

    let jdk_config = gsrc jdk config
    let android_config = gsrc android config

    $env.PATH = ($env.PATH | append $jdk_config.bin_dir)
    $env.JAVA_HOME = $jdk_config.home_dir
    $env.ANDROID_HOME = $android_config.cli_version_dir
    $env.ANDROID_SDK_ROOT = $android_config.cli_version_dir
    $env.ANDROID_NDK_HOME = $android_config.ndk_dir

    if ($env.GODOT_SRC_ANDROID_SC_EDITOR_SETTINGS? | default true) {
        if $release_mode == "debug" {
            let android_keystore_debug_path = ($env.GODOT_ANDROID_KEYSTORE_DEBUG_PATH? | default $"($env.GODOT_SRC_DIR)/debug.keystore")

            if not ($android_keystore_debug_path | path exists) {
                gsrc android key create debug
            }
        }

        let godot_config = gsrc godot config
        let editor_data_path = $"($godot_config.godot_bin_dir)/editor_data"
        let sc_path = $"($godot_config.godot_bin_dir)/_sc_"
        rm -rf $editor_data_path
        # Set godot to be in self contained mode so we can set android settings that can only be set
        # at the editor level: https://docs.godotengine.org/en/latest/tutorials/io/data_paths.html#self-contained-mode
        touch $sc_path

        gsrc godot run --headless --editor --quit

        mut do_append_java_sdk_path = true
        mut do_append_android_sdk_path = true
        let java_sdk_setting = "export/android/java_sdk_path"
        let android_sdk_setting = "export/android/android_sdk_path"
        let java_sdk_setting_assign = $"($java_sdk_setting) = \"($jdk_config.home_dir | str replace --all '\' '/')\""
        let android_sdk_setting_assign = $"($android_sdk_setting) = \"($android_config.cli_version_dir | str replace --all '\' '/')\""
        let godot_settings_path = (glob ($"($env.GODOT_SRC_GODOT_DIR)/bin/editor_data/editor_settings-*.tres" | to unix-path) | first)
        mut godot_settings = ($godot_settings_path | open | split row "\n")

        for setting in $godot_settings {
            if ($setting | str starts-with $java_sdk_setting) {
                $do_append_java_sdk_path = false
                $java_sdk_setting_assign
            } else if ($setting | str starts-with $android_sdk_setting) {
                $do_append_android_sdk_path = false
                $android_sdk_setting_assign
            } else {
                $setting
            }
        }

        if $do_append_java_sdk_path {
            $godot_settings = ($godot_settings | append $java_sdk_setting_assign)
        }

        if $do_append_android_sdk_path {
            $godot_settings = ($godot_settings | append $android_sdk_setting_assign)
        }

        $godot_settings | str join "\n" | save -f $godot_settings_path

        (gsrc export 
            --project=$project 
            --release-mode=$release_mode 
            --out-file=$out_file 
            --preset=$preset
            ...$rest
        )

        rm -rf $editor_data_path
        rm -f $sc_path
    } else {
        (gsrc export 
            --project=$project 
            --release-mode=$release_mode 
            --out-file=$out_file 
            --preset=$preset
            ...$rest
        )
    }
}

export def --wrapped "gsrc export macos" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "macOS"
    --arch: string = "universal"
    --out-file: string
    ...rest
] {
    use ../utils/utils.nu validate_arg
    validate_arg $release_mode "--release-mode" ((metadata $release_mode).span) "release" "debug"

    if not $skip_template {
        gsrc godot build template macos app --arch=$arch
    }

    $env.GODOT_SRC_GODOT_PLATFORM = "macos"
    (gsrc export 
        --project=$project 
        --release-mode=$release_mode 
        --out-file=$out_file 
        --preset=$preset
        ...$rest)
}

export def --wrapped "gsrc export ios" [
    --project: string # Path to the folder with a project.godot file that will be exported
    --release-mode: string = "debug", # How to optimize the build. Options: 'release' | 'debug'
    --skip-template
    --preset: string = "iOS"
    --arch: string = "arm64"
    --out-file: string
    ...rest
] {
    use ../utils/utils.nu validate_arg
    validate_arg $release_mode "--release-mode" ((metadata $release_mode).span) "release" "debug"

    if not $skip_template {
        gsrc godot build template ios app --arch=$arch
    }

    $env.GODOT_SRC_GODOT_PLATFORM = "ios"
    (gsrc export 
        --project=$project 
        --release-mode=$release_mode 
        --out-file=$out_file 
        --preset=$preset
        ...$rest)
}

export def "gsrc vulkan compile validation android" [
    android_libs_path: string,
    --release-mode: string = "debug",
] {
    use ../nudep/vulkan-validation-layers.nu
    vulkan-validation-layers compile android $android_libs_path "arm64-v8a" --release-mode=$release_mode
    # vulkan-validation-layers compile android $android_libs_path "x86_64" --release-mode=$release_mode
}

# Returns vars commonly accepted by scons. See more here under "User Guide": https://scons.org/documentation.html
export def "gsrc zig cxx scons-vars" [target: string] -> string[] {
    use ../nudep

    let cxx_env_vars = gsrc zig cxx env-vars-wrapped $target

    return [
        $"CC=($cxx_env_vars.CC)"
        $"CXX=($cxx_env_vars.CXX)"
        $"LINK=($cxx_env_vars.LD)"
        $"AS=($cxx_env_vars.AS)"
        $"AR=($cxx_env_vars.AR)"
        $"RANLIB=($cxx_env_vars.RANLIB)"
        $"RC=($cxx_env_vars.RC)"
    ]
}

# Returns common env vars to use the zig toolchain when compiling c++ code.
export def "gsrc zig cxx env-vars" [target: string] {
    use ../nudep

    return {
        CC: $"(nudep zig bin) cc -target ($target)"
        CXX: $"(nudep zig bin) c++ -target ($target)"
        LD: $"(nudep zig bin) c++ -target ($target)"
        AS: $"(nudep zig bin) c++ -target ($target)"
        AR: $"(nudep zig bin) ar"
        RANLIB: $"(nudep zig bin) ranlib"
        RC: $"(nudep zig bin) rc"
    }
}

# Returns common env vars to use the zig toolchain when compiling c++ code.
export def "gsrc zig cxx env-vars-wrapped" [target: string] {
    use ../nudep

    let zig_filter_script = $"($env.GODOT_SRC_DIR)/zig/zig-cc-cxx.nu"
    let cc = (gsrc wrap-script zig-cc $nu.current-exe $zig_filter_script $"(nudep zig bin)" cc -target ($target))
    let cxx = (gsrc wrap-script zig-c++ $nu.current-exe $zig_filter_script $"(nudep zig bin)" c++ -target ($target))
    let ar = (gsrc wrap-script zig-ar $"(nudep zig bin)" ar)
    let ranlib = (gsrc wrap-script zig-ranlib $"(nudep zig bin)" ranlib)
    let rc = (gsrc wrap-script zig-rc $"(nudep zig bin)" rc)
    
    return {
        CC: $cc
        CXX: $cxx
        LD: $cxx
        AS: $cxx
        AR: $ar
        RANLIB: $ranlib
        RC: $rc
    }
}

# Returns common env vars to use the android llvm toolchain when compiling C / C++ code.
export def "gsrc android cxx env-vars" [target: string] {
    use ../nudep/android-cli.nu

    let os_arch = (match $nu.os-info.name {
        "macos" => "darwin-x86_64", 
        _ => $"($nu.os-info.name)-($nu.os-info.arch)"
    })

    let android_config = android-cli config
    let llvm_dir = (
        $"($android_config.ndk_dir)/toolchains/llvm/prebuilt/($os_arch)/bin"
        | str replace --all "\\" "/"
    )

    let ext = match $nu.os-info.name {
        "windows" => ".cmd",
        _ => ""
    }

    return {
        CC: $"($llvm_dir)/($target)($env.GODOT_SRC_ANDROID_VERSION)-clang($ext)"
        CXX: $"($llvm_dir)/($target)($env.GODOT_SRC_ANDROID_VERSION)-clang++($ext)"
        # Some programs use LINK and others use LD so we set both to be safe
        LD: $"($llvm_dir)/lld"
        AS: $"($llvm_dir)/($target)-as($ext)"
        AR: $"($llvm_dir)/llvm-ar"
        RANLIB: $"($llvm_dir)/llvm-ranlib"
        RC: $"($llvm_dir)/llvm-rc"
        STRIP: $"($llvm_dir)/llvm-strip"
        NM: $"($llvm_dir)/llvm-nm"
    }
}

export def --wrapped "gsrc wrap-script" [script_name: string, ...rest] -> string {
    let script_dir = $"($env.GODOT_SRC_DIR)/gitignore/wrapper-scripts"
    mkdir $script_dir

    if $nu.os-info.name == "windows" {
        let script_path = $"($script_dir)/($script_name).cmd"
        $"@echo off\n($rest | each { |it| '"' + $it + '"' } | str join ' ') %*" | save -f $script_path
        return ($script_path | str replace --all "\\" "/")
    } else {
        let script_path = $"($script_dir)/($script_name).sh"
        $"#!/bin/bash\n($rest | each { |it| '"' + $it + '"' } | str join ' ') \"$@\"" | save -f $script_path
        chmod +x $script_path
        return ($script_path | str replace --all "\\" "/")
    }
}