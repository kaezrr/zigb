const Cpu = @This();

const std = @import("std");
const assert = std.debug.assert;

const lib = @import("lib.zig");

af: FlagsRegister = .{ .full = 0 },
bc: Register = .{ .full = 0 },
de: Register = .{ .full = 0 },
hl: Register = .{ .full = 0 },

/// Stack Pointer
sp: u16 = 0,
/// Program Counter
pc: u16 = 0x100,

memory: *lib.Memory,

pub fn step(self: *Cpu) void {
    std.log.debug("PC: 0x{x:08}", .{self.pc});

    const instr = self.fetch(u8);

    switch (instr) {
        0x00 => {}, // NOP
        else => |x| std.debug.panic("unimplemented instruction: 0x{x:02}", .{x}),
    }
}

fn fetch(self: *Cpu, comptime T: type) T {
    assert(T == u8 or T == u16); // Numeric types only

    var data: T = self.memory.read(self.pc);
    self.pc += 1;

    if (T == u16) {
        data |= self.memory.read(self.pc) << 8;
        self.pc += 1;
    }

    return data;
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

test "gp-registers" {
    var register = Register{ .full = 0xABCD };

    try std.testing.expectEqual(0xABCD, register.full);
    try std.testing.expectEqual(0xAB, register.half.hi);
    try std.testing.expectEqual(0xCD, register.half.lo);

    register.half.lo = 0xF1;

    try std.testing.expectEqual(0xABF1, register.full);
    try std.testing.expectEqual(0xAB, register.half.hi);
    try std.testing.expectEqual(0xF1, register.half.lo);
}

test "flag-registers" {
    var register = FlagsRegister{ .full = 0xAB50 };

    try std.testing.expectEqual(0xAB50, register.full);
    try std.testing.expectEqual(0xAB, register.half.a);
    try std.testing.expectEqual(0, register.half.f.z);
    try std.testing.expectEqual(1, register.half.f.n);
    try std.testing.expectEqual(0, register.half.f.h);
    try std.testing.expectEqual(1, register.half.f.c);

    register.half.f.z = 1;
    register.half.f.n = 0;
    register.half.f.h = 1;
    register.half.f.c = 0;

    try std.testing.expectEqual(0xABA0, register.full);
    try std.testing.expectEqual(0xAB, register.half.a);
    try std.testing.expectEqual(1, register.half.f.z);
    try std.testing.expectEqual(0, register.half.f.n);
    try std.testing.expectEqual(1, register.half.f.h);
    try std.testing.expectEqual(0, register.half.f.c);
}

test "sm83-single-step-tests" {
    // load test .json;
    // for test in test.json:
    //     set initial processor state from test;
    //     set initial RAM state from test;
    //
    //     for cycle in test:
    //         cycle processor
    //         if we are checking cycle-by-cycle:
    //             compare our R/W/MRQ/Address/Data pins against the current cycle;
    //
    //     compare final RAM state to test and report any errors;
    //     compare final processor state to test and report any errors;
}
