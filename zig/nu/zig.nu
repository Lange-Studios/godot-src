# Builds the godot template for linux
def --wrapped "main zig" [
    ...rest
] {
    use ../../nudep zig
    zig ...$rest
}