const std = @import("std");

pub fn build(b: *std.Build) void {
    const nasm_dep = b.dependency("nasm", .{});
    const nasm_exe = nasm_dep.artifact("nasm");
    // nasm has UB when building libvpx.  Disabling this to workaround for now.
    nasm_exe.root_module.sanitize_c = false;
    const install_nasm = b.addInstallArtifact(nasm_exe, .{});
    const nasm_step = b.step("nasm", "build and install nasm");
    nasm_step.dependOn(&install_nasm.step);
}
