use core.nu *
use platform_constants.nu *

use zig-web.nu

export def config [] {
    zig-web config
}

# Execute a zig command.  Will install zig if it doesn't exist.
export def --wrapped run [
    ...rest
] {
    zig-web run ...$rest
}

# returns the path to the zig binary
export def bin [] {
    zig-web bin
}

export def bin_dir [] {
    zig-web bin_dir
}

# Deletes zig and the directory where it is installed
export def remove [] {
    zig-web remove
}
