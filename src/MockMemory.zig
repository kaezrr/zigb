const MockMemory = @This();

/// Mocked 64KB memory bus for testing purposes...
bytes: [0x10000]u8 = undefined,

pub fn read(self: *MockMemory, at: u16) u8 {
    return self.bytes[at];
}

pub fn write(self: *MockMemory, at: u16, byte: u8) void {
    self.bytes[at] = byte;
}
