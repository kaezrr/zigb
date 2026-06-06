pub const Cpu = @import("cpu.zig").Cpu;
pub const Memory = @import("memory.zig").Memory;

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
