const microzig = @import("microzig");
const regs = microzig.chip.registers;

const core = @import("core.zig");
const set = core.set_reg_field;

pub const LPUART = struct {
    pub fn dma_rx_address() u32 {
        return @ptrToInt(&regs.LPUART1.RDR.raw);
    }
    pub fn dma_tx_address() u32 {
        return @ptrToInt(&regs.LPUART1.TDR.raw);
    }
    pub fn reset() void {
        regs.RCC.APB1RSTR.modify(.{ .LPUART1RST = 1 });
        regs.RCC.APB1RSTR.modify(.{ .LPUART1RST = 0 });
    }
    pub fn enable_clock() void {
        regs.RCC.APB1ENR.modify(.{ .LPUART1EN = 1 });

        regs.RCC.CCIPR.modify(.{
            .LPUART1SEL0 = 0, // hsi16
            .LPUART1SEL1 = 1, // hsi16
        });
    }
    pub fn enable() void {
        regs.LPUART1.CR1.modify(.{ .UE = 1 });
    }
    pub fn disable() void {
        regs.LPUART1.CR1.modify(.{ .UE = 0 });
    }
    pub fn set_word_length(len: enum(u2) {
        u8 = 0b00,
        u9 = 0b01,
        u7 = 0b10,
    }) void {
        regs.LPUART1.CR1.modify(.{
            .M1 = @intCast(u1, (@enumToInt(len) & 0b10) >> 1),
            .M0 = @intCast(u1, (@enumToInt(len) & 0b01)),
        });
    }
    pub fn set_parity_control(enabled: bool) void {
        regs.LPUART1.CR1.modify(.{ .PCE = @boolToInt(enabled) });
    }
    pub fn set_parity(mode: enum { even, odd }) void {
        regs.LPUART1.CR1.modify(.{ .PS = @enumToInt(mode) });
    }
    pub fn set_interrupt(name: enum {
        parity_error,
        character_match,
        transmission_completed,
        rx_buffer_not_empty,
        tx_buffer_empty,
        idle,
        wakeup,
        ctx,
        error_occured,
    }, enabled: bool) void {
        switch (name) {
            .parity_error => regs.LPUART1.CR1.modify(.{
                .PEIE = @boolToInt(enabled),
            }),
            .character_match => regs.LPUART1.CR1.modify(.{
                .CMIE = @boolToInt(enabled),
            }),
            .transmission_completed => regs.LPUART1.CR1.modify(.{
                .TCIE = @boolToInt(enabled),
            }),
            .tx_buffer_empty => regs.LPUART1.CR1.modify(.{
                .TXEIE = @boolToInt(enabled),
            }),
            .rx_buffer_not_empty => regs.LPUART1.CR1.modify(.{
                .RXNEIE = @boolToInt(enabled),
            }),
            .idle => regs.LPUART1.CR1.modify(.{
                .IDLEIE = @boolToInt(enabled),
            }),
            .wakeup => regs.LPUART1.CR3.modify(.{
                .WUFIE = @boolToInt(enabled),
            }),
            .ctx => regs.LPUART1.CR3.modify(.{
                .CTSIE = @boolToInt(enabled),
            }),
            .error_occured => regs.LPUART1.CR3.modify(.{
                .EIE = @boolToInt(enabled),
            }),
        }
    }
    pub fn set_transmitter(enabled: bool) void {
        regs.LPUART1.CR1.modify(.{ .TE = @boolToInt(enabled) });
    }
    pub fn set_receiver(enabled: bool) void {
        regs.LPUART1.CR1.modify(.{ .RE = @boolToInt(enabled) });
    }
    pub fn set_enabled_in_stop_mode(enabled: bool) void {
        regs.LPUART1.CR1.modify(.{ .UESM = @boolToInt(enabled) });
    }
    pub fn set_byte_order(mode: enum(u2) { lsb, msb }) void {
        regs.LPUART1.CR2.modify(.{ .MSBFIRST = @enumToInt(mode) });
    }
    pub fn set_binary_data_inversion(enabled: bool) void {
        regs.LPUART1.CR2.modify(.{ .DATAINV = @boolToInt(enabled) });
    }
    pub fn set_tx_inversion(enabled: bool) void {
        regs.LPUART1.CR2.modify(.{ .TXINV = @boolToInt(enabled) });
    }
    pub fn set_rx_inversion(enabled: bool) void {
        regs.LPUART1.CR2.modify(.{ .RXINV = @boolToInt(enabled) });
    }
    pub fn set_pin_swap(swapped: bool) void {
        regs.LPUART1.CR2.modify(.{ .SWAP = @boolToInt(swapped) });
    }
    pub fn set_stop_bits(mode: enum(u2) {
        one = 0b00,
        two = 0b10,
    }) void {
        regs.LPUART1.CR2.modify(.{ .STOP = @enumToInt(mode) });
    }
    pub fn set_wakeup_from_stop_mode(mode: enum(u2) {
        on_address_match = 0b00,
        on_start_bi = 0b10,
        on_rx_not_empty = 0b11,
    }) void {
        regs.LPUART1.CR3.modify(.{ .WUS = @enumToInt(mode) });
    }
    pub fn set_driver_polarity(mode: enum(u1) {
        active_high = 0,
        active_low = 1,
    }) void {
        regs.LPUART1.CR3.modify(.{ .DEP = @enumToInt(mode) });
    }
    pub fn set_driver_enable(enabled: bool) void {
        regs.LPUART1.CR3.modify(.{ .DEM = @boolToInt(enabled) });
    }
    pub fn set_dma_disable_on_error(enabled: bool) void {
        regs.LPUART1.CR3.modify(.{ .DDRE = @boolToInt(enabled) });
    }
    pub fn set_overrun_disable(enabled: bool) void {
        regs.LPUART1.CR3.modify(.{ .OVRDIS = @boolToInt(enabled) });
    }
    pub fn set_cts(enabled: bool) void {
        regs.LPUART1.CR3.modify(.{ .CTSE = @boolToInt(enabled) });
    }
    pub fn set_rts(enabled: bool) void {
        regs.LPUART1.CR3.modify(.{ .RTSE = @boolToInt(enabled) });
    }
    pub fn set_half_duplex(enabled: bool) void {
        regs.LPUART1.CR3.modify(.{ .HDSEL = @boolToInt(enabled) });
    }
    pub fn set_dma(name: enum {
        rx,
        tx,
        rx_tx,
    }, enabled: bool) void {
        switch (name) {
            .rx => regs.LPUART1.CR3.modify(.{
                .DMAR = @boolToInt(enabled),
            }),
            .tx => regs.LPUART1.CR3.modify(.{
                .DMAT = @boolToInt(enabled),
            }),
            .rx_tx => regs.LPUART1.CR3.modify(.{
                .DMAT = @boolToInt(enabled),
                .DMAR = @boolToInt(enabled),
            }),
        }
    }
    // Only accurate for hsi16
    pub fn set_baudrate(rate: enum(u20) {
        b9600 = 0x682AA,
        b19200 = 0x34155,
        b38400 = 0x1A0AA,
        b57600 = 0x115C7,
        b115200 = 0x8AE3,
    }) void {
        regs.LPUART1.BRR.raw = @intCast(u32, @enumToInt(rate));
    }
    pub fn receive_flush_request() void {
        regs.LPUART1.RQR.modify(.{ .RXFRQ = 1 });
    }
    pub fn mute_mode_request() void {
        regs.LPUART1.RQR.modify(.{ .MMRQ = 1 });
    }
    pub fn send_break_request() void {
        regs.LPUART1.RQR.modify(.{ .SBKRQ = 1 });
    }

    pub fn has_flag(flag: enum {
        receive_enable_ack,
        transmit_enable_ack,
        wakeup_from_stop,
        wakeup_from_mute,
        break_requested,
        character_match,
        busy,
        cts_reset,
        cts_changed,
        transmit_register_empty,
        transmission_completed,
        receive_register_not_empty,
        idle_detected,
        overrun,
        noise_detected,
        framing_error,
        parity_error,
    }) bool {
        const isr = regs.LPUART1.ISR.read();
        return switch (flag) {
            .receive_enable_ack => isr.REACK == 1,
            .transmit_enable_ack => isr.TEACK == 1,
            .wakeup_from_stop => isr.WUF == 1,
            .wakeup_from_mute => isr.RWU == 1,
            .break_requested => isr.SBKF == 1,
            .character_match => isr.CMF == 1,
            .busy => isr.BUSY == 1,
            .cts_reset => isr.CTS == 1,
            .cts_changed => isr.CTSIF == 1,
            .transmit_register_empty => isr.TXE == 1,
            .transmission_completed => isr.TC == 1,
            .receive_register_not_empty => isr.RXNE == 1,
            .idle_detected => isr.IDLE == 1,
            .overrun => isr.ORE == 1,
            .noise_detected => isr.NF == 1,
            .framing_error => isr.FE == 1,
            .parity_error => isr.PE == 1,
        };
    }
    pub fn clear_flag(flag: enum {
        wakeup_from_stop,
        character_match,
        cts,
        transmission_completed,
        idle_detected,
        overrun,
        noise_detected,
        framing_error,
        parity_error,
    }) void {
        const icr = regs.LPUART1.ICR;
        switch (flag) {
            .wakeup_from_stop => icr.modify(.{ .WUCF = 1 }),
            .character_match => icr.modify(.{ .CMCF = 1 }),
            .cts => icr.modify(.{ .CTSCF = 1 }),
            .transmission_completed => icr.modify(.{ .TCCF = 1 }),
            .idle_detected => icr.modify(.{ .IDLECF = 1 }),
            .overrun => icr.modify(.{ .ORECF = 1 }),
            .noise_detected => icr.modify(.{ .NCF = 1 }),
            .framing_error => icr.modify(.{ .FECF = 1 }),
            .parity_error => icr.modify(.{ .PECF = 1 }),
        }
    }

    pub fn read_data() u8 {
        return regs.LPUART1.RDR.read().RDR;
    }
    pub fn write_data(data: u8) void {
        regs.LPUART1.TDR.raw = @intCast(u32, data);
    }
};
