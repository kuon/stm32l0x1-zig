const std = @import("std");
const Pkg = std.build.Pkg;

fn root() []const u8 {
    return (std.fs.path.dirname(@src().file) orelse unreachable) ++ "/";
}

pub fn Lib(comptime microzig: anytype) type {
    return struct { chips: type = struct {
        stm32l011f3px: microzig.Chip = microzig.Chip{
            .name = "STM32L011F3Px",
            .path = root() ++ "src/registers.zig",
            .cpu = microzig.cpus.cortex_m0plus,
            .memory_regions = &.{
                .{ .kind = .flash, .offset = 0x08000000, .length = 8 * 1024 },
                .{ .kind = .ram, .offset = 0x20000000, .length = 2 * 1024 },
            },
        },
        stm32l011f4px: microzig.Chip = microzig.Chip{
            .name = "STM32L011F4Px",
            .path = root() ++ "src/registers.zig",
            .cpu = microzig.cpus.cortex_m0plus,
            .memory_regions = &.{
                .{ .kind = .flash, .offset = 0x08000000, .length = 16 * 1024 },
                .{ .kind = .ram, .offset = 0x20000000, .length = 2 * 1024 },
            },
        },
    }, pkg: Pkg = Pkg{
        .name = "stm32l0x1",
        .source = .{ .path = root() ++ "src/lib.zig" },
    } };
}
