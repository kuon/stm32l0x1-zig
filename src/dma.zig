const std = @import("std");
const microzig = @import("microzig");
const regs = microzig.chip.peripherals;
const set = @import("core.zig").set_reg_field;
const get = @import("core.zig").reg_field;

pub fn enable_clock() void {
    // Enable clock
    set(&regs.RCC.AHBENR, "DMAEN", 1);
}
pub fn disable_clock() void {
    // Enable clock
    set(&regs.RCC.AHBENR, "DMAEN", 0);
}
pub fn reset() void {
    // Reset API
    set(&regs.RCC.AHBRSTR, "DMARST", 1);
    set(&regs.RCC.AHBRSTR, "DMARST", 0);
}

pub fn Channel(comptime channel_number: u3) type {
    const channel_name = std.fmt.comptimePrint("{d}", .{channel_number});
    const cpar = &@field(regs.DMA1, "CPAR" ++ channel_name);
    const cmar = &@field(regs.DMA1, "CMAR" ++ channel_name);
    const ccr = &@field(regs.DMA1, "CCR" ++ channel_name);
    const cndtr = &@field(regs.DMA1, "CNDTR" ++ channel_name);

    return struct {
        pub fn set_peripheral(peripheral: enum(u4) {
            adc = 0b0000,
            spi1 = 0b0001,
            spi2 = 0b0010,
            usart1 = 0b0011,
            usart2 = 0b0100,
            lpuart1 = 0b0101,
            i2c1 = 0b0110,
            i2c2 = 0b0111,
            tim1 = 0b1000,
            tim6_up = 0b1001,
            tim3 = 0b1010,
            aes = 0b1011,
            usart4 = 0b1100,
            usart5 = 0b1101,
            i2c3 = 0b1110,
            tim7_up = 0b1111,
        }) void {
            set(
                &regs.DMA1.CSELR,
                "C" ++ channel_name ++ "S",
                @enumToInt(peripheral),
            );
        }
        pub fn set_peripheral_address(addr: u32) void {
            cpar.modify(.{ .PA = addr });
        }
        pub fn set_memory_address(addr: u32) void {
            cmar.modify(.{ .MA = addr });
        }
        pub fn set_direction(dir: enum(u1) {
            to_memory = 0,
            from_memory = 1,
        }) void {
            ccr.modify(.{ .DIR = @enumToInt(dir) });
        }
        pub fn set_memory_increment_mode(enabled: bool) void {
            ccr.modify(.{ .MINC = @boolToInt(enabled) });
        }
        pub fn set_peripheral_increment_mode(enabled: bool) void {
            ccr.modify(.{ .PINC = @boolToInt(enabled) });
        }
        pub fn set_memory_data_size(size: enum(u2) {
            u8 = 0b00,
            u16 = 0b01,
            u32 = 0b10,
        }) void {
            ccr.modify(.{ .MSIZE = @enumToInt(size) });
        }
        pub fn set_peripheral_data_size(size: enum(u2) {
            u8 = 0b00,
            u16 = 0b01,
            u32 = 0b10,
        }) void {
            ccr.modify(.{ .PSIZE = @enumToInt(size) });
        }
        pub fn set_priority(priority: enum(u2) {
            low = 0b00,
            medium = 0b01,
            high = 0b10,
            very_high = 0b11,
        }) void {
            ccr.modify(.{ .PL = @enumToInt(priority) });
        }
        pub fn set_data_count(count: u16) void {
            cndtr.modify(.{ .NDT = count });
        }
        pub fn data_count() u16 {
            return cndtr.read().NDT;
        }
        pub fn set_interrupt(name: enum {
            transfer_completed,
            transfer_error,
            half_transfer,
        }, enabled: bool) void {
            switch (name) {
                .transfer_error => ccr.modify(.{
                    .TEIE = @boolToInt(enabled),
                }),
                .transfer_completed => ccr.modify(.{
                    .TCIE = @boolToInt(enabled),
                }),
                .half_transfer => ccr.modify(.{
                    .HTIE = @boolToInt(enabled),
                }),
            }
        }
        pub fn enable() void {
            ccr.modify(.{ .EN = 1 });
        }
        pub fn disable() void {
            ccr.modify(.{ .EN = 0 });
            clear_flags();
        }
        pub fn has_flag(flag: enum {
            transfer_completed,
            transfer_error,
            half_transfer,
            global,
        }) bool {
            const val: u32 = switch (flag) {
                .transfer_error => get(&regs.DMA1.ISR, "TEIF" ++ channel_name),
                .transfer_completed => get(&regs.DMA1.ISR, "TCIF" ++ channel_name),
                .half_transfer => get(&regs.DMA1.ISR, "HTIF" ++ channel_name),
                .global => get(&regs.DMA1.ISR, "GIF" ++ channel_name),
            };
            return val != 0;
        }
        pub fn clear_flag(flag: enum {
            transfer_completed,
            transfer_error,
            half_transfer,
            global,
        }) void {
            switch (flag) {
                .transfer_error => set(&regs.DMA1.IFCR, "CTEIF" ++ channel_name, 1),
                .transfer_completed => set(&regs.DMA1.IFCR, "CTCIF" ++ channel_name, 1),
                .half_transfer => set(&regs.DMA1.IFCR, "CHTIF" ++ channel_name, 1),
                .global => set(&regs.DMA1.IFCR, "CGIF" ++ channel_name, 1),
            }
        }
        pub fn clear_flags() void {
            set(&regs.DMA1.IFCR, "CTEIF" ++ channel_name, 1);
            set(&regs.DMA1.IFCR, "CTCIF" ++ channel_name, 1);
            set(&regs.DMA1.IFCR, "CHTIF" ++ channel_name, 1);
            set(&regs.DMA1.IFCR, "CGIF" ++ channel_name, 1);
        }
    };
}
