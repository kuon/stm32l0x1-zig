const std = @import("std");
const microzig = @import("microzig");
const regs = microzig.chip.registers;

const set = @import("core.zig").set_reg_field;

pub fn Pin(comptime spec: []const u8) type {
    const invalid_format_msg = "The given pin '" ++ spec ++ "' has an invalid format. Pins must follow the format \"P{Port}{Pin}\" scheme.";

    if (spec[0] != 'P')
        @compileError(invalid_format_msg);
    if (spec[1] < 'A' or spec[1] > 'B')
        @compileError(invalid_format_msg);

    const port_name = spec[1..2];
    const pin_number: comptime_int = std.fmt.parseInt(u4, spec[2..], 10) catch @compileError(invalid_format_msg);
    const suffix = std.fmt.comptimePrint("{d}", .{pin_number});
    const port = @field(regs, "GPIO" ++ port_name);

    return struct {
        pub fn enable_port_clock() void {
            set(regs.RCC.IOPENR, "IOP" ++ port_name ++ "EN", 1);
        }
        pub fn input() void {
            set(port.MODER, "MODE" ++ suffix, 0b00);
        }
        pub fn output() void {
            set(port.MODER, "MODE" ++ suffix, 0b01);
        }
        pub fn alternate() void {
            set(port.MODER, "MODE" ++ suffix, 0b10);
        }
        pub fn analog() void {
            set(port.MODER, "MODE" ++ suffix, 0b11);
        }
        pub fn push_pull() void {
            set(port.OTYPER, "OT" ++ suffix, 0);
        }
        pub fn open_drain() void {
            set(port.OTYPER, "OT" ++ suffix, 1);
        }
        pub fn low_speed() void {
            set(port.OSPEEDR, "OSPEED" ++ suffix, 0x00);
        }
        pub fn medium_speed() void {
            set(port.OSPEEDR, "OSPEED" ++ suffix, 0x01);
        }
        pub fn high_speed() void {
            set(port.OSPEEDR, "OSPEED" ++ suffix, 0x10);
        }
        pub fn very_high_speed() void {
            set(port.OSPEEDR, "OSPEED" ++ suffix, 0x11);
        }
        pub fn floating() void {
            set(port.PUPDR, "PUPD" ++ suffix, 0b00);
        }
        pub fn pull_up() void {
            set(port.PUPDR, "PUPD" ++ suffix, 0b01);
        }
        pub fn pull_down() void {
            set(port.PUPDR, "PUPD" ++ suffix, 0b10);
        }
        pub fn alternate_mode(mode: u3) void {
            if (pin_number > 7) {
                set(port.AFRH, "AFSEL" ++ suffix, mode);
            } else {
                set(port.AFRL, "AFSEL" ++ suffix, mode);
            }
        }
        pub fn floating_output() void {
            enable_port_clock();
            push_pull();
            output();
            floating();
        }
        pub fn low() void {
            // Set pin as low
            set(port.ODR, "OD" ++ suffix, 0);
        }
        pub fn high() void {
            // Set pin as high
            set(port.ODR, "OD" ++ suffix, 1);
        }
    };
}
