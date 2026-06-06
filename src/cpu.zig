const std = @import("std");
const assert = std.debug.assert;

const lib = @import("lib.zig");

/// This struct represents a (speculated) SM83 CPU core
pub const Cpu = struct {
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
};

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
