const std = @import("std");
const assert = std.debug.assert;

const lib = @import("lib.zig");

const Cpu = @This();

af: FlagsRegister = .{ .full = 0 },
bc: Register = .{ .full = 0 },
de: Register = .{ .full = 0 },
hl: Register = .{ .full = 0 },

/// Stack Pointer
sp: u16 = 0,
/// Program Counter
pc: u16 = 0x100,

memory: *lib.Memory,

pub fn step_instruction(self: *Cpu) void {
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

// load test .json;
// for test in test.json:
//     set initial processor state from test;
//     set initial ram state from test;
//
//     for cycle in test:
//         cycle processor
//         if we are checking cycle-by-cycle:
//             compare our r/w/mrq/address/data pins against the current cycle;
//
//     compare final ram state to test and report any errors;
//     compare final processor state to test and report any errors;
test "sm83-single-step-tests" {
    const io = std.testing.io;
    const dir = try std.Io.Dir.cwd().openDir(io, "tests/sm83-ssts/v1", .{});
    const allocator = std.testing.allocator;

    const helper = struct {
        fn process_test_file(file: []const u8) !void {
            const parsed = try std.json.parseFromSlice(std.json.Value, allocator, file, .{});
            defer parsed.deinit();

            for (parsed.value.array.items) |item| {
                const initial = item.object.get("initial").?.object;

                var memory = lib.Memory.init();
                var cpu = Cpu{ .memory = &memory };

                cpu.af.half.a = @intCast(initial.get("a").?.integer);
                cpu.af.half.f = @bitCast(@as(u8, @intCast(initial.get("f").?.integer)));
                cpu.bc.half.hi = @intCast(initial.get("b").?.integer);
                cpu.bc.half.lo = @intCast(initial.get("c").?.integer);
                cpu.de.half.hi = @intCast(initial.get("d").?.integer);
                cpu.de.half.lo = @intCast(initial.get("e").?.integer);
                cpu.hl.half.hi = @intCast(initial.get("h").?.integer);
                cpu.hl.half.lo = @intCast(initial.get("l").?.integer);

                cpu.pc = @intCast(initial.get("pc").?.integer);
                cpu.sp = @intCast(initial.get("sp").?.integer);

                for (initial.get("ram").?.array.items) |ram_write| {
                    const addr: u16 = @intCast(ram_write.array.items[0].integer);
                    const data: u8 = @intCast(ram_write.array.items[1].integer);

                    memory.write(addr, data);
                }

                // Single Step
                cpu.step_instruction();

                const final = item.object.get("final").?.object;

                const final_a: u8 = @intCast(final.get("a").?.integer);
                const final_f: u8 = @bitCast(@as(u8, @intCast(final.get("f").?.integer)));
                const final_b: u8 = @intCast(final.get("b").?.integer);
                const final_c: u8 = @intCast(final.get("c").?.integer);
                const final_d: u8 = @intCast(final.get("d").?.integer);
                const final_e: u8 = @intCast(final.get("e").?.integer);
                const final_h: u8 = @intCast(final.get("h").?.integer);
                const final_l: u8 = @intCast(final.get("l").?.integer);

                const final_pc: u16 = @intCast(final.get("pc").?.integer);
                const final_sp: u16 = @intCast(final.get("sp").?.integer);

                try std.testing.expectEqual(final_a, cpu.af.half.a);
                try std.testing.expectEqual(final_f, @as(u8, @bitCast(cpu.af.half.f)));
                try std.testing.expectEqual(final_b, cpu.bc.half.hi);
                try std.testing.expectEqual(final_c, cpu.bc.half.lo);
                try std.testing.expectEqual(final_d, cpu.de.half.hi);
                try std.testing.expectEqual(final_e, cpu.de.half.lo);
                try std.testing.expectEqual(final_h, cpu.hl.half.hi);
                try std.testing.expectEqual(final_l, cpu.hl.half.lo);

                try std.testing.expectEqual(final_pc, cpu.pc);
                try std.testing.expectEqual(final_sp, cpu.sp);

                for (final.get("ram").?.array.items) |ram_read| {
                    const addr: u16 = @intCast(ram_read.array.items[0].integer);
                    const expected: u8 = @intCast(ram_read.array.items[1].integer);

                    const actual = memory.read(addr);
                    try std.testing.expectEqual(expected, actual);
                }
            }
        }
    };

    const file_buffer = try allocator.alloc(u8, 500 * 1024); // 500 KiB
    defer allocator.free(file_buffer);

    for (0..0xFF + 1) |ins| {
        var path_buf: [32]u8 = undefined;

        if (ins == 0xCB) {
            for (0..0xFF + 1) |sub| {
                const sub_file_name = try std.fmt.bufPrint(&path_buf, "{x:02} {x:02}.json", .{ ins, sub });
                const sub_file = dir.readFile(io, sub_file_name, file_buffer) catch continue;
                try helper.process_test_file(sub_file);
            }
            continue;
        }

        const file_name = try std.fmt.bufPrint(&path_buf, "{x:02}.json", .{ins});
        const file = dir.readFile(io, file_name, file_buffer) catch continue;
        try helper.process_test_file(file);
    }
}
