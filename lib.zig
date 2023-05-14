const std = @import("std");

fn root() []const u8 {
    return comptime (std.fs.path.dirname(@src().file) orelse unreachable) ++ "/";
}

pub fn Lib(comptime microzig: type) type {
    return struct {
        pub const chips = struct {
            pub const stm32l011f3px = microzig.Chip{
                .name = "STM32L0x1",
                .source = .{
                    .path = root() ++ "src/registers.zig",
                },
                .cpu = microzig.cpus.cortex_m0plus,
                .memory_regions = &.{
                    .{ .kind = .flash, .offset = 0x08000000, .length = 8 * 1024 },
                    .{ .kind = .ram, .offset = 0x20000000, .length = 2 * 1024 },
                },
            };
            pub const stm32l011f4px = microzig.Chip{
                .name = "STM32L0x1",
                .source = .{
                    .path = root() ++ "src/registers.zig",
                },
                .cpu = microzig.cpus.cortex_m0plus,
                .memory_regions = &.{
                    .{ .kind = .flash, .offset = 0x08000000, .length = 16 * 1024 },
                    .{ .kind = .ram, .offset = 0x20000000, .length = 2 * 1024 },
                },
            };
        };
        pub const module = std.build.CreateModuleOptions{
            .source_file = .{
                .path = root() ++ "src/lib.zig",
            },
        };
    };
}
