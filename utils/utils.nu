# Returns the path to the native shell scripts that forward cli args to zig.
# 
# Example:
# 
# $env.CC = $"(utils zig path native-shell) cc
# $env.CXX = $"(utils zig path native-shell) c++
export def "zig path native-shell" [] {
    $"($env.GODOT_SRC_DIR)/zig/native-shell/($nu.os-info.name)/zig"
}

export def validate_arg [
    arg: any, # The arg to validate
    arg_name: string, # The name of the argument
    span: record # The span to make an error on if this argument is invalid
    ...options # The valid options.  If one of these don't match, make an error
] {
    if $arg == null {
        let options = $options | each {|i| $"'($i)'"} | str join ,;
        error make {
            msg: $"Missing required argument '($arg_name)'. Possible values ($options)", 
            label: {
                text: $"Pass the required argument '($arg_name)' with one of the following options: ($options)", 
                span: $span 
            } 
        }
    }

    if $arg not-in $options {
        let options = $options | each {|i| $"'($i)'"} | str join ,;
        error make {
            msg: $"Invalid value '($arg)'. Possible values ($options)", 
            label: {
                text: $"Change to one of the possible values: ($options)", 
                span: $span 
            } 
        }
    }
}

export def validate_arg_exists [
    arg: any, # The arg to validate
    arg_name: string, # The name of the argument
    span: record # The span to make an error on if this argument is invalid
] {
    if $arg == null {
        error make {
            msg: $"Missing required argument '($arg_name)'.", 
            label: {
                text: $"Pass the required argument '($arg_name)'", 
                span: $span 
            } 
        }
    }
}

# returns a list of gitignored folders and directories
export def "git list ignored" [...dirs: string] {
    $dirs | each { 
        |dir| cd $dir | (run-external --redirect-combine git 
            "status"
            .
            "--ignored"
            "--short" |
                complete |
                get stdout |
                str trim |
                split row "\n" |
                filter { |$el| $el | str starts-with "!!" } |
                str substring 2..) | 
                str trim | 
                each { |$el| $env.PWD | path join $el }
    } | flatten
}

# Removed all of the gitignored folders and directories found in the directories passed as arguments
#
# Returns the list of files and directories that were removed
export def "git remove ignored" [...dirs: string] {
    git list ignored ...$dirs | each { |dir_file| 
        print $"removing: ($dir_file)"
        rm -r $dir_file 
    }
    ()
}