# Filters out or remaps commonly passed command line args to cc or c++ that aren't compatible with zig.
# Then runs the command_to_run with the filtered args
export def --wrapped "main" [command_to_run ...rest] {
    run-external $command_to_run ...(filter $rest)
}

def filter [args: list<string>] -> list<string> {
    mut filtered_args: list<string> = []

    for arg in $args {
        let arg = if $arg == "-lgcc_s" {
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
        } else if (
            ($arg | str contains "libcompiler_builtins-") or
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

        $filtered_args = ($filtered_args | append $arg)
    }

    return $filtered_args
}