# Builds the godot template for linux
def "main build linux-template" [
    --release-mode: string, # How to optimize the build. Options: 'release' | 'debug'
    --skip-cs-glue # Skips generating or rebuilding the csharp glue
    --custom-modules: string # A csv seperated list of additional modules to include in the build
] {
    use ../utils/utils.nu
    use ../nudep/platform_constants.nu *
    use ../nudep zig *
    utils validate_arg $release_mode "--release-mode" ((metadata $release_mode).span) "release" "debug"

    let build_config =  match $release_mode {
        # When llvm fixes the lto bug, do lto_arg:"lto=full"
        "release" => {lto_arg: "", debug_symbols: "no"},
        _ => {lto_arg: "", debug_symbols: "yes"}
    };

    let cc = $"(utils zig path native-shell) cc"
    let cxx = $"(utils zig path native-shell) c++"

    # if not $skip_cs_glue {
    #     "$root_dir/godot/godot-clean-dotnet.sh"
    #     # The directory where godot will be built out to
    #     mkdir $"($env.GODOT_CROSS_GODOT_DIR)/bin/"
    #     # This folder needs to exist in order for the nuget packages to be output here
    #     mkdir $"($env.GODOT_CROSS_GODOT_DIR)/bin/GodotSharp/Tools/nupkgs"
    
    #     # We assume the godot editor is already built
    #     # TODO: Allow customizing these flags
    #     ("$dir/godot.sh"
    #         --headless
    #         --generate-mono-glue
    #         "$GODOT_CROSS_GODOT_DIR/modules/mono/glue"
    #         --precision=double)
    
    #     # # TODO: Allow customizing these flags
    #     "$GODOT_CROSS_GODOT_DIR/modules/mono/build_scripts/build_assemblies.py" \
    #         --godot-output-dir="$GODOT_CROSS_GODOT_DIR/bin" \
    #         --precision=double \
    #         --godot-platform=linuxbsd
    # }
    
    # if [[ "$skip_cs" != "true" ]]
    # then
    #     "$root_dir/godot/godot-clean-dotnet.sh"
    #     # The directory where godot will be built out to
    #     mkdir -p "$GODOT_CROSS_GODOT_DIR/bin/"
    #     # This folder needs to exist in order for the nuget packages to be output here
    #     mkdir -p "$GODOT_CROSS_GODOT_DIR/bin/GodotSharp/Tools/nupkgs"
    
    #     # We assume the godot editor is already built
    #     # TODO: Allow customizing these flags
    #     "$dir/godot.sh" \
    #         --headless \
    #         --generate-mono-glue \
    #         "$GODOT_CROSS_GODOT_DIR/modules/mono/glue" \
    #         --precision=double
    
    #     # TODO: Allow customizing these flags
    #     "$GODOT_CROSS_GODOT_DIR/modules/mono/build_scripts/build_assemblies.py" \
    #         --godot-output-dir="$GODOT_CROSS_GODOT_DIR/bin" \
    #         --precision=double \
    #         --godot-platform=linuxbsd
    # fi
    
    # cd "$GODOT_CROSS_GODOT_DIR"
    
    # scons \
    #     "$lto_arg" \
    #     platform=linuxbsd \
    #     target=template_$target \
    #     debug_symbols=$debug_symbols \
    #     module_mono_enabled=yes \
    #     compiledb=no \
    #     precision=double \
    #     import_env_vars="$GODOT_CROSS_IMPORT_ENV_VARS" \
    #     custom_modules="$GODOT_CROSS_CUSTOM_MODULES" \
    #     CC="$cc" \
    #     CXX="$cxx"
    
    # cd "$prev_pwd"
    
    # echo "Template build success!  Find your template at: $(realpath "$GODOT_CROSS_GODOT_DIR/bin")"
}