# Filters out or remaps commonly passed command line args to cc or c++ that aren't compatible with zig.
# Then runs the command_to_run with the filtered args
export def --wrapped "main" [command_to_run ...rest] {
    run-external $command_to_run ...(filter $rest)
}

def filter [args: list<string>] -> list<string> {
    mut filtered_args: list<string> = []

    mut is_arg_val = false
    mut do_prepend = false

    # TODO: Pass -o as first arg
    for arg in $args {
        let arg = if $is_arg_val {
            $arg
        } else if $arg == "-o" {
            # zig requires -o to be the first arg / val combination after cc / cxx when linking
            $filtered_args = ($filtered_args | insert 1 $arg)
            $is_arg_val = true
            $do_prepend = true
            continue;
        } else if $arg == "-lgcc_s" {
            "-lunwind"
        } else if ($arg | str starts-with "@") {
            let file_path = ($arg | str substring 1..)
            let file_str = open --raw $file_path | decode utf-8
            let file_args = ($file_str | split row "\n")
            let file_args = filter $file_args
            let file_args = ($file_args | str join "\n")
            $file_args | save -f $file_path
            $arg
        } else if $arg == "-lgcc_eh" {
            "-lc++"
        } else if ($arg | str starts-with "-Wl,") and ($arg | str ends-with "list.def") {
            $arg | str substring 4..
        } else if ($arg == "--whole-archive") {
            "-Wl,--whole-archive"
        } else if (
            ($arg | str contains "libcompiler_builtins-") or
            ($arg | str contains "self-contained") or
            ($arg | str starts-with "--target=") or
            ($arg | str starts-with "-lwindows") or
            ($arg == "-Wl,--disable-auto-image-base") or
            ($arg == "-lmsvcrt") or
            ($arg == "-lgcc") or
            ($arg == "-l:libpthread.a") or
            ($arg == "-Wl,--allow-multiple-definition") or
            ($arg == "--allow-multiple-definition") or
            ($arg == "--no-relax") or
            ($arg == "--gc-sections") or
            ($arg == "--gc-keep-exported")
        ) {
            continue
        } else {
            $arg
        }

        if $do_prepend {
            $do_prepend = false
            if $is_arg_val {
                $is_arg_val = false
                # The arg val will always come after the arg
                $filtered_args = ($filtered_args | insert 2 $arg)
            } else {
                $filtered_args = ($filtered_args | insert 1 $arg)
            }
        } else {
            $filtered_args = ($filtered_args | append $arg)
        }
    }

    return $filtered_args
}