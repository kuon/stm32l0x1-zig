const microzig = @import("microzig");
const regs = microzig.chip.peripherals;

// this produces the same result as
// std.hash.crc.Crc32.hash(&buf),
pub fn crc(buf: []const u8) u32 {
    regs.CRC.INIT.modify(.{ .CRC_INIT = 0xffffffff });
    regs.CRC.POL.modify(.{
        .Polynomialcoefficients = 0x4C11DB7,
    });
    regs.CRC.CR.modify(.{
        .RESET = 1,
        .REV_IN = 0b01,
        .REV_OUT = 1,
    });

    const dr = @ptrCast(*volatile u8, &regs.CRC.DR);

    for (buf) |b| dr.* = b;

    return @intCast(u32, regs.CRC.DR.raw) ^ 0xffffffff;
}

pub fn reset() void {
    regs.RCC.APB1RSTR.modify(.{ .CRCRST = 1 });
    regs.RCC.APB1RSTR.modify(.{ .CRCRST = 0 });
}

pub fn enable_clock() void {
    regs.RCC.AHBENR.modify(.{ .CRCEN = 1 });
}
