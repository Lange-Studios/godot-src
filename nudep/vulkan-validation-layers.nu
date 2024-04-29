use core.nu *
use platform_constants.nu *

const GODOT_SRC_VULKAN_VALIDATION_VERSION_DEFAULT = "1.3.250.1"

export def config [] {
    let dir = $"($env.GODOT_SRC_DIR)/($DEP_DIR)/vulkan-validation"
    let version = ($env.GODOT_SRC_VULKAN_VALIDATION_VERSION? | default $GODOT_SRC_VULKAN_VALIDATION_VERSION_DEFAULT)

    return {
        dir: $dir,
        version: $version,
        src_dir: $"($dir)/($version)/Vulkan-ValidationLayers-sdk-($version)"
    }
}

export def download [] {
    let config = config
    let vulkan_validation_version_dir = $"($config.dir)/($config.version)"
    let zip_file = $"vulval-($config.version)-($nu.os-info.name).zip"
    let zip_path = $"($config.dir)/($zip_file)"

    nudep http file $"https://github.com/KhronosGroup/Vulkan-ValidationLayers/archive/refs/tags/sdk-($config.version).zip" $zip_path
    nudep decompress $zip_path $vulkan_validation_version_dir
}

export def "compile android" [
    android_libs_path: string,
    arch: string,
    --release-mode: string,
] {
    # Validation build process will error if the build already happened
    if ($"($android_libs_path)/($release_mode)/($arch)/libVkLayer_khronos_validation.so" | path exists) {
        return
    }

    use android-cli.nu
    use jdk.nu

    download
    android-cli download
    jdk download

    let config = config
    let android_cli_config = android-cli config
    let jdk_config = jdk config

    $env.ANDROID_SDK_ROOT = $android_cli_config.cli_version_dir
    $env.ANDROID_NDK_HOME = $android_cli_config.ndk_dir

    $env.PATH = ($env.PATH | prepend [
        $android_cli_config.build_tools_dir,
        $jdk_config.bin_dir,
    ])

    print "appt version:"
    run-external aapt "version"
    print ""
    print "cmake version:"
    run-external cmake "--version"
    print ""
    print "ninja version:"
    run-external ninja "--version"
    print ""
    print "apksigner version:"
    run-external apksigner "--version"
    print ""

    cd $config.src_dir

    let cmake_build_type = match $release_mode {
        "release" => "Release",
        "debug" => "Debug",
        _ => {
            error make {
                msg: $"Release mode: ($release_mode) is unsupported for validation layers"
            }
        }
    }

    let build_dir = $"build/($release_mode)/($arch)"

    (run-external cmake "-S" . "-B" $build_dir
        "-D" $"CMAKE_TOOLCHAIN_FILE=($env.ANDROID_NDK_HOME)/build/cmake/android.toolchain.cmake"
        "-D" "ANDROID_PLATFORM=26"
        "-D" $"CMAKE_ANDROID_ARCH_ABI=($arch)"
        "-D" "CMAKE_ANDROID_STL_TYPE=c++_static"
        "-D" "ANDROID_USE_LEGACY_TOOLCHAIN_FILE=NO"
        "-D" $"CMAKE_BUILD_TYPE=($cmake_build_type)"
        "-D" "UPDATE_DEPS=ON"
        "-G" "Ninja")

    run-external cmake "--build" $build_dir
    run-external cmake "--install" $build_dir "--prefix" $"($build_dir)/install"
    mkdir $"($android_libs_path)/($release_mode)/($arch)"
    (mv 
        $"($build_dir)/install/lib/libVkLayer_khronos_validation.so" 
        $"($android_libs_path)/($release_mode)/($arch)/libVkLayer_khronos_validation.so")
}