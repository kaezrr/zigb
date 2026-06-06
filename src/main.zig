const std = @import("std");

pub fn main(_: std.process.Init) !void {
    std.log.debug("starting emulator", .{});
}

/// General purpose register
const Register = packed union(u16) {
    full: u16,
    half: packed struct(u16) { lo: u8, hi: u8 },
};

/// Accumulator and flags register
const FlagsRegister = packed union(u16) {
    full: u16,
    half: packed struct(u16) { f: Flags, a: u8 },
};

const Flags = packed struct(u8) {
    _: u4,
    /// Carry flag
    c: u1,
    /// Half Carry flag (BCD)
    h: u1,
    /// Subtraction flag (BCD)
    n: u1,
    /// Zero flag
    z: u1,
};

/// This struct represents a (speculated) SM83 CPU core
const Cpu = struct {
    af: FlagsRegister = .{ .full = 0 },
    bc: Register = .{ .full = 0 },
    de: Register = .{ .full = 0 },
    hl: Register = .{ .full = 0 },

    /// Stack Pointer
    sp: u16 = 0,
    /// Program Counter
    pc: u16 = 0x100,
};
