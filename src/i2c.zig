const std = @import("std");
const microzig = @import("microzig");
const regs = microzig.chip.registers;

const core = @import("core.zig");
const set = core.set_reg_field;

pub fn I2C(comptime port_number: u3) type {
    if (port_number != 1) unreachable;
    const port_name = std.fmt.comptimePrint("{d}", .{port_number});
    const port = @field(regs, "I2C" ++ port_name);

    return struct {
        pub fn dma_rx_address() u32 {
            return @ptrToInt(&port.RXDR.raw);
        }
        pub fn dma_tx_address() u32 {
            return @ptrToInt(&port.TXDR.raw);
        }
        pub fn enable_clock() void {
            // Enable clock
            set(regs.RCC.APB1ENR, "I2C" ++ port_name ++ "EN", 1);

            set(regs.RCC.CCIPR, "I2C" ++ port_name ++ "SEL0", 0b0); // hsi16
            set(regs.RCC.CCIPR, "I2C" ++ port_name ++ "SEL1", 0b1); // hsi16
        }
        pub fn disable_clock() void {
            // Enable clock
            set(regs.RCC.APB1ENR, "I2C" ++ port_name ++ "EN", 0);
        }
        pub fn reset() void {
            // Reset API
            set(regs.RCC.APB1RSTR, "I2C" ++ port_name ++ "RST", 1);
            set(regs.RCC.APB1RSTR, "I2C" ++ port_name ++ "RST", 0);
        }
        pub fn enable() void {
            port.CR1.modify(.{ .PE = 1 });
        }
        pub fn disable() void {
            port.CR1.modify(.{ .PE = 0 });
        }
        pub fn set_speed(speed: enum {
            kHz_10,
            kHz_100,
            kHz_400,
            kHz_1000,
        }) void {
            const vals: [5]u8 = switch (speed) {
                .kHz_10 => .{ 3, 0xC7, 0xC3, 0x2, 0x4 },
                .kHz_100 => .{ 3, 0x13, 0xF, 0x2, 0x4 },
                .kHz_400 => .{ 1, 0x9, 0x3, 0x2, 0x3 },
                .kHz_1000 => .{ 0, 0x4, 0x2, 0x0, 0x2 },
            };
            port.TIMINGR.modify(.{
                .PRESC = @intCast(u4, vals[0]),
                .SCLL = vals[1],
                .SCLH = vals[2],
                .SDADEL = @intCast(u4, vals[3]),
                .SCLDEL = @intCast(u4, vals[4]),
            });
        }
        pub fn set_interrupt(name: enum {
            transfer_completed,
            stop_detected,
            nack_received,
            address_match,
            rx_buffer_not_empty,
            tx_buffer_empty,
            error_occured,
        }, enabled: bool) void {
            switch (name) {
                .transfer_completed => port.CR1.modify(.{
                    .TCIE = @boolToInt(enabled),
                }),
                .stop_detected => port.CR1.modify(.{
                    .STOPIE = @boolToInt(enabled),
                }),
                .nack_received => port.CR1.modify(.{
                    .NACKIE = @boolToInt(enabled),
                }),
                .address_match => port.CR1.modify(.{
                    .ADDRIE = @boolToInt(enabled),
                }),
                .rx_buffer_not_empty => port.CR1.modify(.{
                    .RXIE = @boolToInt(enabled),
                }),
                .tx_buffer_empty => port.CR1.modify(.{
                    .TXIE = @boolToInt(enabled),
                }),
                .error_occured => port.CR1.modify(.{
                    .ERRIE = @boolToInt(enabled),
                }),
            }
        }
        pub fn has_flag(flag: enum {
            alert,
            timeout,
            pec_error,
            overrun,
            arbitration_lost,
            bus_error,
            stop,
            not_ack,
            address_match,
            busy,
            write,
            read,
            reloaded_transfer,
            transfer_completed,
            rx_buffer_not_empty,
            tx_buffer_empty,
            tx_interrupt_status,
        }) bool {
            const isr = port.ISR.read();
            return switch (flag) {
                .alert => isr.ALERT == 1,
                .timeout => isr.TIMEOUT == 1,
                .pec_error => isr.PECERR == 1,
                .overrun => isr.OVR == 1,
                .arbitration_lost => isr.ARLO == 1,
                .bus_error => isr.BERR == 1,
                .stop => isr.STOPF == 1,
                .not_ack => isr.NACKF == 1,
                .address_match => isr.ADDR == 1,
                .busy => isr.BUSY == 1,
                .write => isr.DIR == 0,
                .read => isr.DIR == 1,
                .reloaded_transfer => isr.TCR == 1,
                .transfer_completed => isr.TC == 1,
                .rx_buffer_not_empty => isr.RXNE == 1,
                .tx_buffer_empty => isr.TXE == 1,
                .tx_interrupt_status => isr.TXIS == 1,
            };
        }
        pub fn set_flag(flag: enum {
            tx_empty,
        }) void {
            switch (flag) {
                .tx_empty => port.ISR.modify(.{ .TXE = 1 }),
            }
        }
        pub fn clear_flag(flag: enum {
            alert,
            timeout,
            pec_error,
            overrun,
            arbitration_lost,
            bus_error,
            stop,
            not_ack,
            address_match,
        }) void {
            switch (flag) {
                .alert => port.ICR.modify(.{ .ALERTCF = 1 }),
                .timeout => port.ICR.modify(.{ .TIMOUTCF = 1 }),
                .pec_error => port.ICR.modify(.{ .PECCF = 1 }),
                .overrun => port.ICR.modify(.{ .OVRCF = 1 }),
                .arbitration_lost => port.ICR.modify(.{ .ARLOCF = 1 }),
                .bus_error => port.ICR.modify(.{ .BERRCF = 1 }),
                .stop => port.ICR.modify(.{ .STOPCF = 1 }),
                .not_ack => port.ICR.modify(.{ .NACKCF = 1 }),
                .address_match => port.ICR.modify(.{ .ADDRCF = 1 }),
            }
        }
        pub fn clear_flags() void {
            port.ICR.modify(.{
                .ALERTCF = 1,
                .TIMOUTCF = 1,
                .PECCF = 1,
                .OVFCF = 1,
                .ARLOCF = 1,
                .BERRCF = 1,
                .STOPCF = 1,
                .NACKCF = 1,
                .ADDRCF = 1,
            });
        }
        pub fn set_general_call(enabled: bool) void {
            port.CR1.modify(.{ .GCEN = @boolToInt(enabled) });
        }
        pub fn set_wakeup_from_stop(enabled: bool) void {
            port.CR1.modify(.{ .WUPEN = @boolToInt(enabled) });
        }
        pub fn set_clock_stretching(enabled: bool) void {
            port.CR1.modify(.{ .NOSTRETCH = @boolToInt(!enabled) });
        }
        pub fn set_slave_byte_control(enabled: bool) void {
            port.CR1.modify(.{ .SBC = @boolToInt(enabled) });
        }
        pub fn set_analog_filter(enabled: bool) void {
            port.CR1.modify(.{ .ANFOFF = @boolToInt(!enabled) });
        }
        const Timeout = enum {
            disabled,
            us,
        };
        pub fn set_idle_timeout(timeout: union(Timeout) {
            disabled: void,
            us: u16,
        }) void {
            port.TIMEOUTR.modify(.{ .TIMOUTEN = 0, .TIDLE = 0 });
            switch (timeout) {
                .us => |val| {
                    port.TIMEOUTR.modify(.{
                        .TIMOUTEN = 1,
                        .TIDLE = 1,
                        .TIMEOUTA = @intCast(u12, @maximum(1024, val) * 4 - 1),
                    });
                },
                else => {},
            }
        }

        const DigitalFilter = enum {
            disabled,
            clk,
        };
        pub fn set_digital_filter(mode: union(DigitalFilter) {
            disabled: void,
            clk: u4,
        }) void {
            const val = switch (mode) {
                .disabled => 0,
                .clk => |val| val,
            };
            port.CR1.modify(.{ .DNF = val });
        }
        pub fn set_dma(name: enum {
            rx,
            tx,
            rx_tx,
        }, enabled: bool) void {
            switch (name) {
                .rx => port.CR1.modify(.{
                    .RXDMAEN = @boolToInt(enabled),
                }),
                .tx => port.CR1.modify(.{
                    .TXDMAEN = @boolToInt(enabled),
                }),
                .rx_tx => port.CR1.modify(.{
                    .RXDMAEN = @boolToInt(enabled),
                    .TXDMAEN = @boolToInt(enabled),
                }),
            }
        }
        const Address = enum {
            bit_7,
            bit_10,
        };
        pub fn set_own_address(addr: union(Address) {
            bit_7: u7,
            bit_10: u10,
        }) void {
            port.OAR1.modify(.{ .OA1EN = 0 });
            switch (addr) {
                .bit_7 => |val| port.OAR1.modify(.{
                    .OA1 = @intCast(u10, val) << 1,
                    .OA1MODE = 0,
                    .OA1EN = 1,
                }),
                .bit_10 => |val| port.OAR1.modify(.{
                    .OA1 = val,
                    .OA1MODE = 1,
                    .OA1EN = 1,
                }),
            }
        }
        pub fn set_slave_address(addr: union(Address) {
            bit_7: u7,
            bit_10: u10,
        }) void {
            switch (addr) {
                .bit_7 => |val| port.CR2.modify(.{
                    .SADD = @intCast(u10, val) << 1,
                    .ADD10 = 0,
                }),
                .bit_10 => |val| port.CR2.modify(.{
                    .SADD = val,
                    .ADD10 = 1,
                }),
            }
        }
        pub fn set_10bit_header(enabled: bool) void {
            port.CR2.modify(.{ .HEAD10R = @boolToInt(enabled) });
        }
        pub fn start() void {
            port.CR2.modify(.{ .START = 1 });
        }
        pub fn stop() void {
            port.CR2.modify(.{ .STOP = 1 });
        }
        pub fn nack() void {
            port.CR2.modify(.{ .NACK = 1 });
        }
        pub fn set_direction(dir: enum(u1) { write = 0, read = 1 }) void {
            port.CR2.modify(.{ .RD_WRN = @enumToInt(dir) });
        }
        pub fn set_byte_count(n: u8) void {
            port.CR2.modify(.{ .NBYTES = n });
        }
        pub fn set_autoend(enabled: bool) void {
            port.CR2.modify(.{ .AUTOEND = @boolToInt(enabled) });
        }
        pub fn set_reload(enabled: bool) void {
            port.CR2.modify(.{ .RELOAD = @boolToInt(enabled) });
        }
        pub fn set_packet_error_checking_byte(enabled: bool) void {
            port.CR2.modify(.{ .PECBYTE = @boolToInt(enabled) });
        }
        pub fn wait_until_finished() !void {
            try core.timeout_wait_for(100, port.ISR, .BUSY, 0);
        }
        pub fn read_data() u8 {
            return port.RXDR.read().RXDATA;
        }
        pub fn write_data(data: u8) void {
            port.TXDR.modify(.{ .TXDATA = data });
        }
    };
}
