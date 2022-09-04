const std = @import("std");
const microzig = @import("microzig");
const regs = microzig.chip.registers;
const gpio = @import("gpio.zig");

const set = @import("core.zig").set_reg_field;
const wait_for = @import("core.zig").wait_for;

const InitConfig = struct {
    cs: ?[]const u8 = null,
    clk: []const u8,
    miso: []const u8,
    mosi: []const u8,
};

pub fn SPI(comptime port_number: u3) type {
    if (port_number != 1) unreachable;
    const port_name = std.fmt.comptimePrint("{d}", .{port_number});
    const port = @field(regs, "SPI" ++ port_name);

    return struct {
        pub fn init_pins(comptime config: InitConfig) void {
            reset();
            enable_clock();

            const clk = gpio.Pin(config.clk);
            const miso = gpio.Pin(config.miso);
            const mosi = gpio.Pin(config.mosi);

            clk.enable_port_clock();
            clk.push_pull();
            clk.pull_up();
            clk.alternate();
            clk.medium_speed();
            clk.alternate_fun("SPI" ++ port_name ++ "_SCK");

            miso.enable_port_clock();
            miso.push_pull();
            miso.pull_up();
            miso.alternate();
            miso.medium_speed();
            miso.alternate_fun("SPI" ++ port_name ++ "_MISO");

            mosi.enable_port_clock();
            mosi.push_pull();
            mosi.pull_up();
            mosi.alternate();
            mosi.medium_speed();
            mosi.alternate_fun("SPI" ++ port_name ++ "_MOSI");

            if (config.cs) |csn| {
                const cs = gpio.Pin(csn);
                cs.enable_port_clock();
                cs.push_pull();
                cs.pull_up();
                cs.alternate();
                cs.medium_speed();
                cs.alternate_fun("SPI" ++ port_name ++ "_NSS");
            }
        }
        pub fn dma_address() u32 {
            return @ptrToInt(&port.DR.raw);
        }
        pub fn enable_clock() void {
            // Enable clock
            set(regs.RCC.APB2ENR, "SPI" ++ port_name ++ "EN", 1);
        }
        pub fn disable_clock() void {
            // Enable clock
            set(regs.RCC.APB2ENR, "SPI" ++ port_name ++ "EN", 0);
        }
        pub fn reset() void {
            // Reset API
            set(regs.RCC.APB2RSTR, "SPI" ++ port_name ++ "RST", 1);
            set(regs.RCC.APB2RSTR, "SPI" ++ port_name ++ "RST", 0);
        }
        pub fn clear() void {
            write(0);
            if (port.SR.read().RXNE == 1) {
                _ = port.DR.read();
            }
        }
        pub fn enable() void {
            port.CR1.modify(.{ .SPE = 1 });
        }
        pub fn disable() void {
            port.CR1.modify(.{ .SPE = 0 });
        }
        pub fn clean_disable() u16 {
            // Wait until last data is received
            wait_for(port.SR, .RXNE, 1);
            var data: u16 = port.DR.read();

            // Wait until last data is transmitted
            wait_for(port.SR, .TXE, 1);

            // Wait until not busy
            wait_for(port.SR, .BSY, 0);

            // Disable peripheral
            port.CR1.modify(.{ .SPE = 0 });

            return data;
        }
        pub fn wait_until_finished() void {
            // Wait until not busy
            wait_for(port.SR, .BSY, 0);
        }
        pub fn write(data: u16) void {
            port.DR.modify(data);
        }
        pub fn send(data: u16) void {
            // Wait for transmit empty
            wait_for(port.SR, .TXE, 1);

            port.DR.modify(data);
        }
        pub fn read() u16 {
            // Wait for data to be ready
            wait_for(port.SR, .RXNE, 1);

            return port.DR.read();
        }
        pub fn xfer(data: u16) u16 {
            write(data);

            return read();
        }
        pub fn set_baudrate(baudrate: enum(u3) {
            div2 = 0b000,
            div4 = 0b001,
            div8 = 0b010,
            div16 = 0b011,
            div32 = 0b100,
            div64 = 0b101,
            div128 = 0b110,
            div256 = 0b111,
        }) void {
            port.CR1.modify(.{ .BR = @enumToInt(baudrate) });
        }
        pub fn set_standard_mode(mode: enum(u2) {
            mode_0 = 0b00,
            mode_1 = 0b01,
            mode_2 = 0b10,
            mode_3 = 0b11,
        }) void {
            port.CR1.modify(.{
                .CPOL = @intCast(u1, (@enumToInt(mode) & 0b10) >> 1),
                .CPHA = @intCast(u1, @enumToInt(mode) & 0b01),
            });
        }
        pub fn set_bitorder(order: enum(u1) {
            msbfirst = 0,
            lsbfirst = 1,
        }) void {
            port.CR1.modify(.{ .LSBFIRST = @enumToInt(order) });
        }
        pub fn set_slave_management(mode: enum {
            hardware_master,
            hardware_slave,
            software,
        }) void {
            const vals: [2]u1 = switch (mode) {
                .hardware_master => .{ 0, 1 },
                .hardware_slave => .{ 0, 0 },
                .software => .{ 1, 0 },
            };
            port.CR1.modify(.{
                .SSM = vals[0],
            });
            port.CR2.modify(.{
                .SSOE = vals[1],
            });
        }
        pub fn set_slave_select(selected: bool) void {
            port.CR1.modify(.{ .SSI = @boolToInt(selected) });
        }
        pub fn set_frame_format(frame_format: enum(u1) {
            u8 = 0,
            u16 = 1,
        }) void {
            port.CR1.modify(.{
                .DFF = @enumToInt(frame_format),
            });
        }
        pub fn set_directional_mode(mode: enum {
            full_duplex,
            bidirectional_receive_only,
            bidirectional_transmit_only,
            receive_only,
        }) void {
            const vals: [3]u1 = switch (mode) {
                .full_duplex => .{ 0, 0, 0 },
                .bidirectional_receive_only => .{ 1, 0, 0 },
                .bidirectional_transmit_only => .{ 1, 1, 0 },
                .receive_only => .{ 0, 0, 1 },
            };
            port.CR1.modify(.{
                .BIDIMODE = vals[0],
                .BIDIOE = vals[1],
                .RXONLY = vals[2],
            });
        }
        pub fn set_role(role: enum(u1) {
            slave = 0,
            master = 1,
        }) void {
            port.CR1.modify(.{
                .MSTR = @enumToInt(role),
            });
        }
        pub fn set_crc(enabled: bool) void {
            port.CR1.modify(.{
                .CRCEN = @boolToInt(enabled),
            });
        }
        pub fn set_next_tx(source: enum(u1) {
            from_buffer = 0,
            from_crc = 1,
        }) void {
            port.CR1.modify(.{
                .CRCNEXT = @enumToInt(source),
            });
        }
        pub fn set_interrupt(name: enum {
            tx_buffer_empty,
            rx_buffer_not_empty,
            error_occured,
        }, enabled: bool) void {
            switch (name) {
                .tx_buffer_empty => port.CR2.modify(.{
                    .TXEIE = @boolToInt(enabled),
                }),
                .rx_buffer_not_empty => port.CR2.modify(.{
                    .RXNEIE = @boolToInt(enabled),
                }),
                .error_occured => port.CR2.modify(.{
                    .ERRIE = @boolToInt(enabled),
                }),
            }
        }
        pub fn set_dma(name: enum {
            none,
            rx,
            tx,
            rx_tx,
        }) void {
            switch (name) {
                .none => port.CR2.modify(.{
                    .RXDMAEN = 0,
                    .TXDMAEN = 0,
                }),
                .rx => port.CR2.modify(.{
                    .RXDMAEN = 1,
                    .TXDMAEN = 0,
                }),
                .tx => port.CR2.modify(.{
                    .RXDMAEN = 0,
                    .TXDMAEN = 1,
                }),
                .rx_tx => port.CR2.modify(.{
                    .RXDMAEN = 1,
                    .TXDMAEN = 1,
                }),
            }
        }
    };
}
