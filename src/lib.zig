pub const Cpu = @import("Cpu.zig");
pub const Memory = if (@import("builtin").is_test) @import("MockMemory.zig") else @import("Memory.zig");

pub const Emulator = struct {
    memory: Memory,
    cpu: Cpu,

    pub fn init() Emulator {
        var memory = Memory.init();

        return .{
            .memory = memory,
            .cpu = Cpu{ .memory = &memory },
        };
    }

    pub fn run(self: *Emulator) void {
        while (true) {
            self.cpu.step();
        }
    }
};
