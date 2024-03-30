export const DEP_DIR = "gitignore";
export const OS_WINDOWS = "windows";
export const OS_LINUX = "linux";
export const OS_MACOS = "macos";

export def "nudep http file" [
    url: string, # The url to fetch the file from
    file_path: string # The path the file should be located at on the system
] {
    if ($file_path | path exists) {
        return;
    }

    mkdir (dirname $file_path)
    print $"http get ($url) - downloading to ($file_path)"
    http get $url | save $file_path
}

# Decompresses the zip file at the file_path to the out_dir if the contents of that directory are empty
export def "nudep decompress zip" [
    file_path: string # The path to the file to unzip
    out_dir: string # The directory to extract the files to
] {
    if ($out_dir | path exists) and not (ls $out_dir | is-empty) {
        return;
    }

    mkdir $out_dir
    unzip $file_path -d $out_dir
}

# Decompresses the tar file at the file_path to the out_dir if the contents of that directory are empty
export def "nudep decompress tar" [
    file_path: string # The path to the file to unzip
    out_dir: string # The directory to extract the files to
] {
    if ($out_dir | path exists) and not (ls $out_dir | is-empty) {
        return;
    }

    mkdir $out_dir
    tar -xvf $file_path -C $out_dir
}

# Decompresses the file and detects the file type.  Must have an extension of '.tar.xz', '.tar.gz' or '.zip'
export def "nudep decompress" [
    file_path: string # The path to the file to unzip
    out_dir: string # The directory to extract the files to
] {
    if ($file_path | str ends-with ".tar.xz") or ($file_path | str ends-with ".tar.gz") {
        decompress tar $file_path $out_dir
    } else if ($file_path | str ends-with ".zip") {
        decompress zip $file_path $out_dir
    } else {
        error make {
            msg: $"Failed to detect compression format for '($file_path)'. Must have a file extension of '.tar.xz', '.tar.gz' or '.zip'.  Otherwise call 'decompress tar' or 'decompress zip' explicitly",
        }
    }
}