const BOOT_ROM = @embedFile("_boot.bin");

bytes: [0x10000]u8 = undefined,

pub fn init() Memory {
    var memory = Memory{};
    @memcpy(memory.bytes[0..BOOT_ROM.len], BOOT_ROM);

    return memory;
}

pub fn read(self: *Memory, at: u16) u8 {
    return self.bytes[at];
}

pub fn write(self: *Memory, at: u16, byte: u8) void {
    self.bytes[at] = byte;
}

// /// Mocked 64KB memory bus for testing purposes...
// pub const FlatMemory = struct {
//     bytes: [0x10000]u8 = undefined,
//
//     pub fn read(self: *Memory, at: u16) u8 {
//         return self.bytes[at];
//     }
//
//     pub fn write(self: *Memory, at: u16, byte: u8) void {
//         self.bytes[at] = byte;
//     }
// };
