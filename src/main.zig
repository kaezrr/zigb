const std = @import("std");
const lib = @import("lib.zig");

pub fn main(_: std.process.Init) !void {
    std.log.debug("starting emulator...", .{});

    var emulator = lib.Emulator.init();

    emulator.run();
}

test {
    std.testing.refAllDecls(lib);
}
