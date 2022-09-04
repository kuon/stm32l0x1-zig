const std = @import("std");
const microzig = @import("microzig");
const regs = microzig.chip.registers;
const gpio = @import("gpio.zig");

const core = @import("core.zig");
const set = core.set_reg_field;

pub const Direction = enum(u1) {
    write = 0,
    read = 1,
};

const AddressTag = enum {
    none,
    bit_7,
    bit_10,
};

const Address = union(AddressTag) {
    none: void,
    bit_7: u7,
    bit_10: u10,
};

const DigitalFilterTag = enum {
    disabled,
    clk,
};

const DigitalFilter = union(DigitalFilterTag) {
    disabled: void,
    clk: u4,
};

const StartConfig = struct {
    slave_address: Address,
    autoend: bool = true,
    reload: bool = false,
    direction: Direction = .read,
    byte_count: usize = 0,
    packet_error_checking_byte: bool = false,
};

const Speed = enum {
    kHz_10,
    kHz_100,
    kHz_400,
    kHz_1000,
};

const InitConfig = struct {
    scl: []const u8,
    sda: []const u8,
};

pub fn I2C(comptime port_number: u3) type {
    if (port_number != 1) unreachable;
    const port_name = std.fmt.comptimePrint("{d}", .{port_number});
    const port = @field(regs, "I2C" ++ port_name);

    return struct {
        pub fn init_pins(comptime config: InitConfig) void {
            reset();
            enable_clock();

            const scl = gpio.Pin(config.scl);
            const sda = gpio.Pin(config.sda);

            scl.enable_port_clock();
            scl.open_drain();
            scl.floating();
            scl.alternate_fun("I2C" ++ port_name ++ "_SCL");

            sda.enable_port_clock();
            sda.open_drain();
            sda.floating();
            sda.alternate_fun("I2C" ++ port_name ++ "_SDA");
        }
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
        pub fn set_speed(speed: Speed) void {
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
        pub fn has_error() bool {
            return has_flag(.alert) or
                has_flag(.timeout) or
                has_flag(.pec_error) or
                has_flag(.overrun) or
                has_flag(.arbitration_lost) or
                has_flag(.bus_error);
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
                .OVRCF = 1,
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

        pub fn set_digital_filter(mode: DigitalFilter) void {
            const val = switch (mode) {
                .disabled => 0,
                .clk => |val| val,
            };
            port.CR1.modify(.{ .DNF = val });
        }
        pub fn set_dma(name: enum {
            none,
            rx,
            tx,
            rx_tx,
        }) void {
            switch (name) {
                .none => port.CR1.modify(.{
                    .RXDMAEN = 0,
                    .TXDMAEN = 0,
                }),
                .rx => port.CR1.modify(.{
                    .RXDMAEN = 1,
                    .TXDMAEN = 0,
                }),
                .tx => port.CR1.modify(.{
                    .TXDMAEN = 1,
                    .RXDMAEN = 0,
                }),
                .rx_tx => port.CR1.modify(.{
                    .RXDMAEN = 1,
                    .TXDMAEN = 1,
                }),
            }
        }
        pub fn set_own_address(addr: Address) void {
            port.OAR1.modify(.{ .OA1EN = 0 });
            switch (addr) {
                .none => port.OAR1.modify(.{
                    .OA1 = 0,
                    .OA1MODE = 0,
                    .OA1EN = 0,
                }),
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
        pub fn set_10bit_header(enabled: bool) void {
            port.CR2.modify(.{ .HEAD10R = @boolToInt(enabled) });
        }
        pub fn stop() void {
            port.CR2.modify(.{ .STOP = 1 });
        }
        pub fn nack() void {
            port.CR2.modify(.{ .NACK = 1 });
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

        pub fn start(config: StartConfig) void {
            const addr: [2]u10 = switch (config.slave_address) {
                .none => .{ 0, 0 },
                .bit_7 => |val| .{ @intCast(u10, val) << 1, 0 },
                .bit_10 => |val| .{ val, 1 },
            };
            port.CR2.modify(.{
                .SADD = addr[0],
                .ADD10 = @intCast(u1, addr[1]),
                .AUTOEND = @boolToInt(config.autoend),
                .RD_WRN = @enumToInt(config.direction),
                .NBYTES = @intCast(u8, config.byte_count),
                .PECBYTE = @boolToInt(config.packet_error_checking_byte),
                .START = 1,
            });
        }

        pub fn transfer(addr: u7, tx: []const u8, rx: []u8) !void {
            const writing = tx.len > 0;
            const reading = rx.len > 0;

            // wait until i2c is not busy
            try wait_until_finished();

            if (writing) {
                // auto end only if we will not read after write
                try start_rw(addr, tx.len, .write, !reading);

                // send bytes
                for (tx) |b| {
                    try send_byte(b);
                }

                // wait for i2c transfer to finish (only if reading after)
                if (reading) {
                    while (!has_flag(.transfer_completed)) {
                        if (has_error()) {
                            return error.TransferError;
                        }
                    }
                }
            }

            if (reading) {
                try start_rw(addr, rx.len, .read, true);

                // recv bytes
                for (rx) |*b| {
                    b.* = try recv_byte();
                }
            }
        }

        fn start_rw(
            addr: u7,
            len: usize,
            direction: Direction,
            autoend: bool,
        ) !void {
            // Ensure tx is empty
            set_flag(.tx_empty);

            // Read any data to flush rx
            while (has_flag(.rx_buffer_not_empty)) {
                _ = read_data();
                if (has_error()) {
                    return error.StartError;
                }
            }
            start(.{
                .autoend = autoend,
                .direction = direction,
                .byte_count = len,
                .slave_address = .{ .bit_7 = addr },
            });
        }

        fn send_byte(b: u8) !void {
            while (!has_flag(.tx_buffer_empty)) {
                if (has_error()) {
                    return error.SendError;
                }
            }

            write_data(b);

            if (has_error()) {
                return error.SendError;
            }
        }

        fn recv_byte() !u8 {
            while (!has_flag(.rx_buffer_not_empty)) {
                if (has_error()) {
                    return error.SendError;
                }
            }

            return read_data();
        }
    };
}
